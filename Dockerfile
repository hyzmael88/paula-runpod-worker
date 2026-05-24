FROM runpod/worker-comfyui:5.8.5-base

# 1) Pre-instalar dependencies para ReActor y otros custom nodes comunes
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

# 2) Clonar ReActor custom node DIRECTAMENTE en la imagen para que
#    siempre esté disponible (no depende de symlinks del network volume)
RUN cd /comfyui/custom_nodes && \
    git clone --depth 1 https://github.com/Gourieff/ComfyUI-ReActor.git comfyui-reactor-node && \
    cd comfyui-reactor-node && \
    pip install --no-cache-dir -r requirements.txt || true

# 3) Script de arranque: GPU check + ComfyUI + handler + symlinks
COPY start.sh /start.sh
RUN chmod +x /start.sh

CMD ["/start.sh"]
