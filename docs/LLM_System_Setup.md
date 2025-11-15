# LLM System Setup Guide
## Dell T5820 Ubuntu 24.04.3 LTS Configuration for Local LLM Inference

**System:** Dell Precision T5820 with NVIDIA RTX 3090 (24GB)  
**OS:** Ubuntu 24.04.3 LTS  
**Goal:** Prepare system for local LLM inference workloads

---

## Table of Contents
1. [Hardware Overview](#hardware-overview)
2. [Prerequisites](#prerequisites)
3. [NVIDIA Driver Installation](#nvidia-driver-installation)
4. [System Updates](#system-updates)
5. [Core Packages](#core-packages)
6. [Docker Installation](#docker-installation)
7. [NVIDIA Container Toolkit](#nvidia-container-toolkit)
8. [NVMe Drive Configuration](#nvme-drive-configuration)
9. [LLM Directory Structure](#llm-directory-structure)
10. [Timeshift Backup](#timeshift-backup)
11. [Final Verification](#final-verification)

---

## Hardware Overview

### System Specifications
```
CPU:     Intel Xeon W-2235 (6 cores / 12 threads, 3.8-4.6 GHz)
RAM:     128 GB DDR4 ECC (2x64 GB, 2666 MHz)
GPU:     NVIDIA RTX 3090 (24 GB GDDR6X)
Storage:
  - OS:      128 GB SSD (sda2)
  - NVMe 1:  1 TB (nvme0n1p1) - For working data/logs
  - NVMe 2:  4 TB (nvme1n1p1) - For model storage
```

### Why This Configuration Matters
- **24GB VRAM**: Can run models up to 32B parameters at Q4 quantization entirely on GPU
- **128GB RAM**: Sufficient for model loading and system operations
- **Dual NVMe**: Separates hot data (models on 4TB) from working data (logs/benchmarks on 1TB)
- **ECC Memory**: Error correction for reliable long-running inference tasks

---

## Prerequisites

**Starting Point:**
- Fresh Ubuntu 24.04.3 LTS installation on 128GB SSD
- Single partition (no separate /home, no swap)
- "Install third-party drivers" option selected during installation (installs a default NVIDIA driver)
- Network connectivity established
- User account created with sudo privileges

---

## NVIDIA Driver Installation

Ubuntu's installer may pre-install a default NVIDIA driver. We need to replace it with the 570-open driver for optimal RTX 3090 performance.

### 1. Check Current Driver Status

```bash
# See what driver is currently loaded
lspci -k | grep -A 3 -i nvidia

# Check driver version (if installed)
cat /proc/driver/nvidia/version

# List installed NVIDIA packages
dpkg -l | grep nvidia
```

### 2. Remove Existing NVIDIA Drivers

```bash
# Purge all NVIDIA packages
sudo apt purge '*nvidia*'
sudo apt autoremove
```

**Note:** Screen resolution may change after this as system falls back to nouveau driver.

### 3. Install NVIDIA 570-Open Driver

```bash
sudo apt update
sudo apt install nvidia-driver-570-open
```

This installs the open-source kernel module version of the 570 driver, which provides excellent performance for RTX 3090.

### 4. Reboot

```bash
sudo reboot
```

### 5. Verify Installation

After reboot:

```bash
nvidia-smi
```

Expected output:
```
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 570.195.03             Driver Version: 570.195.03     CUDA Version: 12.8     |
|-----------------------------------------+------------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id          Disp.A | Volatile Uncorr. ECC |
|=========================================+========================+======================|
|   0  NVIDIA GeForce RTX 3090        Off |   00000000:65:00.0  On |                  N/A |
| 30%   40C    P2            101W /  350W |     557MiB /  24576MiB |      0%      Default |
+-----------------------------------------+------------------------+----------------------+
```

**Key Points:**
- Driver Version: 570.195.03
- CUDA Version: 12.8
- GPU Memory: 24576MiB (24GB)
- Power Cap: 350W

---

## System Updates

Ensure all packages are up to date:

```bash
sudo apt update && sudo apt upgrade -y
```

**Note:** Some packages may be deferred due to Ubuntu's phased updates. This is normal and the deferred package(s) will update automatically later.

---

## Core Packages

Install essential development tools and utilities:

```bash
sudo apt install -y git curl wget htop build-essential python3-pip python3-venv nvme-cli
```

**Package Purposes:**
- **git** - Version control
- **curl, wget** - File downloads and API interaction
- **htop** - Interactive process monitor
- **build-essential** - Compiler toolchain (gcc, make, etc.)
- **python3-pip** - Python package manager
- **python3-venv** - Python virtual environment support
- **nvme-cli** - NVMe drive management tools

### Verify Python Installation

```bash
python3 --version
pip3 --version
```

Expected output:
```
Python 3.12.3
pip 24.0 from /usr/lib/python3/dist-packages/pip (python 3.12)
```

Ubuntu 24.04 includes Python 3.12 by default.

---

## Docker Installation

### 1. Install Docker Engine

Use the official convenience script:

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
```

This installs:
- Docker Engine (latest version)
- Docker Compose plugin
- Docker CLI tools
- containerd

### 2. Add User to Docker Group

```bash
sudo usermod -aG docker $USER
```

**Important:** Log out and log back in (or reboot) for group membership to take effect.

### 3. Verify Installation

After logging back in:

```bash
docker --version
docker compose version
```

Expected output:
```
Docker version 29.0.1, build eedd969
Docker Compose version v2.40.3
```

**Note:** Docker Compose is now included as a plugin with Docker Engine - no separate installation needed.

---

## NVIDIA Container Toolkit

This enables Docker containers to access the GPU.

### 1. Add Repository

```bash
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
```

### 2. Install Toolkit

```bash
sudo apt update
sudo apt install -y nvidia-container-toolkit
```

### 3. Configure Docker Runtime

```bash
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

This creates/updates `/etc/docker/daemon.json` with NVIDIA runtime configuration.

### 4. Test GPU Access in Container

```bash
docker run --rm --gpus all nvidia/cuda:12.1.0-base-ubuntu22.04 nvidia-smi
```

Expected output should show the RTX 3090 with Driver 570.195.03 and CUDA 12.8, confirming GPU is accessible from within Docker containers.

---

## NVMe Drive Configuration

Configure the 1TB and 4TB NVMe drives for LLM workloads.

### 1. Identify Drives

```bash
lsblk
```

Look for:
- `nvme0n1` - 953.9G (1TB drive)
- `nvme1n1` - 3.7T (4TB drive)

If drives aren't visible, check:
```bash
sudo nvme list
```

**Troubleshooting:** If 4TB drive isn't detected, verify physical seating and BIOS settings.

### 2. Format Drives

**Warning:** This erases all data on the drives.

**1TB Drive (for working data):**

```bash
# Unmount if mounted
sudo umount /dev/nvme0n1p1 2>/dev/null || true

# Create fresh GPT partition table and partition
sudo parted /dev/nvme0n1 --script mklabel gpt
sudo parted /dev/nvme0n1 --script mkpart primary ext4 0% 100%

# Format as ext4 with label
sudo mkfs.ext4 -L llm-data /dev/nvme0n1p1
```

**4TB Drive (for model storage):**

```bash
# Unmount if mounted
sudo umount /dev/nvme1n1p1 2>/dev/null || true

# Create fresh GPT partition table and partition
sudo parted /dev/nvme1n1 --script mklabel gpt
sudo parted /dev/nvme1n1 --script mkpart primary ext4 0% 100%

# Format as ext4 with label
sudo mkfs.ext4 -L llm-models /dev/nvme1n1p1
```

### 3. Get Drive UUIDs

```bash
sudo blkid /dev/nvme0n1p1
sudo blkid /dev/nvme1n1p1
```

Note the UUIDs for each drive. Example:
```
/dev/nvme0n1p1: UUID="bed8a522-0f07-483c-a7f2-2783a8a91abb" ...
/dev/nvme1n1p1: UUID="da2c57bf-b3d1-479c-a3d2-10e39af62712" ...
```

### 4. Create Mount Points

```bash
sudo mkdir -p /mnt/llm-data
sudo mkdir -p /mnt/llm-models
```

### 5. Configure Automatic Mounting

Edit `/etc/fstab`:

```bash
# Add entries (replace UUIDs with your actual values)
echo "UUID=YOUR-1TB-UUID  /mnt/llm-data    ext4  defaults,nofail  0  2" | sudo tee -a /etc/fstab
echo "UUID=YOUR-4TB-UUID  /mnt/llm-models  ext4  defaults,nofail  0  2" | sudo tee -a /etc/fstab
```

Or use the actual commands with your UUIDs:

```bash
echo "UUID=bed8a522-0f07-483c-a7f2-2783a8a91abb  /mnt/llm-data    ext4  defaults,nofail  0  2" | sudo tee -a /etc/fstab
echo "UUID=da2c57bf-b3d1-479c-a3d2-10e39af62712  /mnt/llm-models  ext4  defaults,nofail  0  2" | sudo tee -a /etc/fstab
```

**Why `nofail`:** System will boot even if drives fail to mount.

### 6. Mount Drives

```bash
sudo systemctl daemon-reload
sudo mount -a
```

### 7. Set Ownership

```bash
sudo chown -R $USER:$USER /mnt/llm-data
sudo chown -R $USER:$USER /mnt/llm-models
```

### 8. Verify Mounts

```bash
df -h | grep mnt
```

Expected output:
```
/dev/nvme0n1p1  938G   28K  891G   1% /mnt/llm-data
/dev/nvme1n1p1  3.7T   28K  3.5T   1% /mnt/llm-models
```

---

## LLM Directory Structure

Create an organized directory structure for LLM workloads.

### 1. Create Model Storage Directories (4TB Drive)

```bash
mkdir -p /mnt/llm-models/{ollama,vllm,tgi,gguf}
```

**Purpose:**
- **ollama/** - Ollama model storage
- **vllm/** - vLLM model cache (future use)
- **tgi/** - Text Generation Inference cache (future use)
- **gguf/** - Raw GGUF model files (future use)

### 2. Create Working Data Directories (1TB Drive)

```bash
mkdir -p /mnt/llm-data/{logs/{ollama,vllm,tgi},benchmarks,datasets,exports}
```

**Purpose:**
- **logs/** - Inference engine logs
- **benchmarks/** - Performance test results
- **datasets/** - Test and evaluation datasets
- **exports/** - Model exports and artifacts

### 3. Create Convenience Symlinks (Optional)

```bash
ln -s /mnt/llm-models ~/models
ln -s /mnt/llm-data ~/data
```

This creates shortcuts in your home directory for easy access.

### 4. Verify Structure

```bash
tree -L 2 /mnt/llm-models
tree -L 2 /mnt/llm-data
```

Expected output:
```
/mnt/llm-models
├── gguf
├── ollama
├── tgi
└── vllm

/mnt/llm-data
├── benchmarks
├── datasets
├── exports
└── logs
    ├── ollama
    ├── tgi
    └── vllm
```

---

## Timeshift Backup

Create a system snapshot of the clean base configuration.

### 1. Install Timeshift

```bash
sudo apt install -y timeshift
```

### 2. Create Snapshot

```bash
sudo timeshift --create --comments "Base System: Ubuntu 24.04.3 + NVIDIA 570-open + Docker 29 + Python 3.12 + NVMe mounted + LLM directories"
```

### 3. Verify Snapshot

```bash
sudo timeshift --list
```

**Storage Location:** By default, Timeshift stores snapshots on the OS drive. With 128GB OS drive and ~30GB used, there's adequate space for several snapshots.

**Note:** To restore from a snapshot:

```bash
sudo timeshift --restore
```

---

## Final Verification

### System Summary Check

```bash
# OS Version
lsb_release -a

# GPU Status
nvidia-smi

# Docker Status
docker --version
docker compose version

# Python Version
python3 --version

# Storage Mounts
df -h | grep -E "^/dev/(sda|nvme)"

# Core Tools
git --version
curl --version | head -1
htop --version
```

### Quick Health Check Script

Create a verification script:

```bash
cat > ~/check-system.sh << 'EOF'
#!/bin/bash
echo "=== LLM System Health Check ==="

echo -e "\n--- OS ---"
lsb_release -d

echo -e "\n--- GPU ---"
nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader

echo -e "\n--- Docker ---"
docker --version
docker compose version

echo -e "\n--- Python ---"
python3 --version

echo -e "\n--- Storage ---"
df -h | grep -E "^/dev/(sda|nvme)" | awk '{print $1, $2, $4, $5, $6}'

echo -e "\n--- LLM Directories ---"
ls -la /mnt/llm-models/ 2>/dev/null | head -10 || echo "Model directory not found"
ls -la /mnt/llm-data/ 2>/dev/null | head -10 || echo "Data directory not found"

echo -e "\n--- GPU in Docker ---"
docker run --rm --gpus all nvidia/cuda:12.1.0-base-ubuntu22.04 nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null && echo "✓ GPU accessible in containers" || echo "✗ GPU NOT accessible in containers"

echo -e "\n=== All checks complete ==="
EOF

chmod +x ~/check-system.sh
```

Run with: `~/check-system.sh`

---

## What's Next

This base system is now ready for LLM inference engine configuration. Proceed to the **[LLM Inference Setup Guide](LLM_Inference_Setup.md)** for:

- Docker Compose configuration for Ollama
- GPU optimization and troubleshooting
- Model downloading and testing
- Performance benchmarking
- Golden snapshot creation

---

## Appendix: Key File Locations

```
/etc/fstab                              # Drive mount configuration
/etc/docker/daemon.json                 # Docker NVIDIA runtime config
/mnt/llm-data/                          # 1TB NVMe - Working data
/mnt/llm-models/                        # 4TB NVMe - Model storage
~/models -> /mnt/llm-models             # Symlink for convenience
~/data -> /mnt/llm-data                 # Symlink for convenience
~/check-system.sh                       # System health check script
```

---

## Appendix: Troubleshooting

### NVIDIA Driver Issues

**Symptom:** `nvidia-smi` command not found after driver installation.

**Solution:** Ensure package name is correct:
```bash
dpkg -l | grep nvidia-utils
# Should show nvidia-utils-570
```

### GPU Not Visible in Docker

**Symptom:** `docker run --gpus all` fails or doesn't show GPU.

**Solution:**
1. Verify NVIDIA Container Toolkit is installed
2. Check Docker daemon configuration:
   ```bash
   cat /etc/docker/daemon.json
   ```
3. Restart Docker:
   ```bash
   sudo systemctl restart docker
   ```

### NVMe Drive Not Detected

**Symptom:** Only one NVMe drive shows in `lsblk`.

**Solution:**
1. Check physical connection (power off, reseat drive)
2. Verify BIOS settings for M.2 slots
3. Use `sudo nvme list` to check kernel-level detection

### Drives Appearing in Taskbar

**Symptom:** Formatted but unmounted drives show as icons in GNOME taskbar.

**Solution:** Mount drives to /mnt with fstab entries. Once properly mounted, they won't appear as "unmounted drives" in file manager sidebar.

### Permission Denied on NVMe Drives

**Symptom:** Cannot write to /mnt/llm-models or /mnt/llm-data.

**Solution:**
```bash
sudo chown -R $USER:$USER /mnt/llm-data
sudo chown -R $USER:$USER /mnt/llm-models
```

---

**Document Version:** 2.0  
**Last Updated:** November 14, 2025  
**System:** Dell T5820 + RTX 3090  
**Status:** Production Ready ✓
