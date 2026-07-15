# Dell Precision T5820 - Hardware Configuration

## System Overview

**Model:** Dell Precision T5820 Workstation  
**Processor:** Intel Xeon W-2235  
**Purpose:** High-performance local LLM inference and AI development workloads

---

## Detailed Specifications

### CPU
- **Model:** Intel Xeon W-2235
- **Cores/Threads:** 6 cores / 12 threads
- **Base Clock:** 3.8 GHz
- **Turbo Clock:** 4.6 GHz
- **Architecture:** Cascade Lake
- **TDP:** 130W

### Memory
- **Total:** 128 GB DDR4 ECC Registered
- **Configuration:** 2x 64 GB DIMMs
- **Speed:** DDR4-2666 (PC4-21300)
- **Type:** 2Rx4 1.2V CL19 ECC RDIMM
- **Brand:** NEMIX RAM
- **Compatibility:** Dell EMC PowerEdge XR2, Dell Precision T5820

### Storage
| Drive | Capacity | Type | Mount Point | Purpose |
|-------|----------|------|-------------|---------|
| OS Drive | 128 GB | SSD | `/` | Operating System |
| Storage #1 | 1 TB | NVMe SSD | `/mnt/llm-data` | Working data, logs, benchmarks |
| Storage #2 | 4 TB | NVMe SSD | `/mnt/llm-models` | Model storage |

### Graphics
- **Model:** NVIDIA GeForce RTX 3090
- **VRAM:** 24 GB GDDR6X
- **Variant:** HP OEM (Part# M24410-001, Renewed)
- **CUDA Cores:** 10,496
- **Memory Bandwidth:** 936 GB/s
- **TDP:** 350W

### Operating System
- **Distribution:** Ubuntu 24.04.3 LTS
- **Kernel:** Linux 6.8.x
- **NVIDIA Driver:** 570-open (570.195.03)
- **CUDA Version:** 12.8

---

## LLM Inference Capabilities

### Maximum Model Sizes (Q4 Quantization)
- **Comfortable:** Up to 14B parameters (~9GB VRAM)
- **Maximum:** Up to 32B parameters (~21GB VRAM)
- **Not Recommended:** 70B+ parameters (requires CPU offloading)

### Expected Performance
- **32B models:** 15-25 tokens/second, 80-97% GPU utilization
- **14B models:** 30-40 tokens/second, 80-90% GPU utilization
- **8B models:** 40-50 tokens/second, 70-85% GPU utilization

### Storage Capacity
- **Model Storage:** ~3.5 TB available (can store 100+ models)
- **Working Data:** ~900 GB available for logs, datasets, exports

---

## Power & Thermal Considerations

- **System TDP:** ~500-600W under full load
- **GPU Power Draw:** Up to 350W during inference
- **Recommended PSU:** 1000W+ (Dell T5820 typically comes with 950W)
- **Cooling:** Stock Dell workstation cooling sufficient for sustained workloads
- **Typical GPU Temp:** 50-65°C under load (well within safe range)

---

## Expansion Potential

- **Additional GPU:** Second PCIe x16 slot available for multi-GPU setup
- **Memory Expansion:** Supports up to 512GB RAM (8x 64GB DIMMs)
- **Storage:** Additional NVMe slots and SATA ports available
- **Network:** Gigabit Ethernet standard, 10GbE optional

---

## Notes

- This system is optimized for AI research and development, not gaming
- ECC memory provides error correction for reliable long-running inference tasks
- Workstation-class reliability with server-grade components
- HP OEM RTX 3090 uses reference PCB with adequate cooling for sustained loads
