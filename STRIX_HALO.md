# Strix Halo (gfx1151) Setup Guide

Quick reference for setting up PyTorch on AMD Strix Halo (Ryzen AI Max+ 395, Radeon 8060S, gfx1151).

## Quick Start

```bash
cd /home/ianbarber/ml-env-setup
./setup-universal.sh
# Choose option 1 (ROCm 6.4.4+ Nightlies - RECOMMENDED)
./validate.sh
```

## Critical Information

**⚠️ Official PyTorch wheels DO NOT work with gfx1151!**

You MUST use AMD-specific builds:
- ✅ ROCm 6.4.4+ Nightlies: `https://rocm.nightlies.amd.com/v2/gfx1151/`
- ✅ ROCm 7.9 Stable gfx1151: `https://repo.amd.com/rocm/whl/gfx1151/`
- ✅ Community builds: `https://github.com/scottt/rocm-TheRock/releases`

## Prerequisites Checklist

- [ ] Ubuntu 24.04 LTS or newer
- [ ] Linux kernel 6.16.9+ (recommended)
- [ ] ROCm 6.4.4+ or 7.0.2+ installed
- [ ] User in `render` and `video` groups
- [ ] 64GB+ RAM for large models (30B+)

### Quick Checks

```bash
# Check ROCm
rocminfo | grep gfx1151

# Check user groups
groups | grep -E "render|video"

# If not in groups:
sudo usermod -aG render,video $USER
newgrp render  # Or logout/login
```

## ROCm Options

### Option 1: ROCm 6.4.4+ Nightlies (RECOMMENDED ⭐)

**Status**: Most stable, community-tested

```bash
pip install --index-url https://rocm.nightlies.amd.com/v2/gfx1151/ --pre torch torchvision torchaudio
```

**Pros**:
- Well-tested by community
- Good performance
- Fewer bugs

**Cons**:
- Nightly builds (may change)
- Not "official" stable

### Option 2: ROCm 7.9 Stable gfx1151 (NEWEST)

**Status**: Official AMD stable release for gfx1151

```bash
pip install --index-url https://repo.amd.com/rocm/whl/gfx1151/ torch torchvision torchaudio
```

**Pros**:
- Official AMD release
- Stable URL
- Latest features

**Cons**:
- Newer, may have undiscovered issues
- Less community testing so far

### Option 3: ROCm 7.0.2+ Nightlies (EXPERIMENTAL)

**Status**: Cutting edge, experimental

```bash
pip install --index-url https://rocm.nightlies.amd.com/v2/gfx1151/ --pre torch torchvision torchaudio
```

**Pros**:
- Latest improvements
- Newest ROCm features

**Cons**:
- May be unstable
- Potential bugs
- Not recommended for production

### Option 4: CPU-only (Safe Fallback)

If ROCm doesn't work:

```bash
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
```

## What Works

| Feature | Support | Notes |
|---------|---------|-------|
| PyTorch basics | ✅ Full | Matrix ops, autograd, etc. |
| Training | ✅ Yes | Works well |
| Inference | ✅ Yes | Good performance |
| LLMs 7B-13B | ✅ Yes | ~14-26GB VRAM |
| LLMs 30B | ✅ Yes* | *Requires GTT config |
| LLMs 65B+ | ❌ No | Exceeds memory |
| Multi-GPU | ❌ No | Single APU |

## Memory Configuration

**Default**: ~33GB GPU-accessible memory
**With GTT**: Up to 113GB (on 64GB RAM system)

GTT allows using system RAM as GPU memory for large models.

**Setup GTT**: See https://github.com/ianbarber/strix-halo-skills

## Verification

After installation:

```bash
./validate.sh
```

Expected output:
```
✓ ROCm Backend Detected
Architecture: gfx1151
ROCm Version: 6.4.4 (or 7.0.2+)
GPU 0: AMD Radeon Graphics (gfx1151)
✓ GPU computation successful
```

## Testing PyTorch

```python
import torch

# Check ROCm is working
print(f"ROCm available: {torch.cuda.is_available()}")  # Should be True
print(f"ROCm version: {torch.version.hip}")            # Should show version
print(f"Device name: {torch.cuda.get_device_name(0)}") # AMD GPU

# Test computation
x = torch.randn(1000, 1000, device='cuda')
y = x @ x.T  # Matrix multiply on GPU
print(f"Success! Result shape: {y.shape}")
```

## Common Issues

### "HIP error: invalid device function"

