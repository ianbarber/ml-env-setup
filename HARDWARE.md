# Hardware Compatibility Guide

This document provides specific guidance for each of your machines.

## Your Machine Configuration Summary

| Machine | GPU | Platform | Recommended PyTorch Config | Status |
|---------|-----|----------|---------------------------|--------|
| **Desktop** | RTX 5090 | Linux | CUDA 13.0 or Nightly | Experimental |
| **Laptop** | RTX 4060 | WSL2 | CUDA 12.8 | Stable |
| **Thinkpad** | None | WSL2 | CPU-only | Stable |
| **Ubuntu PC** | Strix Halo (gfx1151) | Linux | ROCm 6.4.4+ Nightlies | Community-Supported |
| **DGX Spark** | GB200 (GB10) | Linux | Nightly CUDA 13.0 | Experimental |
| **Mini PC** | RTX 3090 | Linux | CUDA 12.8 | Stable |

---

## Machine-Specific Setup Instructions

### 1. Desktop - RTX 5090 (SM120)

**GPU**: NVIDIA GeForce RTX 5090
**Compute Capability**: sm_120 (Blackwell architecture)
**Platform**: Native Linux
**Status**: ⚠️ Experimental

#### Setup Command
```bash
cd /home/ianbarber/ml-env-setup
./setup-universal.sh
# Choose option 2 (PyTorch nightly) for best compatibility
```

#### Expected Behavior
- PyTorch 2.9.0 stable has experimental sm_120 support
- May fall back to PTX JIT compilation (slower performance)
- **Recommended**: Use PyTorch nightly builds for native sm_120 support

#### Verification
```bash
./validate.sh
# Look for: Compute Capability: (12, 0)
# Check for PTX warnings in logs
```

#### Known Issues
- Limited optimization for sm_120 in stable PyTorch
- Some operations may fall back to CPU
- Performance may improve with nightly builds

---

### 2. Laptop - RTX 4060 on WSL2

**GPU**: NVIDIA GeForce RTX 4060
**Compute Capability**: sm_89 (Ada Lovelace architecture)
**Platform**: WSL2 (Windows Subsystem for Linux)
**Status**: ✅ Stable

#### Setup Command
```bash
cd /home/ianbarber/ml-env-setup
./setup-universal.sh
# Will auto-detect WSL2 and RTX 4060, installs CUDA 12.8
```

#### WSL2-Specific Notes
- **IMPORTANT**: Do NOT install Linux NVIDIA drivers in WSL2
- Uses Windows NVIDIA driver (must be version 520+)
- Run `nvidia-smi` from WSL2 to verify driver access
- CUDA toolkit is NOT required (PyTorch includes it)

#### Verification
```bash
./validate.sh
# Should show: CUDA Available: True
# Should show: WSL2 Environment Detected
```

#### If CUDA Not Working
1. Update Windows NVIDIA driver
2. Restart WSL: `wsl --shutdown` (from Windows)
3. Rerun setup: `./setup-universal.sh`

---

### 3. Thinkpad - No GPU on WSL2

**GPU**: None
**Platform**: WSL2
**Status**: ✅ Stable (CPU-only)

#### Setup Command
```bash
cd /home/ianbarber/ml-env-setup
./setup-universal.sh
# Will auto-detect no GPU and install CPU-only PyTorch
```

#### What to Expect
- PyTorch will use CPU for all computations
- Slower than GPU but fully functional
- Good for development, testing, and small models
- Consider using smaller batch sizes

#### Verification
```bash
./validate.sh
# Should show: CPU-only PyTorch (No GPU backend detected)
```

#### Use Cases
- Development and debugging
- Small-scale experiments
- Testing code before running on GPU machines
- Educational purposes

---

### 4. Ubuntu PC - Strix Halo (AMD APU)

**GPU**: AMD Radeon 8060S (Strix Halo, gfx1151)
**Architecture**: RDNA 3.5 / Ryzen AI Max+ 395
**Platform**: Native Ubuntu 24.04+
**Status**: ⚠️ Experimental (Community Support)

