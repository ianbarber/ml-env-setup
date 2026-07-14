# Changelog

All notable changes to the ml-env skill are documented here.

## [2026-07-14] - Align docs to conda-first, fix gfx1151 wheels, prefer latest

### Fixed
- **gfx1151 wheel guidance was wrong.** The "recommended"
  `repo.amd.com/rocm/whl/gfx1151/` index serves only torch 2.9.1, and the script's
  `torch==2.10.0` pin would not resolve from it. Replaced with the two verified
  tracks from strix-halo-setup v2.0.0: TheRock multi-arch nightly (default) and
  AMD-supported stable ROCm 7.2.1 (repo.radeon.com).
- **uv clobbered hardware-specific torch.** `install_ml_packages` used
  `uv pip install -U`, whose holistic re-resolution replaced the gfx1151 ROCm
  torch with a CUDA wheel. Now uses plain `pip install` (no `-U`).
- **validate.sh printed empty sections.** `conda run ... python - <<HEREDOC` does
  not forward stdin on conda 25.x; the probe now runs from a temp file.
- **ensure_conda** now checks `~/miniforge`, `~/miniconda3`, `~/anaconda3`, and
  `~/miniforge3` (was only the first two; conda is often off-PATH in
  non-interactive shells).
- Setup log now written into the project dir (was the skill dir).

### Changed
- Docs (SKILL/TROUBLESHOOTING/UPDATE/README/CLAUDE) fully rewritten to match the
  conda-first scripts; all `uv`/`ml-env/` venv references removed.
- **Prefer latest versions** (verified 2026-07-14): Python 3.13, PyTorch 2.13.0,
  CUDA cu130 (not cu132 — fleet NVIDIA boxes are driver 580.x = max CUDA 13.0),
  ROCm rocm7.2. Versions are overridable vars at the top of setup-universal.sh.
- Blackwell (sm_120+) no longer treated as experimental — PyTorch 2.13 on cu130
  supports it natively.
- Env-var guidance flipped to "do not set globally" (HSA_ENABLE_SDMA,
  PYTORCH_HIP_ALLOC_CONF), matching strix-halo-setup v2.0.0.

### Removed
- `CLAUDE_WEBHOOK.md` (off-topic GitHub-app boilerplate; workflow already in
  `.github/workflows/claude.yml`).
- Generic PyTorch tutorial content from TROUBLESHOOTING.md (OOM/mixed-precision
  training loops) — deferred to the PyTorch docs.

## [2026-01-28] - ROCm 7 Preferred for Strix Halo

### Changed
- **Strix Halo (gfx1151)**: ROCm 7 stable builds are now the recommended option
  - New index URL: `https://repo.amd.com/rocm/whl/gfx1151/`
  - ~2.5x performance improvement over ROCm 6.x (~31 TFLOPS BF16 vs ~12 TFLOPS)
- ROCm 6.4.4+ nightlies moved to fallback option (still available if ROCm 7 has issues)
- Updated menu order in setup script to reflect new recommendations

### Added
- Reference to `~/Projects/amdtest` as a working gfx1151 setup example
- ROCm 7.x considerations in TROUBLESHOOTING.md (benefits, limitations, env vars)
- Recommended environment variables for ROCm 7.x stability

### Documentation
- Updated SKILL.md with ROCm 7 index URLs and performance info
- Updated TROUBLESHOOTING.md with new installation order and ROCm 7 details
- Clearer menu options in setup-universal.sh for gfx1151 users

## [2026-01-23] - Initial Release

### Added
- Universal ML environment setup supporting NVIDIA, AMD, and CPU
- Hardware auto-detection for NVIDIA (CUDA 12.8/13.0) and AMD (ROCm)
- Special handling for Strix Halo (gfx1151) with AMD community builds
- Blackwell GPU support with CUDA 13.0 experimental option
- WSL2 support with Windows NVIDIA driver detection
- Conda-safe activation wrapper for mixed environments
- Validation script for environment testing
