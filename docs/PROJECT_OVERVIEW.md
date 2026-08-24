# Project Overview — What This Repository Actually Does

This document describes the *intent and method* of this repository: the problem it solves, how
the work decomposes, the decisions that drive it, and the operating rules we converged on.

It deliberately contains **no performance figures and no benchmark results**. Those live in the
machine-specific documents; they are outputs of this project, not its subject. For concrete
commands, follow the guide for your machine.

---

## 1. In one paragraph

This repository is the **field manual and reference implementation for turning a bare NVIDIA
workstation into a self-contained, private AI appliance**. It takes a machine from "fresh OS
install" (or "appliance out of the box") to "serving local language models over an API, with
optional image generation, surviving reboots, with models on the right disks and the GPU
actually being used." Everything is captured twice: as **prose documentation** that explains
*why* each step exists, and as **executable scripts and compose files** that perform the step.
The result is a repeatable, auditable setup path rather than a one-off machine someone
configured by hand.

---

## 2. The problem we are solving

Running an LLM locally is easy to demo and hard to *operate*. The failure modes are boring and
repetitive, and they are almost never in the model — they are in the plumbing:

- The GPU is present but the container cannot see it, so inference silently runs on CPU.
- The model loads but only partially fits, so some layers spill to CPU and everything crawls.
- Models land on the OS drive and fill it.
- The service works until the machine reboots, or until a driver update leaves a container
  parked in a state no restart policy will recover from.
- A guide written for one machine is followed on a different machine, and every command is
  subtly wrong — wrong port, wrong prefix, wrong memory assumptions.

None of these are model problems. They are **systems problems**. This repo is the accumulated,
verified answer to them for a specific, real class of hardware.

---

## 3. The central idea: a build is a small set of decisions

The most useful discovery in this work is not any individual command — it is that **the entire
build collapses into a handful of decisions, and everything downstream is derivable from them.**

| Decision | What it determines |
|---|---|
| **CPU architecture** (x86-64 vs ARM) | Whether containers are viable at all, and which binaries/images exist |
| **Memory model** (discrete VRAM vs unified) | The size class of models the machine can serve, and what the real bottleneck is |
| **Appliance vs build-it-yourself** | Whether setup *builds* the stack or merely *verifies* a preinstalled one |
| **Storage topology** (single disk vs multiple NVMe) | Where models, logs and working data live, and what goes into `fstab` |
| **Runtime deployment** (Docker vs native systemd) | Command shape, port, model path, log access, restart semantics |
| **Optional workloads** (image generation, alternate engines) | Extra services, extra storage trees, GPU memory budgeting rules |

The top-level [`setup.sh`](../setup.sh) is the working proof of this idea: it reads *one* fact
about the machine (`uname -m`) and from that single input routes to a completely different path
— different runtime, different port, different storage root, different command vocabulary,
different capabilities. Everything else in the repo hangs off that routing decision.

---

## 4. The two reference paths

We maintain two machines that are deliberately opposite, so the abstraction is forced to be real
rather than accidental. They are documented as **classes**, not as products — a new machine is
handled by mapping it onto whichever class it resembles.

### Class A — "Build it": x86-64 workstation, discrete GPU, Docker

*Reference: Dell Precision T5820 with an RTX 3090.*

The machine arrives as a general-purpose computer. Setup must **construct** the entire stack:
replace the stock GPU driver, install Docker, install and configure the NVIDIA Container
Toolkit, partition and mount dedicated NVMe drives, lay out a directory tree, then bring up the
inference runtime in containers. Every command that touches the model server is prefixed with a
`docker exec` into the container. Capacity is bounded by discrete VRAM, so **model selection is a
fitting problem** — you choose models that fit, and the payoff for fitting is high throughput.
Because the GPU is a conventional discrete card with high memory bandwidth, this class can *also*
host image generation on the same card.

### Class B — "Verify it": ARM appliance, unified memory, native service

*Reference: ASUS Ascent GX10 with an NVIDIA GB10.*

The machine arrives **already an appliance** — OS, driver, CUDA and a native ARM build of the
model server are preinstalled. There is nothing to install; the job is to **verify, configure and
hand over**. The model server runs as a native systemd service, so commands are issued directly
with no container prefix. Memory is unified and large, so capacity stops being the constraint and
**bandwidth becomes the constraint** — model selection turns from "will it fit?" into "how many
parameters are active per token?" Container-based tooling is a liability here, because images
built only for x86 either fail or run under slow emulation.

### Why keeping both matters

