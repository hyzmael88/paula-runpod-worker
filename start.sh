#!/usr/bin/env bash
# Paula Worker startup: symlinks + ComfyUI + handler

echo ">>> [Paula Worker] Iniciando..."
START=$(date +%s)

# === 1) SYMLINKS desde el network volume hacia /comfyui ===
for SRC in "/runpod-volume/ComfyUI/custom_nodes" "/workspace/ComfyUI/custom_nodes"; do
  if [ -d "$SRC" ]; then
    echo ">>> [Paula Worker] Enlazando custom nodes desde $SRC"
    for dir in "$SRC"/*/; do
      [ -d "$dir" ] || continue
      name=$(basename "$dir")
      target="/comfyui/custom_nodes/$name"
      if [ ! -e "$target" ]; then
        ln -s "$dir" "$target"
        echo " + $name"
      fi
    done
    break
  fi
done

for SRC in "/runpod-volume/ComfyUI/models" "/workspace/ComfyUI/models"; do
  if [ -d "$SRC" ]; then
    echo ">>> [Paula Worker] Enlazando models desde $SRC"
    for dir in "$SRC"/*/; do
      [ -d "$dir" ] || continue
      name=$(basename "$dir")
      target="/comfyui/models/$name"
      if [ ! -e "$target" ] && [ ! -L "$target" ]; then
        ln -s "$dir" "$target"
      fi
    done
    break
  fi
done

ELAPSED=$(($(date +%s) - START))
echo ">>> [Paula Worker] Symlinks listos en ${ELAPSED}s."

# === 2) Bloque del start.sh base de runpod/worker-comfyui ===

# tcmalloc para mejor manejo de memoria
TCMALLOC="$(ldconfig -p | grep -Po "libtcmalloc.so.\d" | head -n 1)"
export LD_PRELOAD="${TCMALLOC}"

# GPU pre-flight
echo "worker-comfyui: Checking GPU availability..."
if ! GPU_CHECK=$(python3 -c "
import torch
try:
    torch.cuda.init()
    name = torch.cuda.get_device_name(0)
    print(f'OK: {name}')
except Exception as e:
    print(f'FAIL: {e}')
    exit(1)
" 2>&1); then
  echo "worker-comfyui: GPU is not available. $GPU_CHECK"
  exit 1
fi
echo "worker-comfyui: GPU available - $GPU_CHECK"

# ComfyUI-Manager en modo offline (no bloquea por updates)
comfy-manager-set-mode offline || echo "worker-comfyui - Could not set ComfyUI-Manager network_mode" >&2

echo "worker-comfyui: Starting ComfyUI"

: "${COMFY_LOG_LEVEL:=DEBUG}"
COMFY_PID_FILE="/tmp/comfyui.pid"

python -u /comfyui/main.py --disable-auto-launch --disable-metadata --verbose "${COMFY_LOG_LEVEL}" --log-stdout &
echo $! > "$COMFY_PID_FILE"

echo "worker-comfyui: Starting RunPod Handler"
exec python -u /handler.py
