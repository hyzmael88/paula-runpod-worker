#!/bin/bash

echo ">>> Iniciando worker de Paula..."

# El network volume puede estar en /runpod-volume o /workspace dependiendo de la config
for SRC in "/runpod-volume/ComfyUI/custom_nodes" "/workspace/ComfyUI/custom_nodes"; do
  if [ -d "$SRC" ]; then
    echo ">>> Copiando custom nodes desde $SRC hacia /comfyui/custom_nodes/"
    for dir in "$SRC"/*/; do
      [ -d "$dir" ] || continue
      name=$(basename "$dir")
      echo "    - Copiando: $name"
      cp -rf "$dir" "/comfyui/custom_nodes/$name"
    done
    echo ">>> Custom nodes listos."
    break
  fi
done

echo ">>> Iniciando handler de RunPod..."
exec python -u /handler.py

