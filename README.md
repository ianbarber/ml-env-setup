# ML Environment Skill for Claude Code

A Claude Code skill that sets up isolated ML environments with PyTorch. **Automatically detects your hardware** (NVIDIA GPU, AMD GPU, or CPU) and installs the appropriate PyTorch build.

Supports:
- **NVIDIA GPUs**: RTX 3090, 4060, 5090, GB200, etc. (CUDA 12.8/13.0)
- **AMD GPUs**: RDNA 2/3, Strix Halo (ROCm 6.2/6.4.4+/7.x)
- **CPU-only**: For any system without GPU
- **WSL2**: Windows Subsystem for Linux support

## Installation

### Option 1: Symlink (Recommended - Get Updates)

Clone the repository, then symlink the skill directory:

```bash
# Clone once
git clone https://github.com/ianbarber/ml-env-setup.git

# Symlink to Claude Code skills directory (all users can install this way)
ln -s ~/ml-env-setup/skill ~/.claude/skills/ml-env

# Get updates anytime
cd ~/ml-env-setup && git pull
```

### Option 2: Copy (Standalone)

Clone and copy the skill directory:

```bash
git clone https://github.com/ianbarber/ml-env-setup.git
cp -r ~/ml-env-setup/skill ~/.claude/skills/ml-env
```

## Quick Start

Once installed, ask Claude Code:

```
Help me set up a new ML project at ~/my-ml-project
```

Claude will:
1. Create your project directory
2. Detect your hardware (NVIDIA/AMD/CPU)
3. Install PyTorch with the right backend
4. Set up ML libraries (numpy, pandas, scikit-learn, jupyter, etc.)
5. Validate the installation
6. Show you how to activate and use it

## What You Get

Each project gets:
- **ml-env/** - Isolated Python environment with PyTorch
- **.gitignore** - Ignores ml-env/, data/, models/, logs/, etc.

Everything else is in the skill at `~/.claude/skills/ml-env/`:
- **SKILL.md** - Interactive setup and troubleshooting guide
- **TROUBLESHOOTING.md** - Detailed hardware-specific setup (Strix Halo, WSL2, etc.)
- **UPDATE.md** - Updating PyTorch and dependencies
- **scripts/** - Setup and validation scripts

## Using Your Environment

```bash
cd ~/my-ml-project

# Activate the environment
source ml-env/bin/activate

# Or if you use conda
source ml-env/activate-safe.sh

# Start coding
python your_script.py
```

## Verifying Installation

```bash
# Check PyTorch and GPU
python -c "import torch; print(torch.__version__); print(f'CUDA: {torch.cuda.is_available()}')"

# Run full validation
bash ~/.claude/skills/ml-env/scripts/validate.sh
```

## Features

- 🔍 **Auto-detection**: Identifies NVIDIA, AMD, CPU hardware and installs the right PyTorch build
- 🚀 **Fast setup**: Uses `uv` for faster package installation
- 🎯 **Interactive**: Claude guides you through setup with questions for special hardware
- 🤖 **Claude integrated**: Works directly in Claude Code - no command line needed
- 📝 **Comprehensive docs**: Troubleshooting guides for all supported GPUs
- ✅ **Validation**: Built-in testing to verify your installation
- 🔄 **WSL2 support**: Works seamlessly on Windows Subsystem for Linux
- 📦 **Project-ready**: Each project gets isolated environments with its own PyTorch version

## Current Versions (2026)

- **PyTorch**: 2.10.0
- **Python**: 3.13 (or 3.12 if needed)
- **CUDA**: 12.8 (stable), 13.0 (Blackwell experimental)
- **ROCm**: 6.2 (RDNA), 6.4.4+/7.x (Strix Halo)
- **Key libraries**: numpy, pandas, matplotlib, scikit-learn, jupyter, accelerate, tensorboard

## Supported Hardware

### NVIDIA GPUs
- RTX 50 series (5090, 5080, etc.) - Blackwell - CUDA 13.0 experimental
- RTX 40 series (4090, 4080, 4060, etc.) - Ada Lovelace - CUDA 12.8
- RTX 30 series (3090, 3080, etc.) - Ampere - CUDA 12.8
- WSL2 with Windows NVIDIA drivers

### AMD GPUs
- **RDNA 3** (RX 7000 series) - ROCm 6.2
- **RDNA 2** (RX 6000 series) - ROCm 6.2
- **Strix Halo** (Ryzen AI MAX+, gfx1151) - ROCm 6.4.4+/7.x (requires special setup)

### CPU-Only
- Works on any system without GPU
- Good for development and testing

## Common Questions

**Q: Do I need to clone the repo after installing the skill?**
A: No, symlink is enough. But keeping the repo lets you easily pull updates.

**Q: How do I update PyTorch or packages?**
A: See `~/.claude/skills/ml-env/UPDATE.md` or ask Claude in your project.

**Q: Can I have multiple projects with different PyTorch versions?**
A: Yes! Each project has its own isolated `ml-env/` - you can customize each one.

**Q: Strix Halo setup looks complicated. Do I need special configuration?**
A: Claude will guide you through it. See `~/.claude/skills/ml-env/TROUBLESHOOTING.md` for GTT memory setup.

**Q: What about WSL2 on Windows?**
A: Works great! Just use Windows NVIDIA drivers (don't install Linux drivers in WSL2).

## Contributing

This is a single-purpose skill repo. Contributions welcome:

**Testing checklist:**
- [ ] Runs on your hardware type (NVIDIA/AMD/CPU)
- [ ] Hardware detection works correctly
- [ ] PyTorch installs and detects GPU/CPU
- [ ] Validation passes
- [ ] Skill guides users properly

### Changes to make:

1. **Hardware support**: Update `scripts/setup-universal.sh` hardware detection
2. **Skill guidance**: Update `skill/SKILL.md` with new workflows
3. **Documentation**: Update troubleshooting or setup docs
4. **Scripts**: Improve setup or validation logic

## License

MIT License - Free to use and modify.

## Support

- **Issues**: Open an issue on GitHub
- **Questions**: Ask Claude Code directly once the skill is installed
- **Full docs**: See `~/.claude/skills/ml-env/TROUBLESHOOTING.md` after installation
