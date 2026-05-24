#!/bin/bash
set -e

echo ">>> [Paula Worker] Iniciando..."
START=$(date +%s)

# Symlink custom nodes del network volume (instantáneo, no copia archivos)
for SRC in "/runpod-volume/ComfyUI/custom_nodes" "/workspace/ComfyUI/custom_nodes"; do
  if [ -d "$SRC" ]; then
    echo ">>> [Paula Worker] Enlazando custom nodes desde $SRC"
    for dir in "$SRC"/*/; do
      [ -d "$dir" ] || continue
      name=$(basename "$dir")
      target="/comfyui/custom_nodes/$name"
      if [ ! -e "$target" ]; then
        ln -s "$dir" "$target"
        echo "    + $name"
      fi
    done
    break
  fi
done

# Symlink models del network volume si existen
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
echo ">>> [Paula Worker] Setup en ${ELAPSED}s. Iniciando handler..."

exec python -u /handler.py
