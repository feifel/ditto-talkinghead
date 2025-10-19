#!/usr/bin/env bash
set -euo pipefail

# Colors
RED='\033[0;31m'
GRN='\033[0;32m'
YEL='\033[1;33m'
NC='\033[0m' # No Color

log_info()  { echo -e "${GRN}[entrypoint]${NC} $*"; }
log_warn()  { echo -e "${YEL}[entrypoint]${NC} $*"; }
log_error() { echo -e "${RED}[entrypoint]${NC} $*" >&2; }

# 1) Ensure NVIDIA GPU is available
if ! command -v nvidia-smi >/dev/null 2>&1; then
  log_error "No NVIDIA driver or NVIDIA Container Toolkit detected. Did you run with '--gpus all' and install nvidia-container-toolkit on the host?"
  exit 1
fi
if ! nvidia-smi -L >/dev/null 2>&1; then
  log_error "nvidia-smi is present but no GPUs are visible. Check driver installation and docker run flags."
  exit 1
fi

# 2) Paths
APP_DIR="/app"
CHECKPOINTS_DIR="${APP_DIR}/checkpoints"
ONNX_DIR="${CHECKPOINTS_DIR}/ditto_onnx"
TRT_DIR="${CHECKPOINTS_DIR}/ditto_trt_custom"
CONVERT_SCRIPT="${APP_DIR}/ditto-talkinghead/scripts/cvt_onnx_to_trt.py"

cd "${APP_DIR}"

# 3) First-run conversion if no engines exist
mkdir -p "${TRT_DIR}"

if [ -z "$(ls -A "${TRT_DIR}" 2>/dev/null || true)" ]; then
  log_info "No TensorRT engines found in ${TRT_DIR}. Attempting conversion from ${ONNX_DIR}..."
  if [ ! -d "${ONNX_DIR}" ]; then
    log_error "ONNX directory ${ONNX_DIR} does not exist. Mount or copy your checkpoints properly."
    log_warn "If running with host mounts, use: -v \"\$(pwd)/checkpoints:${CHECKPOINTS_DIR}\""
    exit 1
  fi
  if [ ! -f "${CONVERT_SCRIPT}" ]; then
    log_error "Conversion script not found at ${CONVERT_SCRIPT}"
    exit 1
  fi

  python "${CONVERT_SCRIPT}" --onnx_dir "${ONNX_DIR}" --trt_dir "${TRT_DIR}"
  log_info "Conversion completed. Engines are in ${TRT_DIR}"
else
  log_info "TensorRT engines already present in ${TRT_DIR}. Skipping conversion."
fi

# 4) If a command is provided, execute it. Otherwise, start a shell.
if [ "$#" -gt 0 ]; then
  log_info "Executing command: $*"
  exec "$@"
else
  log_info "No command provided. Dropping into interactive shell."
  exec bash
fi
