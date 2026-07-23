#!/usr/bin/env bash
# WazobiaVoice TTS -- staged install.
#
# Why this isn't just `pip install .`: a plain, single-shot resolve of every
# dependency together sends pip's resolver backtracking through years-old
# releases of deepfilternet and torchmetrics hunting for a combination that
# satisfies stale pins (deepfilternet declares numpy<2.0 as a direct
# requirement; letting the resolver see that alongside a numpy>=2.0 request
# in the same call makes it backtrack all the way to deepfilternet 0.2.3
# from 2021, which uses a poetry build backend we don't have, and fail).
# Installing in stages, with build isolation off for the packages that build
# from source, is the actual fix -- confirmed working end-to-end on
# Python 3.12 / CUDA. Same story for deepfilternet's Rust extension (libdf):
# no prebuilt wheel exists for cp312, and installing cargo/rustc first lets
# pip build it from source instead of silently shipping a broken wrapper.
set -euo pipefail

echo "--- Installing system build tools (cargo/rustc, for deepfilternet's Rust extension) ---"
if command -v apt-get &> /dev/null; then
    apt-get install -y cargo rustc
else
    echo "apt-get not found -- make sure cargo and rustc are installed some other way before continuing."
fi

CONSTRAINT_FILE="$(mktemp)"
echo "numpy>=2.0" > "$CONSTRAINT_FILE"

pip_install () {
    local label="$1"; shift
    echo "--- Installing: $label ---"
    pip install --constraint "$CONSTRAINT_FILE" "$@"
    echo "--- OK: $label ---"
    echo
}

echo "--- Installing: numpy + torch (wheels only) ---"
pip install numpy>=2.0 torch>=2.1 torchaudio>=2.1
echo "--- OK: numpy + torch (wheels only) ---"
echo

pip_install "data/hub libs" \
    "datasets>=2.19,<3.0" "huggingface_hub>=0.30" \
    "transformers>=4.45,<5.1" "safetensors>=0.4.1"

# Pinned explicitly (not left open) so the resolver can't wander back to
# 2021-era 0.3.x/0.4.x/0.5.x releases hunting for a combo that satisfies an
# unbounded 'torchmetrics[audio]' request. 1.4+ is the first line where
# [audio] is stable and numpy-2-compatible.
pip_install "torchmetrics (pinned to stop resolver backtracking)" \
    "torchmetrics[audio]>=1.4"

# maturin installed separately, build isolation still ON for this one (it's
# a normal wheel). Needed because --no-build-isolation below means pip will
# NOT auto-install build backends packages declare in pyproject.toml --
# deepfilterlib declares maturin as its backend, so without this it fails
# with "ModuleNotFoundError: No module named 'maturin'" during metadata prep.
pip_install "maturin (build backend for deepfilterlib)" maturin

# These are exactly the packages that fail egg_info with build isolation on:
# build isolation creates a FRESH env per package to build from source in,
# which does NOT include numpy even though it was just installed above --
# so any legacy setup.py doing `import numpy` at the top dies before
# metadata generation. --no-build-isolation builds against the real
# environment instead, which already has numpy/torch present.
pip_install "audio/build-from-source libs (no build isolation)" \
    --no-build-isolation \
    s3tokenizer einops soundfile omegaconf \
    resemble-perth conformer "librosa>=0.10" onnxruntime pyloudnorm

# deepfilternet's own package metadata declares numpy<2.0 as a direct
# requirement (not just transitive) -- pip has to honor that when resolving
# THIS package specifically, and backtracks hard trying to. Fix: skip its
# dependency resolution entirely and supply its few real runtime deps
# ourselves. Confirmed working end-to-end with numpy 2.x at runtime.
pip_install "deepfilternet sub-deps" \
    --no-build-isolation \
    "appdirs>=1.4,<2.0" "loguru>=0.5" "deepfilterlib==0.5.6"
pip_install "deepfilternet (--no-deps, stale numpy<2.0 pin bypassed)" \
    --no-deps deepfilternet==0.5.6

echo "--- Installing: wazobiavoice-tts itself (--no-deps -- everything real above already handled) ---"
pip install --no-deps -e "$(dirname "$0")/.."
echo "--- OK: wazobiavoice-tts ---"
echo

python3 -c "
import numpy
assert numpy.__version__.startswith('2.'), (
    f'numpy got downgraded to {numpy.__version__} by one of the install '
    'stages above -- check which stage pulled in a <2.0 pin.'
)
print(f'numpy version confirmed: {numpy.__version__}')
"

echo "Install complete."
