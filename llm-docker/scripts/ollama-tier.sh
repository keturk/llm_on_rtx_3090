#!/bin/bash
# ollama-tier.sh -- usage-based hot/cold tiering for the Ollama model store.
#
# Ollama knows exactly one store (OLLAMA_MODELS), content-addressed:
#   models/manifests/<registry>/<namespace>/<model>/<tag>   (JSON, lists the blobs)
#   models/blobs/sha256-<hex>                               (weights, config, template, ...)
# It follows symlinks, which is what makes a second tier possible: a "cold" model is one
# whose blobs were moved to the HDD and replaced by symlinks; a "hot" one has real files
# on the NVMe. The manifests always stay in the store, so `ollama list` and `ollama run`
# see every model regardless of tier.
#
# Popularity is measured, not guessed: every model load Ollama logs ("--model <blob>")
# is harvested from the container log into a ledger, and `auto` promotes what is used,
# demotes what is not, and keeps the hot tier under a size cap. Pinned models never
# leave the NVMe.
#
#   ollama-tier.sh list                # every model: tier, size, loads, last used, pin
#   ollama-tier.sh auto                # harvest usage, then promote/demote by policy
#   ollama-tier.sh promote <model>     # move to NVMe now
#   ollama-tier.sh demote  <model>     # move to HDD now
#   ollama-tier.sh pin|unpin <model>   # keep on NVMe regardless of usage
#   ollama-tier.sh harvest             # only update the usage ledger
#   ollama-tier.sh gc                  # remove cold blobs no manifest references
#
# Runs as the user that owns the store (needs docker group for `docker logs`).
set -euo pipefail

# --- policy (edit here) ------------------------------------------------------
PROMOTE_MIN_LOADS=3        # cold model loaded this often in the window -> promote
PROMOTE_WINDOW_DAYS=14
DEMOTE_IDLE_DAYS=30        # hot, unpinned, unused this long -> demote
HOT_CAP_GB=300             # hot tier budget; least-recently-used unpinned go first

# --- paths (match .env.t7920) --------------------------------------------------
HOT_STORE="${OLLAMA_HOT_STORE:-/srv/llm-models/ollama/models}"
COLD_STORE="${OLLAMA_COLD_STORE:-/mnt/data/llm-models/ollama-cold}"
STATE_DIR="${OLLAMA_TIER_STATE:-/mnt/data/llm-data/tier}"
CONTAINER="${OLLAMA_CONTAINER:-ollama}"

LEDGER="$STATE_DIR/ledger.tsv"       # <docker-log-timestamp>\t<blob>
PINNED="$STATE_DIR/pinned"           # one model name per line
SINCE_FILE="$STATE_DIR/logs-since"   # where the last harvest stopped
LOG="$STATE_DIR/tier.log"
DEFAULT_REGISTRY="registry.ollama.ai/library"

mkdir -p "$STATE_DIR" "$COLD_STORE/blobs"
touch "$LEDGER" "$PINNED"
exec 9>"$STATE_DIR/lock"; flock -n 9 || { echo "another ollama-tier run is active"; exit 1; }

log() { printf '[%s] %s\n' "$(date +%Y-%m-%dT%H:%M:%S)" "$*" | tee -a "$LOG"; }
die() { echo "error: $*" >&2; exit 1; }
need() { command -v "$1" >/dev/null || die "$1 is required"; }
need jq; need docker