**Cause**: Using official PyTorch (doesn't work!)

**Solution**:
```bash
pip uninstall torch torchvision torchaudio
pip install --index-url https://rocm.nightlies.amd.com/v2/gfx1151/ --pre torch torchvision torchaudio
```

### ROCm not detecting GPU

**Check**:
```bash
# GPU visible?
lspci | grep -i vga
# Should show: AMD/ATI Device [1002:7d20]

# ROCm installed?
rocminfo | grep gfx1151

# User groups?
groups | grep -E "render|video"
```

**Fix**:
```bash
# Add to groups
sudo usermod -aG render,video $USER
newgrp render
```

### Out of memory

**Solutions**:
1. Configure GTT memory (see your repo)
2. Reduce batch size
3. Use smaller models
4. Try model quantization

### Slow performance

**Check**:
```bash
# Verify GPU is being used
rocm-smi

# In Python
import torch
print(torch.cuda.is_available())  # Must be True
```

**Optimize**:
```python
import torch

# Enable benchmarking
torch.backends.cudnn.benchmark = True

# Monitor memory
print(f"Allocated: {torch.cuda.memory_allocated()/1e9:.2f}GB")
print(f"Reserved: {torch.cuda.memory_reserved()/1e9:.2f}GB")
```

## Performance Tips

```python
import torch

# 1. Check device
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
print(f"Using: {device}")

# 2. Move model and data to GPU
model = model.to(device)
data = data.to(device)

# 3. Enable benchmarking (finds fastest algorithms)
torch.backends.cudnn.benchmark = True

# 4. Use mixed precision (faster, less memory)
from torch.cuda.amp import autocast, GradScaler

scaler = GradScaler()
with autocast():
    output = model(input)
    loss = criterion(output, target)
```

## Model Size Guidelines

With default memory (~33GB):
- ✅ 7B models in FP16: ~14GB
- ✅ 13B models in FP16: ~26GB
- ⚠️ 30B models: Need GTT
- ❌ 65B+ models: Too large

With GTT configured (113GB on 64GB RAM):
- ✅ 30B models in FP16: ~60GB
- ⚠️ 65B models: Marginal (may be slow)

## Monitoring

```bash
# Watch GPU usage
watch -n 1 rocm-smi

# Check temperature and utilization
rocm-smi --showtemp --showuse

# In Python
import torch
print(f"Memory allocated: {torch.cuda.memory_allocated()/1e9:.2f}GB")
print(f"Memory cached: {torch.cuda.memory_reserved()/1e9:.2f}GB")
print(f"Max memory: {torch.cuda.max_memory_allocated()/1e9:.2f}GB")

# Reset stats
torch.cuda.reset_peak_memory_stats()
```

## Useful Commands

```bash
# System info
rocminfo | grep -E "Marketing|Name|gfx"

# GPU monitoring
rocm-smi

# Check kernel
uname -r  # Should be 6.16.9+

# Check Ubuntu version
lsb_release -a  # Should be 24.04+

# Environment activation
source /home/ianbarber/ml-env-setup/ml-env/bin/activate

# Reinstall PyTorch
pip uninstall torch torchvision torchaudio
pip install --index-url https://rocm.nightlies.amd.com/v2/gfx1151/ --pre torch torchvision torchaudio
```

## Resources

- **Your setup repo**: https://github.com/ianbarber/strix-halo-skills
- **Community discussion**: https://github.com/ROCm/TheRock/discussions/655
- **scottt's builds**: https://github.com/scottt/rocm-TheRock/releases
- **AMD ROCm docs**: https://rocm.docs.amd.com/
- **PyTorch ROCm**: https://pytorch.org/get-started/locally/

## Version Information

**Tested configurations**:
- Ubuntu 24.04 LTS
- Linux kernel 6.16.9+
- ROCm 6.4.4 nightlies (stable)
- ROCm 7.0.2+ nightlies (experimental)
- ROCm 7.9 stable gfx1151 (newest)
- Python 3.11/3.12/3.14

## Support

**Community**:
- ROCm/TheRock GitHub discussions
- PyTorch forums (ROCm section)
- Your strix-halo-skills repo

**Known Contributors**:
- @scottt - Community PyTorch builds
- @jammm - ROCm development
- AMD ROCm team

---

## Quick Command Summary

```bash
# Setup
./setup-universal.sh  # Auto-detects gfx1151
./validate.sh         # Test installation

# Verify
rocminfo | grep gfx1151
groups | grep -E "render|video"

# Test PyTorch
python -c "import torch; print(torch.cuda.is_available())"

# Monitor
rocm-smi

# Reinstall
pip uninstall torch torchvision torchaudio
pip install --index-url https://rocm.nightlies.amd.com/v2/gfx1151/ --pre torch torchvision torchaudio
```

## Changelog

- **2025-11**: Initial guide for universal setup script
- Added ROCm 6.4.4+ support (recommended)
- Added ROCm 7.9 stable gfx1151 support
- Added ROCm 7.0.2+ experimental support
- Added GTT memory reference
