#!/bin/bash
# setup-t7920.sh -- bring up the LLM stack on a Dell Precision T7920 shared with other stacks.
#
# Assumes the host already has the driver, Docker CE + Compose and the NVIDIA container
# toolkit (System_Setup.md is done there by the server rebuild). This script does the
# rest of the Class A path for this machine's storage layout:
#
#   1. directory contract: hot tier on the OS NVMe, cold tier + working data on the HDD
#   2. .env from .env.t7920 (paths, ports that do not collide with the other tenants)
#   3. Ollama up, GPU proven from inside the container
#   4. boot persistence (llm-stack.t7920.service) and the weekly tiering job (anacron)
#   5. a first small model, timed
#
# Run as the user that will own the model store, from llm-docker/:   ./scripts/setup-t7920.sh
# (the boot unit and the weekly tier job are rendered for that user and this checkout)
# Idempotent; re-run after changing .env.t7920.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."
REPO_DIR="$(cd .. && pwd)"
ok()   { printf '  \033[32m*\033[0m %s\n' "$1"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$1"; }
die()  { printf '  \033[31mx\033[0m %s\n' "$1"; exit 1; }

echo; echo "T7920 LLM stack setup ($(hostname), $(date +%F))"; echo "----------------------------------------------"

echo "Preflight"
[ "$(id -u)" -ne 0 ] || die "run as the user that owns the model store, not root"
id -nG | grep -qw docker || die "$USER is not in the docker group for this session -- log out and back in (or run: newgrp docker)"
docker info >/dev/null 2>&1 || die "docker is not answering"
mountpoint -q /mnt/data || die "/mnt/data (HDD) is not mounted"
nvidia-smi --query-gpu=name --format=csv,noheader | head -1 | grep -q . || die "nvidia-smi sees no GPU"
ok "docker, GPU and /mnt/data present"

echo "Storage layout"
set -a; . ./.env.t7920; set +a
sudo mkdir -p "$MODELS_PATH"/{ollama,vllm,tgi,gguf} \
              "$MODELS_PATH"/stable-diffusion/models/{Stable-diffusion,VAE,Lora,ControlNet,ESRGAN} \
              "$MODELS_PATH"/stable-diffusion/{outputs,embeddings} \
              "$COLD_MODELS_PATH"/{ollama-cold/blobs,stable-diffusion-archive} \
              "$DATA_PATH"/{logs/{ollama,vllm,tgi},benchmarks,datasets,exports,tier}
sudo chown -R "$USER:$USER" "$MODELS_PATH" "$COLD_MODELS_PATH" "$DATA_PATH"
ln -sfn "$MODELS_PATH" ~/models; ln -sfn "$DATA_PATH" ~/data
ok "hot  $MODELS_PATH ($(df -h --output=avail "$MODELS_PATH" | tail -1 | tr -d ' ') free, NVMe)"
ok "cold $COLD_MODELS_PATH ($(df -h --output=avail "$COLD_MODELS_PATH" | tail -1 | tr -d ' ') free, HDD)"
ok "data $DATA_PATH"

echo "Configuration"
cp .env.t7920 .env
chmod +x scripts/*.sh
ok ".env <- .env.t7920 (COMPOSE_FILE=$COMPOSE_FILE, TGI on $TGI_PORT)"
for p in "$OLLAMA_PORT" "$FORGE_PORT" "$VLLM_PORT" "$TGI_PORT"; do
  for r in ${RESERVED_PORTS:-}; do [ "$p" = "$r" ] && warn "port $p is listed in RESERVED_PORTS"; done
  if ss -tln | awk '{print $4}' | grep -qE ":$p$"; then
    docker ps --format '{{.Names}} {{.Ports}}' | grep -q ":$p->" || warn "port $p is already in use by something outside this stack"
  fi
done

echo "Ollama"
docker compose up -d
for i in $(seq 1 30); do curl -fsS "http://127.0.0.1:$OLLAMA_PORT/api/version" >/dev/null 2>&1 && break; sleep 2; done
curl -fsS "http://127.0.0.1:$OLLAMA_PORT/api/version" >/dev/null || { docker logs --tail 30 ollama; die "ollama did not answer on :$OLLAMA_PORT"; }
ok "ollama $(curl -fsS "http://127.0.0.1:$OLLAMA_PORT/api/version" | jq -r .version) answering on :$OLLAMA_PORT"
gpu=$(docker exec ollama nvidia-smi --query-gpu=name,memory.total --format=csv,noheader 2>/dev/null || true)
[ -n "$gpu" ] && ok "GPU inside the container: $gpu" || die "the ollama container cannot see the GPU"
docker exec ollama test -d "$COLD_MODELS_PATH/ollama-cold/blobs" && ok "cold tier visible inside the container at the same path" || die "cold tier mount missing in the container"

echo "Persistence"
sed -e "s#^User=.*#User=$USER#" -e "s#^WorkingDirectory=.*#WorkingDirectory=$REPO_DIR/llm-docker#" \
  systemd/llm-stack.t7920.service | sudo tee /etc/systemd/system/llm-stack.service >/dev/null
sudo systemctl daemon-reload && sudo systemctl enable llm-stack.service >/dev/null 2>&1
ok "llm-stack.service enabled (docker compose up -d at boot)"
sudo tee /etc/cron.weekly/ollama-tier >/dev/null <<EOF
#!/bin/bash
# Weekly (anacron): promote popular models to the NVMe, demote idle ones to the HDD.
su - $USER -c '$REPO_DIR/llm-docker/scripts/ollama-tier.sh auto' >> $DATA_PATH/logs/tier-cron.log 2>&1
EOF
sudo chmod 755 /etc/cron.weekly/ollama-tier
ok "weekly tiering job installed (/etc/cron.weekly/ollama-tier)"

echo "First model"
if ! docker exec ollama ollama list 2>/dev/null | grep -q '^llama3.2:3b'; then
  docker exec ollama ollama pull llama3.2:3b >/dev/null
fi
out=$(docker exec ollama ollama run llama3.2:3b --verbose "Reply with one word: ready" 2>&1 | grep -E "eval rate|^ready|Ready" | tr -s ' ' | paste -sd '|')
ok "llama3.2:3b: $out"
docker exec ollama ollama ps | tail -n +2 | grep -qi "100% GPU" && ok "model fully on the GPU" || warn "ollama ps does not show 100% GPU -- check docker logs ollama"

echo; echo "Done. Next:"
echo "  docker exec -it ollama ollama pull qwen3:14b          # or any model from docs/shared/Model_Guide.md"
echo "  ./scripts/ollama-tier.sh list                          # tiers, sizes, usage"
echo "  ./scripts/start-forge.sh                               # optional image generation on :$FORGE_PORT"
echo "  API: http://$(hostname -I | awk '{print $1}'):$OLLAMA_PORT  (reachable on the LAN; no auth)"