The two classes disagree on nearly everything a naive script would hardcode: the port the API
listens on, the directory models live in, whether `docker` is part of the command, how you read
logs, how you restart the service, whether GPU memory reporting can be trusted at all, and
whether a given optional workload is even offered. Maintaining both is what stops the tooling
from quietly assuming one machine. [`docs/MACHINES.md`](MACHINES.md) is the canonical
side-by-side translation table between them.

---

## 5. What the setup actually consists of

These are the phases the work decomposes into. Each is an independently selectable,
independently verifiable unit — not one monolithic script.

**Phase 0 — Detect and route.**
Identify the machine class from facts about the machine itself, not from what the operator
assumes. Fail clearly and helpfully on unrecognized hardware rather than proceeding on wrong
assumptions.

**Phase 1 — Base platform.**
GPU driver (including *removing* whatever the OS installer put there first), OS updates, and the
small set of core packages later phases depend on. Class B skips this entirely.

**Phase 2 — Container/GPU bridge.** *(Class A only)*
Install Docker, add the NVIDIA container repository and toolkit, configure the container runtime
so containers can address the GPU, then **prove it** by running a throwaway CUDA container. This
phase is where the single most common silent failure lives, so it ends with an explicit test
rather than an assumption.

**Phase 3 — Storage.**
Identify the physical disks, partition and format them, label them, resolve stable UUIDs, create
mount points, write durable `fstab` entries, mount, and set ownership. The layout separates
**model weights** (large, cold, re-downloadable) from **working data** (logs, results, exports)
so they can live on different devices with different characteristics. On single-disk appliances
the same logical separation is expressed as directories rather than devices.

**Phase 4 — Directory contract.**
Create the tree the rest of the system relies on: one subdirectory per inference engine, a
subtree for image-generation assets, and a parallel tree for logs and working data. Convenience
symlinks into the user's home make the layout discoverable. This tree is a *contract* — compose
files, scripts and service units all reference it through environment variables rather than
hardcoded paths.

**Phase 5 — Inference runtime.**
Bring up the model server. Class A does this with Docker Compose, driven by a single `.env` file
that carries storage paths, ports, GPU selection and log destinations. Class B does this by
configuring the existing native service through a systemd drop-in override — model directory,
bind address and port, and model residency policy. Either way the runtime exposes an HTTP API on
a known port, which is the machine's actual product surface.

**Phase 6 — Models.**
Pull the chosen models into the model store, optionally build derived model definitions that
override runtime parameters such as context length or accelerator layer count, and confirm each
model is resident and fully accelerated. The intended use case — coding, reasoning, vision,
general chat — is what turns into a concrete list of models to fetch.

**Phase 7 — Optional workloads.**
Image generation via a Stable Diffusion WebUI container sharing the same GPU as the language
models; and alternate inference engines for higher-throughput or Hugging Face–native serving,
each defined as its own compose file with its own cache directory and port. These are genuinely
optional and **class-gated**: image generation belongs to the discrete-GPU class and is
deliberately *not* offered on the unified-memory class, because the hardware makes it
impractical. Knowing when to withhold an option is part of the design.

**Phase 8 — Lifecycle and persistence.**
Make the stack survive reboots and failures: a systemd unit that brings the whole compose stack
up at boot, with a restart policy chosen for a specific real failure mode — a container that
fails at task creation after a driver upgrade is parked in a state that container restart
policies never retry, and only re-running the bring-up recovers it. This is the kind of hard-won
detail that separates a demo from an appliance.

**Phase 9 — Verification and handover.**
A health check that reports OS, GPU, runtime, storage, directory tree, service state and API
reachability in one pass, plus a printed set of next commands. Setup is not finished when the
last install succeeds — it is finished when a single command can *demonstrate* the machine is
correct.

**Phase 10 — Rollback.**
Filesystem snapshots taken at meaningful checkpoints: one after the base platform is clean, one
after the full stack is working ("golden"). This gives the machine a known-good state to return
to, which matters enormously when the alternative is re-running an hour of setup.

---

## 6. Operating rules we converged on

These are the durable, transferable lessons — the parts worth reusing rather than rediscovering.

**Detect, don't ask.** Machine facts should be read from the machine. Human input selects
*intent* — which models, which optional workloads; the machine determines *mechanism*.

**Verify-vs-build is a first-class mode.** Some machines need building, some need only checking.
The same entry point must support both, and the checking mode must be honest — it reports gaps
with explicit failure and warning states rather than pretending success.

