#!/bin/bash

# Generate project-specific ML environment skill

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${1:-.}"  # Default to current directory
ENV_PATH="$SCRIPT_DIR/ml-env"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}Generating ML environment skill for project...${NC}"
echo "Environment path: $ENV_PATH"
echo "Target directory: $TARGET_DIR"

# Create .claude/skills/ml-env directory
SKILL_DIR="$TARGET_DIR/.claude/skills/ml-env"
mkdir -p "$SKILL_DIR"

# Create SKILL.md
cat > "$SKILL_DIR/SKILL.md" << 'SKILLEOF'
---
name: ml-env
description: Use this skill when the user asks about the ML environment, PyTorch setup, GPU configuration, running ML code, or activating the Python environment. Provides information about the pre-configured PyTorch environment including activation commands, installed packages, and hardware-specific setup.
allowed-tools: Read, Bash
---

# ML Environment Skill

This project uses a pre-configured ML environment with PyTorch that automatically detects your hardware (NVIDIA GPU, AMD GPU, or CPU) and installs the appropriate PyTorch build.

## Environment Activation

**IMPORTANT**: Before running any Python code, ML scripts, or installing packages, you must activate the environment.

SKILLEOF

# Add the environment path to the skill
echo "" >> "$SKILL_DIR/SKILL.md"
echo "Activation command:" >> "$SKILL_DIR/SKILL.md"
echo '```bash' >> "$SKILL_DIR/SKILL.md"
echo "source $ENV_PATH/bin/activate" >> "$SKILL_DIR/SKILL.md"
echo '```' >> "$SKILL_DIR/SKILL.md"

# Continue with the rest of the skill content
cat >> "$SKILL_DIR/SKILL.md" << 'SKILLEOF'

## When to Use This Skill

Activate this skill when:
- User mentions running Python code, ML models, or PyTorch
- User asks about the environment, GPU, or CUDA/ROCm
- User wants to install packages
- User asks about PyTorch version or configuration
- User mentions training, inference, or running models
- User asks about GPU availability or memory

## Installed Packages

The environment includes:
- PyTorch (with CUDA, ROCm, or CPU backend depending on hardware)
- torchvision and torchaudio
- numpy, pandas, matplotlib
- scikit-learn
- jupyter and ipython
- tqdm and tensorboard

To check exact versions:
```bash
uv pip list
```

## Running Python Code

Always activate the environment first:

```bash
source <ENV_PATH>/bin/activate
python your_script.py
```

For Jupyter notebooks:
```bash
source <ENV_PATH>/bin/activate
jupyter notebook
```

## Installing Additional Packages

Use `uv pip install` when the environment is activated:

```bash
source <ENV_PATH>/bin/activate
uv pip install package-name
```

## Verifying the Environment

To check if PyTorch and GPU are working:

```bash
python -c 'import torch; print(f"PyTorch: {torch.__version__}"); print(f"GPU Available: {torch.cuda.is_available()}"); print(f"Device: {torch.cuda.get_device_name(0) if torch.cuda.is_available() else \"CPU\"}")'
```

## Hardware Detection

The environment was set up with automatic hardware detection:

- **NVIDIA GPU**: Uses CUDA (check with `nvidia-smi`)
- **AMD GPU**: Uses ROCm (check with `rocm-smi`)
- **CPU-only**: Falls back to CPU computation

## Common Tasks

### Training a Model
```python
import torch

# Always check device
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
print(f"Using device: {device}")

# Move model and data to device
model = model.to(device)
data = data.to(device)
```

### Checking GPU Memory
```python
import torch

if torch.cuda.is_available():
    print(f"Allocated: {torch.cuda.memory_allocated()/1e9:.2f}GB")
    print(f"Reserved: {torch.cuda.memory_reserved()/1e9:.2f}GB")
```

### Monitoring GPU
```bash
# NVIDIA
watch -n 1 nvidia-smi

# AMD
watch -n 1 rocm-smi
```

## Troubleshooting

### Environment Not Activated
**Error**: `ModuleNotFoundError: No module named 'torch'`
**Solution**: Activate the environment first

### GPU Not Detected
**Check**:
1. Is environment activated?
2. For NVIDIA: Run `nvidia-smi`
3. For AMD: Run `rocm-smi`
4. Verify with Python: `python -c "import torch; print(torch.cuda.is_available())"`

### Performance Issues
- Enable benchmarking: `torch.backends.cudnn.benchmark = True`
- Use mixed precision training with `torch.cuda.amp`
- Monitor GPU utilization

## Hardware-Specific Notes

See the ml-env-setup directory for detailed documentation:
- `HARDWARE.md` - Hardware-specific guides
- `STRIX_HALO.md` - For AMD Strix Halo (gfx1151)
- `README.md` - General setup information
- `UPDATE.md` - Updating packages

## Best Practices

1. **Always activate first**: Check that environment is active before running code
2. **Move to device**: Explicitly move models and tensors to GPU
3. **Monitor memory**: Keep an eye on GPU memory usage
4. **Test on CPU first**: Develop with small data on CPU, scale to GPU
5. **Clean up**: Use `torch.cuda.empty_cache()` if needed

## Example Workflow

```bash
# 1. Activate environment
source <ENV_PATH>/bin/activate

# 2. Verify setup
python -c "import torch; print(torch.__version__); print(torch.cuda.is_available())"

# 3. Run your code
python train.py

# 4. Monitor (in another terminal)
nvidia-smi -l 1  # or rocm-smi for AMD
```

## When Running Code

Before executing any Python code that uses PyTorch:
1. First activate the environment
2. Then run the Python command
3. Do not try to activate inside Python - it must be done in bash first

Example of correct usage:
```bash
source <ENV_PATH>/bin/activate && python script.py
```

SKILLEOF

# Replace <ENV_PATH> placeholder with actual path
sed -i "s|<ENV_PATH>|$ENV_PATH|g" "$SKILL_DIR/SKILL.md"

echo -e "${GREEN}✓ Created ML environment skill at $SKILL_DIR${NC}"
echo ""
echo -e "${YELLOW}The skill will be automatically available in Claude Code${NC}"
echo "Claude will use this skill when you ask about:"
echo "  - Running ML code or PyTorch"
echo "  - GPU configuration"
echo "  - Environment activation"
echo "  - Installing packages"
echo ""
