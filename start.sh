#!/usr/bin/env bash
# Paula Worker startup: per-file symlinks + ComfyUI + handler

echo ">>> [Paula Worker] Iniciando..."
START=$(date +%s)

# Network volume real path es runpod-slim/ComfyUI (descubierto SSH al pod)
COMFY_VOL_BASE=""
for CAND in \
    "/runpod-volume/runpod-slim/ComfyUI" \
    "/runpod-volume/ComfyUI" \
    "/workspace/runpod-slim/ComfyUI" \
    "/workspace/ComfyUI"; do
  if [ -d "$CAND/models" ]; then
    COMFY_VOL_BASE="$CAND"
    echo ">>> [Paula] Volume ComfyUI detectado en: $COMFY_VOL_BASE"
    break
  fi
done

if [ -z "$COMFY_VOL_BASE" ]; then
  echo ">>> [Paula] WARN: no se encontró ComfyUI/models en el volume"
fi

# === 1) Custom nodes (folder-level) ===
if [ -d "$COMFY_VOL_BASE/custom_nodes" ]; then
  echo ">>> [Paula] custom_nodes desde $COMFY_VOL_BASE/custom_nodes"
  for dir in "$COMFY_VOL_BASE/custom_nodes"/*/; do
    [ -d "$dir" ] || continue
    name=$(basename "$dir")
    target="/comfyui/custom_nodes/$name"
    if [ ! -e "$target" ]; then
      ln -s "$dir" "$target"
    fi
  done
fi

# === 2) Models PER-FILE (dirs ya existen en el base image) ===
if [ -d "$COMFY_VOL_BASE/models" ]; then
  echo ">>> [Paula] models desde $COMFY_VOL_BASE/models"
  for subdir in "$COMFY_VOL_BASE/models"/*/; do
    [ -d "$subdir" ] || continue
    name=$(basename "$subdir")
    target_dir="/comfyui/models/$name"
    mkdir -p "$target_dir"
    cnt=0
    for f in "$subdir"*; do
      [ -e "$f" ] || continue
      fname=$(basename "$f")
      ln -sfn "$f" "$target_dir/$fname"
      cnt=$((cnt+1))
    done
    echo "   + models/$name: $cnt archivos"
  done
fi

ELAPSED=$(($(date +%s) - START))
echo ">>> [Paula] symlinks listos en ${ELAPSED}s."

# === 3) Bloque base start.sh de runpod/worker-comfyui ===
TCMALLOC="$(ldconfig -p | grep -Po "libtcmalloc.so.\d" | head -n 1)"
export LD_PRELOAD="${TCMALLOC}"

echo "worker-comfyui: GPU check..."
if ! GPU_CHECK=$(python3 -c "
import torch
try:
    torch.cuda.init()
    print(f'OK: {torch.cuda.get_device_name(0)}')
except Exception as e:
    print(f'FAIL: {e}')
    exit(1)
" 2>&1); then
  echo "worker-comfyui: GPU not available. $GPU_CHECK"
  exit 1
fi
echo "worker-comfyui: $GPU_CHECK"

comfy-manager-set-mode offline 2>/dev/null || true

echo "worker-comfyui: Starting ComfyUI"
: "${COMFY_LOG_LEVEL:=DEBUG}"
COMFY_PID_FILE="/tmp/comfyui.pid"

python -u /comfyui/main.py --disable-auto-launch --disable-metadata --verbose "${COMFY_LOG_LEVEL}" --log-stdout &
echo $! > "$COMFY_PID_FILE"

echo "worker-comfyui: Starting RunPod Handler"
exec python -u /handler.py