#### Prerequisites

1. **Ubuntu 24.04 LTS or newer** (Linux kernel 6.16.9+ recommended)
2. **ROCm 6.4.4+ or ROCm 7.0.2+** installed
3. **User groups**: Must be in `render` and `video` groups

```bash
# Check if ROCm is installed
rocm-smi
rocminfo | grep gfx1151

# Check user groups
groups
# Should show: render video

# If not in groups, add yourself:
sudo usermod -aG render,video $USER
newgrp render  # Or logout and login

# If ROCm not installed, see:
# https://rocm.docs.amd.com/en/latest/deploy/linux/quick_start.html
```

#### Setup Command
```bash
cd /home/ianbarber/ml-env-setup
./setup-universal.sh
# Script will detect gfx1151 and offer ROCm options:
#   1) ROCm 6.4.4+ Nightlies (RECOMMENDED)
#   2) ROCm 7.9 Stable gfx1151
#   3) ROCm 7.0.2+ Nightlies (Experimental)
#   4) CPU-only
```

#### Critical Information

**⚠️ Official PyTorch wheels DO NOT work with gfx1151!**

You MUST use:
- AMD community nightlies: `https://rocm.nightlies.amd.com/v2/gfx1151/`
- AMD stable gfx1151 builds: `https://repo.amd.com/rocm/whl/gfx1151/`
- Community builds from scottt's repo: `https://github.com/scottt/rocm-TheRock/releases`

The setup script handles this automatically.

#### What Works

| Feature | Status | Notes |
|---------|--------|-------|
| PyTorch | ✅ Works | Via nightlies/community builds |
| Basic ML | ✅ Works | Matrix ops, forward/backward pass |
| LLMs (7B-13B) | ✅ Works | ~14-26GB VRAM needed |
| LLMs (30B) | ✅ Works | Requires GTT memory config |
| LLMs (65B+) | ❌ No | Exceeds available memory |
| Training | ✅ Works | May be slower than data center GPUs |
| Inference | ✅ Works | Good performance for size |

#### Memory Configuration

**Default**: ~33GB GPU-accessible memory
**With GTT**: Up to 113GB on 64GB RAM systems

To enable GTT memory for large models:
```bash
# See detailed instructions at:
# https://github.com/ianbarber/strix-halo-skills
```

This allows running 30B parameter models!

#### Verification
```bash
./validate.sh
# Should show:
# ✓ ROCm Backend Detected
# Architecture: gfx1151
```

Expected output:
```
=== ML Environment Validation ===
✓ Environment directory found
1. Python Version: Python 3.14.0
3. PyTorch Installation: PyTorch: 2.x.x+rocm
✓ ROCm Backend Detected
5. ROCm Information
ROCm Version: 6.4.4 (or 7.0.2+)
GPU Count: 1
6. GPU Details
GPU 0:
  Name: AMD Radeon Graphics (gfx1151)
✓ GPU computation successful
```

#### Recommended: ROCm 6.4.4+ Nightlies

This is the **most stable** option:
- Well-tested by community
- Good performance
- Fewer bugs than experimental ROCm 7

#### Experimental: ROCm 7.9 Stable gfx1151

Official stable release for gfx1151:
- Newest features
- Official AMD support
- May have undiscovered issues

#### Very Experimental: ROCm 7.0.2+ Nightlies

Cutting edge:
- Latest improvements
- May be unstable
- Use only if you need bleeding-edge features

#### Troubleshooting

**Problem**: "HIP error: invalid device function"
- You're using official PyTorch wheels (they don't work!)
- Solution: Reinstall with nightlies via `./setup-universal.sh`

**Problem**: ROCm not detecting GPU
```bash
# Check GPU is visible
lspci | grep -i vga
# Should show: AMD/ATI Device [1002:7d20]

# Check ROCm info
rocminfo | grep gfx1151

# Check user groups
groups | grep -E "render|video"
```

**Problem**: Out of memory on large models
- Configure GTT memory (see your strix-halo-skills repo)
- Reduce batch size
- Use smaller models
- Try CPU-only for development

