FROM runpod/worker-comfyui:5.8.5-base

# 1) Pre-instalar TODAS las deps de ReActor + custom nodes comunes
#    OJO: albumentations, segment_anything, ultralytics SON requirements
#    de ReActor; sin ellas el __init__.py falla y ComfyUI no registra
#    "ReActorFaceSwap".
RUN pip install --no-cache-dir \
    albumentations \
    segment_anything \
    ultralytics \
    insightface \
    onnxruntime-gpu \
    opencv-python \
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

# 2) Clonar ReActor + correr install.py (descarga inswapper_128.onnx)
RUN cd /comfyui/custom_nodes && \
    git clone --depth 1 https://github.com/Gourieff/ComfyUI-ReActor.git && \
    cd ComfyUI-ReActor && \
    pip install --no-cache-dir -r requirements.txt && \
    python install.py || echo "install.py warning ignored"

# 3) Script de arranque
COPY start.sh /start.sh
RUN chmod +x /start.sh

CMD ["/start.sh"]
