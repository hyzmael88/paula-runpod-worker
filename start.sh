#!/usr/bin/env bash
# Paula Worker startup: per-file symlinks + ComfyUI + handler

echo ">>> [Paula Worker] Iniciando..."
START=$(date +%s)

# === 1) Custom nodes (folder-level: base no los tiene) ===
for SRC in "/runpod-volume/ComfyUI/custom_nodes" "/workspace/ComfyUI/custom_nodes"; do
  if [ -d "$SRC" ]; then
    echo ">>> [Paula] custom_nodes desde $SRC"
    for dir in "$SRC"/*/; do
      [ -d "$dir" ] || continue
      name=$(basename "$dir")
      target="/comfyui/custom_nodes/$name"
      if [ ! -e "$target" ]; then
        ln -s "$dir" "$target"
      fi
    done
    break
  fi
done

# === 2) Models PER-FILE (dirs ya existen en el base image) ===
for SRC in "/runpod-volume/ComfyUI/models" "/workspace/ComfyUI/models"; do
  if [ -d "$SRC" ]; then
    echo ">>> [Paula] models desde $SRC"
    for subdir in "$SRC"/*/; do
      [ -d "$subdir" ] || continue
      name=$(basename "$subdir")
      target_dir="/comfyui/models/$name"
      mkdir -p "$target_dir"
      for f in "$subdir"*; do
        [ -e "$f" ] || continue
        fname=$(basename "$f")
        ln -sfn "$f" "$target_dir/$fname"
      done
      count=$(ls -1 "$subdir" 2>/dev/null | wc -l)
      echo "   + models/$name: $count archivos"
    done
    break
  fi
done

ELAPSED=$(($(date +%s) - START))
echo ">>> [Paula] symlinks listos en ${ELAPSED}s."

# === 3) Bloque base start.sh ===
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