**Problem**: Slow performance
- Ensure you're using GPU (check `./validate.sh`)
- Monitor with: `rocm-smi`
- Some ops may not be optimized for APU architecture

#### Performance Tips

```python
import torch

# Check you're using ROCm
print(f"ROCm available: {torch.cuda.is_available()}")
print(f"ROCm version: {torch.version.hip}")

# Enable benchmarking
torch.backends.cudnn.benchmark = True

# Monitor memory
print(f"Allocated: {torch.cuda.memory_allocated()/1e9:.2f}GB")
print(f"Reserved: {torch.cuda.memory_reserved()/1e9:.2f}GB")
```

#### Resources

- **Your setup guide**: https://github.com/ianbarber/strix-halo-skills
- **Community discussion**: https://github.com/ROCm/TheRock/discussions/655
- **scottt's builds**: https://github.com/scottt/rocm-TheRock/releases
- **AMD ROCm docs**: https://rocm.docs.amd.com/

---

### 5. DGX Spark ASUS Ascent - GB200 (GB10)

**GPU**: NVIDIA GB200 (Blackwell architecture)
**Compute Capability**: sm_120
**Platform**: Native Linux (likely Ubuntu)
**Status**: ⚠️ Experimental

#### Setup Command
```bash
cd /home/ianbarber/ml-env-setup
./setup-universal.sh
# Will detect GB200
# STRONGLY RECOMMENDED: Choose option 2 (PyTorch nightly)
```

#### Important Notes
- GB200 is a data center GPU with sm_120 compute capability
- Same limitations as RTX 5090 for PyTorch stable release
- **PyTorch nightly builds are STRONGLY recommended**
- This is a high-end GPU - ensure proper cooling and power

#### Verification
```bash
./validate.sh
# Look for: Compute Capability: (12, 0)
# Check GPU memory (should be 96GB or 144GB depending on model)
```

#### Optimization Tips
For multi-GPU setups:
```bash
# Check all GPUs
nvidia-smi --list-gpus

# Set specific GPU
export CUDA_VISIBLE_DEVICES=0  # Use first GPU only
export CUDA_VISIBLE_DEVICES=0,1  # Use first two GPUs

# In Python
import torch
model = torch.nn.DataParallel(model)  # Use multiple GPUs
```

#### Performance Considerations
- GB200 has massive memory bandwidth - ideal for large models
- Multi-GPU training is well supported
- Consider using PyTorch FSDP for model parallelism
- NVLink support for GPU-to-GPU communication

---

### 6. Mini PC - RTX 3090

**GPU**: NVIDIA GeForce RTX 3090
**Compute Capability**: sm_86 (Ampere architecture)
**Platform**: Native Linux
**Status**: ✅ Stable (Best support)

#### Setup Command
```bash
cd /home/ianbarber/ml-env-setup
./setup-universal.sh
# Will auto-detect RTX 3090, installs CUDA 12.8
```

#### Why This Is The Most Stable
- Ampere architecture (sm_86) has excellent PyTorch support
- PyTorch 2.9.0 is well-tested with RTX 3090
- CUDA 12.8 is mature and stable
- 24GB VRAM is great for ML workloads

#### Verification
```bash
./validate.sh
# Should show: Compute Capability: (8, 6)
# Should show: Memory: 24.00 GB
```

#### Use Cases
- Production ML workloads
- Training medium to large models
- Research and development
- Stable baseline for testing code

#### Performance Tips
```python
import torch

# Enable TF32 for faster computation (Ampere feature)
torch.backends.cuda.matmul.allow_tf32 = True
torch.backends.cudnn.allow_tf32 = True

# Enable cudnn benchmarking for faster training
torch.backends.cudnn.benchmark = True
```

---

## General Best Practices

### Sharing the Environment Across Machines

To use the same setup on all machines:

1. **Copy the setup directory to each machine**:
```bash
# On source machine
tar -czf ml-env-setup.tar.gz ml-env-setup/

# On target machine
tar -xzf ml-env-setup.tar.gz
cd ml-env-setup
./setup-universal.sh
```

