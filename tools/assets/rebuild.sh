#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
work="${LTO_ASSET_WORK:-/tmp/last-train-out-assets}"
export LTO_SOURCE_DIR="${LTO_SOURCE_DIR:-$work/sources}"
export LTO_BUILD_DIR="${LTO_BUILD_DIR:-$work/build}"
export LTO_MPFB_SOURCE="${LTO_MPFB_SOURCE:-$work/mpfb2}"
export LTO_MAKEHUMAN_DATA="${LTO_MAKEHUMAN_DATA:-$work/makehuman}"
mkdir -p "$LTO_BUILD_DIR"
python3 tools/fetch_pbr.py
blender -b -t 4 --python-exit-code 1 --python tools/assets/build_worker.py -- --no-render
for script in retarget_worker convert_props convert_locomotive build_carriages; do
    blender -b -t 4 --python-exit-code 1 --python "tools/assets/$script.py"
done
python3 tools/assets/fetch_environment.py
for script in convert_environment build_railway_environment; do
    blender -b -t 4 --python-exit-code 1 --python "tools/assets/$script.py"
done
python3 tools/assets/check_assets.py
