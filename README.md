# ML Environment Skill for Claude Code

A Claude Code skill that sets up **isolated conda environments** with PyTorch.
It **auto-detects your hardware** (NVIDIA, AMD, or CPU) and installs the matching
PyTorch build, then validates it works.

Designed for consistency across a small fleet of Linux boxes — NVIDIA (Ampere /
Ada / Blackwell), AMD Strix Halo (gfx1151), and CPU-only.

## Installation

### Option 1: Symlink (recommended — get updates via `git pull`)

```bash
git clone https://github.com/ianbarber/ml-env-setup.git ~/ml-env-setup
ln -s ~/ml-env-setup/skill ~/.claude/skills/ml-env
# Update later:
cd ~/ml-env-setup && git pull
```

### Option 2: Copy (standalone)

```bash
git clone https://github.com/ianbarber/ml-env-setup.git
cp -r ~/ml-env-setup/skill ~/.claude/skills/ml-env
```

Requires **conda** (Miniforge/Miniconda/Anaconda) on the machine. `uv` is used as
a faster pip front-end when present, but is optional.

## Quick start

Once installed, in a Claude Code session:

```
Help me set up a new ML project at ~/my-ml-project
```

Claude creates the project dir, then runs the setup script, which:

1. Detects hardware (NVIDIA / AMD / CPU / WSL2).
2. Creates a conda env `ml-<project>` (Python 3.13).
3. Installs **PyTorch 2.13.0** with the right backend (CUDA `cu132`, ROCm `7.2`,
   or CPU; gfx1151 uses verified AMD tracks).
4. Installs common ML libs (numpy, pandas, scikit-learn, jupyter, …).
5. Writes a `.gitignore` and a setup log into the project.

## Using your environment

```bash
conda activate ml-<project>
python -c "import torch; print(torch.__version__, torch.cuda.is_available())"
```

Override the env name or versions at setup time:

```bash
ENV_NAME=myexp PYTHON_VERSION=3.12 bash ~/.claude/skills/ml-env/scripts/setup-universal.sh
```

## Validating

```bash
cd ~/my-ml-project
ENV_NAME=ml-<project> bash ~/.claude/skills/ml-env/scripts/validate.sh
```

Reports Python, PyTorch, backend (CUDA/ROCm), device + compute capability / gfx
arch, and runs a real matmul.

## Version defaults (verified 2026-07-14; prefer latest)

| Component | Default | Notes |
|---|---|---|
| Python | 3.13 | overridable via `PYTHON_VERSION` |
| PyTorch | 2.13.0 | latest stable on the indexes below |
| CUDA (NVIDIA) | cu132 | CUDA 13.2; runs on driver 580.x via minor-version compat (cu130 fallback) |
| ROCm (generic AMD) | rocm7.2 | |
| gfx1151 (Strix Halo) | TheRock multi-arch nightly | official wheels don't work |

## Supported hardware

- **NVIDIA**: RTX 30/40/50 series, GB10, data-center — CUDA `cu132`. Blackwell
  (sm_120+) is supported natively by PyTorch 2.13. WSL2 with Windows drivers.
- **AMD RDNA / other** (non-gfx1151): ROCm `rocm7.2`. Requires `render`+`video`
  groups.
- **AMD Strix Halo** (gfx1151): special — see
  [TROUBLESHOOTING.md](skill/TROUBLESHOOTING.md). TheRock nightly (default) or
  AMD-supported stable (ROCm 7.2.1). Deep setup (GTT memory, flash-SDPA, kernels)
  is owned by the [strix-halo-setup](https://github.com/ianbarber/strix-halo-skills)
  skill.
- **CPU-only**: works anywhere.

## What's in the skill

`~/.claude/skills/ml-env/`:
- **SKILL.md** — interactive setup & troubleshooting entry point.
- **TROUBLESHOOTING.md** — hardware-specific issues (Strix Halo, WSL2, drivers).
- **UPDATE.md** — updating PyTorch and packages.
- **scripts/setup-universal.sh**, **scripts/validate.sh**.

## Contributing

Testing checklist:
- [ ] Runs on your hardware (NVIDIA / AMD / CPU)
- [ ] Hardware detection is correct
- [ ] PyTorch installs and detects the GPU
- [ ] `validate.sh` passes

Changes: update `scripts/setup-universal.sh` for hardware logic, `SKILL.md` /
`TROUBLESHOOTING.md` for guidance, and keep the version table here and in
`CLAUDE.md` in sync.

## License

MIT — free to use and modify.