2. **Use git for version control** (recommended):
```bash
cd ml-env-setup
git init
git add .
git commit -m "Initial ML environment setup"
git remote add origin <your-repo-url>
git push -u origin main

# On other machines
git clone <your-repo-url>
cd ml-env-setup
./setup-universal.sh
```

### When to Use CPU-Only

Consider CPU-only PyTorch when:
- GPU support is experimental (Strix Halo)
- Developing/debugging code
- Running inference on small models
- GPU is unavailable

### Keeping Environments in Sync

Create a shared requirements file:
```bash
# On your reference machine (e.g., RTX 3090)
source ml-env/bin/activate
uv pip freeze > requirements-shared.txt

# On other machines
source ml-env/bin/activate
uv pip install -r requirements-shared.txt
```

### Testing Code Across Machines

```python
import torch

def get_device():
    """Auto-detect best available device"""
    if torch.cuda.is_available():
        device = torch.device("cuda")
        print(f"Using CUDA: {torch.cuda.get_device_name(0)}")
    else:
        device = torch.device("cpu")
        print("Using CPU")
    return device

# Use in your code
device = get_device()
model = model.to(device)
data = data.to(device)
```

---

## Quick Reference Table

### PyTorch Build by Machine

| Machine | Script Choice | PyTorch Version | Index URL |
|---------|---------------|-----------------|-----------|
| Desktop (5090) | Nightly | Latest | nightly/cu128 |
| Laptop (4060) | Stable | 2.9.0 | cu128 |
| Thinkpad (No GPU) | Stable | 2.9.0 | cpu |
| Ubuntu (Strix) | **Nightlies** | **Latest** | **rocm.nightlies.amd.com/v2/gfx1151/** |
| DGX (GB200) | Nightly | Latest | nightly/cu128 |
| Mini PC (3090) | Stable | 2.9.0 | cu128 |

**Note**: Strix Halo requires special gfx1151 builds - official PyTorch doesn't work!

### GPU Version Requirements

| GPU Architecture | Compute Cap / GFX | Backend Version | Driver Version |
|------------------|-------------------|-----------------|----------------|
| Blackwell (5090, GB200) | sm_120 | CUDA 13.0 or 12.8 | NVIDIA 550+ |
| Ada Lovelace (4060) | sm_89 | CUDA 12.8 | NVIDIA 520+ |
| Ampere (3090) | sm_86 | CUDA 12.8 or 11.8 | NVIDIA 520+ |
| Strix Halo (gfx1151) | gfx1151 | ROCm 6.4.4+ or 7.0.2+ | ROCm drivers |
| CPU-only | N/A | N/A | N/A |

---

## Need Help?

1. **Run validation**: `./validate.sh` on each machine
2. **Check logs**: `setup-*.log` files contain detailed installation info
3. **Review documentation**:
   - `README.md` - General setup
   - `UPDATE.md` - Updating and version management
   - `HARDWARE.md` - This file (machine-specific guidance)
4. **Test across machines**: Use the simple test script below

### Simple Test Script

Save as `test_pytorch.py`:
```python
import torch
import sys

print(f"PyTorch version: {torch.__version__}")
print(f"CUDA available: {torch.cuda.is_available()}")

if torch.cuda.is_available():
    print(f"CUDA version: {torch.version.cuda}")
    print(f"GPU count: {torch.cuda.device_count()}")
    for i in range(torch.cuda.device_count()):
        print(f"GPU {i}: {torch.cuda.get_device_name(i)}")
        print(f"  Compute capability: {torch.cuda.get_device_capability(i)}")

    # Test computation
    x = torch.randn(1000, 1000, device='cuda')
    y = x @ x.T
    print("✅ GPU computation successful!")
else:
    # Test CPU computation
    x = torch.randn(1000, 1000)
    y = x @ x.T
    print("✅ CPU computation successful!")

sys.exit(0)
```

Run on each machine:
```bash
source ml-env/bin/activate
python test_pytorch.py
```
