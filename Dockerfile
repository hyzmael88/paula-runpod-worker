FROM runpod/worker-comfyui:5.8.5-base

# Dependencias de ReActorFaceSwap (se instalan una vez en la imagen)
RUN pip install --no-cache-dir \
    insightface \
    onnxruntime-gpu \
    opencv-python-headless \
    protobuf

# Script de arranque: copia los custom nodes del network volume al worker
COPY start.sh /start.sh
RUN chmod +x /start.sh

CMD ["/start.sh"]

