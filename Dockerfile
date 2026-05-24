FROM runpod/worker-comfyui:5.8.5-base

# Pre-instalar dependencies de TODOS los custom nodes del network volume.
# Esto evita que ComfyUI las instale al arrancar (lo cual es muy lento).
RUN pip install --no-cache-dir \
    insightface \
    onnxruntime-gpu \
    opencv-python-headless \
    protobuf \
    color-matcher \
    matplotlib \
    pillow \
    scipy \
    scikit-image \
    scikit-learn \
    numpy \
    transformers \
    accelerate \
    safetensors \
    sentencepiece \
    spandrel \
    rembg \
    aiohttp \
    requests \
    tqdm \
    huggingface-hub \
    onnx \
    GitPython \
    PyGithub \
    matrix-client==0.4.0 \
    transparent-background

# Script de arranque: usa SYMLINKS al network volume (instantáneo)
COPY start.sh /start.sh
RUN chmod +x /start.sh

CMD ["/start.sh"]
