# Changelog

All notable changes to the ml-env skill are documented here.

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