# --- model <-> manifest ----------------------------------------------------------
# registry.ollama.ai/library/qwen3/8b  <->  qwen3:8b ; hf.co/user/repo/Q4 <-> hf.co/user/repo:Q4
manifest_of() {
  local name=$1 repo tag
  tag=${name##*:}; repo=${name%:*}
  [[ $repo == */* ]] || repo="$DEFAULT_REGISTRY/$repo"
  echo "$HOT_STORE/manifests/$repo/$tag"
}
name_of() {
  local rel=${1#"$HOT_STORE/manifests/"}
  rel=${rel#"$DEFAULT_REGISTRY/"}
  echo "${rel%/*}:${rel##*/}"
}
all_models() {
  [ -d "$HOT_STORE/manifests" ] || return 0
  find "$HOT_STORE/manifests" -type f | sort | while read -r m; do name_of "$m"; done
}
blobs_of()       { jq -r '[.config.digest] + [.layers[].digest] | .[]' "$(manifest_of "$1")" | sed 's/^sha256:/sha256-/'; }
weight_blob_of() { jq -r '.layers | max_by(.size) | .digest' "$(manifest_of "$1")" | sed 's/^sha256:/sha256-/'; }
size_of()        { jq -r '([.layers[].size] + [.config.size // 0]) | add' "$(manifest_of "$1")"; }
tier_of() {       # hot | cold | missing  (judged by the weight blob)
  local b; b="$HOT_STORE/blobs/$(weight_blob_of "$1")"
  if [ -L "$b" ]; then echo cold; elif [ -f "$b" ]; then echo hot; else echo missing; fi
}
is_pinned() { grep -qxF "$1" "$PINNED"; }
# every model whose manifest references a blob
referrers_of() {
  grep -rl "sha256:${1#sha256-}" "$HOT_STORE/manifests" 2>/dev/null | while read -r m; do name_of "$m"; done
}
gb() { awk -v b="$1" 'BEGIN{printf "%.1f", b/1e9}'; }

# --- usage ledger ------------------------------------------------------------------------
harvest() {
  local since; since=$(cat "$SINCE_FILE" 2>/dev/null || echo 2000-01-01T00:00:00Z)
  docker ps --format '{{.Names}}' | grep -qx "$CONTAINER" || { log "harvest: container $CONTAINER not running; skipped"; return 0; }
  local now; now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  # docker logs -t prefixes each line with an RFC3339 timestamp; Ollama logs every model
  # load with "--model /root/.ollama/models/blobs/sha256-<hex>" (runner start).
  docker logs -t --since "$since" "$CONTAINER" 2>&1 \
    | sed -nE 's#^([0-9]{4}-[0-9]{2}-[0-9]{2}T[^ ]+) .*--model /root/\.ollama/models/blobs/(sha256-[0-9a-f]{64}).*#\1\t\2#p' \
    >> "$LEDGER"
  sort -u -o "$LEDGER" "$LEDGER"
  echo "$now" > "$SINCE_FILE"
  log "harvest: ledger has $(wc -l < "$LEDGER") load(s) since $since"
}
# loads within the promote window and last-used, per blob: "<blob>\t<loads>\t<last>"
usage_table() {
  local cutoff; cutoff=$(date -u -d "-$PROMOTE_WINDOW_DAYS days" +%Y-%m-%dT%H:%M:%SZ)
  awk -F'\t' -v cutoff="$cutoff" '
    { last[$2] = ($1 > last[$2]) ? $1 : last[$2]; if ($1 >= cutoff) loads[$2]++ }
    END { for (b in last) printf "%s\t%d\t%s\n", b, loads[b]+0, last[b] }' "$LEDGER"
}

# --- moving blobs --------------------------------------------------------------------------
demote() {
  local name=$1 blob hot cold moved=0
  [ -f "$(manifest_of "$name")" ] || die "no such model: $name"
  for blob in $(blobs_of "$name"); do
    hot="$HOT_STORE/blobs/$blob"; cold="$COLD_STORE/blobs/$blob"
    [ -f "$hot" ] && [ ! -L "$hot" ] || continue          # already cold, or absent
    # a blob shared with a model that stays hot stays hot (licenses/templates mostly)
    local other keep=0
    for other in $(referrers_of "$blob"); do
      [ "$other" = "$name" ] && continue
      [ "$(tier_of "$other")" = hot ] && { keep=1; break; }
    done
    [ $keep -eq 1 ] && continue
    mv "$hot" "$cold.part" && mv "$cold.part" "$cold" && ln -s "$cold" "$hot"
    moved=$((moved + 1))
  done
  log "demote  $name -> HDD ($moved blob(s), $(gb "$(size_of "$name")") GB)"
}
promote() {
  local name=$1 blob hot cold moved=0
  [ -f "$(manifest_of "$name")" ] || die "no such model: $name"
  for blob in $(blobs_of "$name"); do
    hot="$HOT_STORE/blobs/$blob"; cold="$COLD_STORE/blobs/$blob"
    [ -L "$hot" ] || continue
    [ -f "$cold" ] || die "$name: symlink $blob points at a missing cold blob"
    rm "$hot" && mv "$cold" "$hot.part" && mv "$hot.part" "$hot"
    moved=$((moved + 1))
  done
  log "promote $name -> NVMe ($moved blob(s), $(gb "$(size_of "$name")") GB)"
}
gc() {
  local blob n=0
  for blob in "$COLD_STORE"/blobs/sha256-*; do
    [ -e "$blob" ] || continue
    [ -n "$(referrers_of "$(basename "$blob")")" ] && continue
    rm -f "$blob"; n=$((n + 1))
  done
  find "$HOT_STORE/blobs" -xtype l -delete 2>/dev/null || true   # dangling symlinks
  log "gc: removed $n orphaned cold blob(s)"
}
hot_bytes() {
  local m total=0
  for m in $(all_models); do [ "$(tier_of "$m")" = hot ] && total=$((total + $(size_of "$m"))); done
  echo "$total"
}

# --- commands ----------------------------------------------------------------------------------
cmd_list() {
  local usage; usage=$(usage_table)
  printf '%-40s %-5s %8s %6s %-20s %s\n' MODEL TIER SIZE_GB LOADS LAST_USED PIN
  local m w loads last
  for m in $(all_models); do
    w=$(weight_blob_of "$m")
    loads=$(awk -F'\t' -v b="$w" '$1==b{print $2}' <<<"$usage"); loads=${loads:-0}
    last=$(awk -F'\t' -v b="$w" '$1==b{print substr($3,1,19)}' <<<"$usage"); last=${last:-never}
    printf '%-40s %-5s %8s %6s %-20s %s\n' "$m" "$(tier_of "$m")" "$(gb "$(size_of "$m")")" "$loads" "$last" "$(is_pinned "$m" && echo pinned || true)"
  done
  printf '\nhot tier: %s GB of %s GB   (%s)\n' "$(gb "$(hot_bytes)")" "$HOT_CAP_GB" "$HOT_STORE"
}
cmd_auto() {
  harvest
  local usage demote_cutoff m tier loads last w mtime
  usage=$(usage_table)
  demote_cutoff=$(date -u -d "-$DEMOTE_IDLE_DAYS days" +%Y-%m-%dT%H:%M:%SZ)
  for m in $(all_models); do
    tier=$(tier_of "$m"); w=$(weight_blob_of "$m")
    loads=$(awk -F'\t' -v b="$w" '$1==b{print $2}' <<<"$usage"); loads=${loads:-0}
    last=$(awk -F'\t' -v b="$w" '$1==b{print $3}' <<<"$usage")
    # a never-loaded model counts from when it was pulled
    [ -n "$last" ] || last=$(date -u -r "$(manifest_of "$m")" +%Y-%m-%dT%H:%M:%SZ)
    if [ "$tier" = cold ] && [ "$loads" -ge "$PROMOTE_MIN_LOADS" ]; then
      log "auto: $m loaded $loads x in ${PROMOTE_WINDOW_DAYS}d -> promote"; promote "$m"
    elif [ "$tier" = hot ] && ! is_pinned "$m" && [[ "$last" < "$demote_cutoff" ]]; then
      log "auto: $m last used ${last:0:10}, idle > ${DEMOTE_IDLE_DAYS}d -> demote"; demote "$m"
    fi
  done
  # size cap: evict least-recently-used unpinned hot models until under budget
  local cap=$((HOT_CAP_GB * 1000000000))
  while [ "$(hot_bytes)" -gt "$cap" ]; do
    local victim=
    victim=$(for m in $(all_models); do
      [ "$(tier_of "$m")" = hot ] || continue; is_pinned "$m" && continue
      w=$(weight_blob_of "$m"); last=$(awk -F'\t' -v b="$w" '$1==b{print $3}' <<<"$usage")
      printf '%s\t%s\n' "${last:-0000}" "$m"; done | sort | head -1 | cut -f2)
    [ -n "$victim" ] || { log "auto: hot tier over ${HOT_CAP_GB} GB but everything left is pinned"; break; }
    log "auto: hot tier over ${HOT_CAP_GB} GB -> demote LRU $victim"; demote "$victim"
  done
  gc
  cmd_list
}

case "${1:-}" in
  list)     cmd_list ;;
  auto)     cmd_auto ;;
  harvest)  harvest ;;
  gc)       gc ;;
  promote)  [ -n "${2:-}" ] || die "usage: $0 promote <model>"; promote "$2" ;;
  demote)   [ -n "${2:-}" ] || die "usage: $0 demote <model>";  demote "$2" ;;
  pin)      [ -n "${2:-}" ] || die "usage: $0 pin <model>"; [ -f "$(manifest_of "$2")" ] || die "no such model: $2"
            is_pinned "$2" || echo "$2" >> "$PINNED"; log "pin $2"; [ "$(tier_of "$2")" = cold ] && promote "$2" || true ;;
  unpin)    [ -n "${2:-}" ] || die "usage: $0 unpin <model>"; sed -i "\#^$2\$#d" "$PINNED"; log "unpin $2" ;;
  *) sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit 1 ;;
esac