**Every risky assumption ends in a test.** GPU visible to containers, model fully offloaded to
the accelerator, API answering on its port, drives mounted where they should be. Each is a
command with an expected output, not a hope.

**Configuration is data, not code.** Paths, ports and device selection live in a single `.env`
(Class A) or a single systemd drop-in (Class B). Compose files and service units consume them
with sane defaults. Changing where models live must never mean editing a script.

**Separate weights from working data.** Model stores are large, immutable and re-downloadable;
logs, results and exports are small, hot and precious. Different lifecycles deserve different
locations, and on multi-disk machines, different devices.

**Prefer the runtime that is native to the machine.** Containers on the x86 workstation; a native
systemd service on the ARM appliance. Forcing one deployment style onto both hardware classes
produces either emulation penalties or unnecessary complexity.

**Mount defensively.** Auxiliary storage is mounted so that a missing or failed drive degrades
the machine instead of preventing it from booting.

**Trust the runtime's own reporting over generic tooling.** On unified-memory hardware the
standard GPU utility cannot report memory meaningfully; the inference server's own logs are the
authoritative source. Any health check must know which source to believe on which machine.

**Model residency is a policy, not a default.** How long a loaded model stays in memory should be
chosen from the machine's characteristics — on a large-memory machine where loading is slow,
pinning models is cheap and correct; on a capacity-constrained machine, holding a model resident
blocks other work.

**A shared GPU means budgeting, not luck.** When language models and image generation share one
card, the two workloads coexist only under an explicit memory budget and an explicit way to evict
a resident model before a heavy job. That rule has to be documented and tooled, not assumed.

**Document the translation, not just the procedure.** Because two machine classes exist, every
guide states which class it is for, and the shared docs carry an explicit command-translation
table. This is the human-facing equivalent of the routing function.

---

## 7. What a finished machine delivers

Independent of class, a completed build offers:

- A **local HTTP inference API** on a known port, speaking a standard and widely supported
  protocol, so existing tools and IDE integrations can point at it with no code changes.
- A **command-line workflow** for listing, pulling, running, inspecting and unloading models.
- A **model library on dedicated storage**, sized for many models rather than a handful.
- Optionally, an **image-generation service** with its own web UI and API on the same GPU
  (discrete-GPU class only).
- Optionally, **alternate inference engines** for throughput-oriented or Hugging Face–native
  serving.
- **Boot persistence, logging, health checking and snapshot-based rollback.**
- And the underlying premise of the whole thing: **no cloud dependency, no per-token cost, and no
  data leaving the machine.**

---

## 8. Where the knowledge lives

| Path | What it holds |
|---|---|
| [setup.sh](../setup.sh) | The detect-and-route entry point |
| [docs/MACHINES.md](MACHINES.md) | Machine-class comparison and the command-translation table between classes |
| [docs/machines/t5820/](machines/t5820/) | The full build path for the x86 + discrete GPU + Docker class: system setup, inference setup, install, hardware, image generation |
| [docs/machines/gx10/](machines/gx10/) | The verify-and-configure path for the ARM + unified-memory + native-service class |
| [docs/shared/](shared/) | Machine-independent material: model selection guidance and evaluation automation |
| [llm-docker/](../llm-docker/) | The executable Class A stack: `.env`, one compose file per engine, the image-generation image, the boot service unit, and operational scripts |
| [scripts/](../scripts/) | Machine-independent operational and evaluation scripts |
| [QUICK_START.md](../QUICK_START.md) | The shortest path from a configured machine to a first working query, per class |

---

## 9. What this repository is not

Being explicit about the edges:

- It is **not multi-tenant or multi-user**. There is no authentication layer, no quota system and
  no user isolation in front of the inference API.
- It is **not network-hardened**. Services bind for local and LAN use; exposing a machine beyond
  a trusted network is out of scope here.
- It is **not multi-GPU**. Both reference machines are single-accelerator, and device selection is
  expressed as a single index.
- It is **not a fleet manager**. There is no remote inventory, no central update mechanism and no
  telemetry — each machine is set up and operated on its own.
- It does **not train or fine-tune**. This is an inference appliance.
- It is **not an unattended installer**. Several build-class steps are documented as deliberate,
  reviewed human actions — replacing drivers, destroying and repartitioning disks, editing
  `fstab`. They are written to be understood before they are run.

---

*This document describes intent and method. For the concrete commands of either path, follow the
machine guide for that class; for measured performance characteristics, see the machine-specific
benchmark documents, which are intentionally out of scope here.*
