FROM nvidia/cuda:12.1.0-base-ubuntu22.04

RUN apt-get update -y \
    && apt-get install -y python3-pip

RUN ldconfig /usr/local/cuda-12.1/compat/

# Install Python dependencies
COPY builder/requirements.txt /requirements.txt
RUN --mount=type=cache,target=/root/.cache/pip \
    python3 -m pip install --upgrade pip && \
    python3 -m pip install --upgrade -r /requirements.txt

# Install vLLM (switching back to pip installs since issues that required building fork are fixed and space optimization is not as important since caching) and FlashInfer
RUN python3 -m pip install vllm==0.6.3.post1 && \
    python3 -m pip install flashinfer -i https://flashinfer.ai/whl/cu121/torch2.3

COPY models--Ertugrul--Pixtral-12B-Captioner-Relaxed/snapshots/768ab0dc91f78088f523167f02158877a5f0b240 /models/huggingface-cache/hub/models--Ertugrul--Pixtral-12B-Captioner-Relaxed/snapshots/768ab0dc91f78088f523167f02158877a5f0b240

# Copy your modified vLLM code from vllm-base-image/vllm
COPY vllm-base-image/vllm/vllm/ /usr/local/lib/python3.10/dist-packages/vllm/
# Setup for Option 2: Building the Image with the Model included
ARG MODEL_NAME=""
ARG TOKENIZER_NAME=""
ARG BASE_PATH="/runpod-volume"
ARG QUANTIZATION=""
ARG MODEL_REVISION=""
ARG TOKENIZER_REVISION=""

ENV MODEL_NAME=$MODEL_NAME \
    MODEL_REVISION=$MODEL_REVISION \
    TOKENIZER_NAME=$TOKENIZER_NAME \
    TOKENIZER_REVISION=$TOKENIZER_REVISION \
    BASE_PATH=$BASE_PATH \
    QUANTIZATION=$QUANTIZATION \
    HF_DATASETS_CACHE="${BASE_PATH}/huggingface-cache/datasets" \
    HUGGINGFACE_HUB_CACHE="${BASE_PATH}/huggingface-cache/hub" \
    HF_HOME="${BASE_PATH}/huggingface-cache/hub" \
    HF_HUB_ENABLE_HF_TRANSFER=0

ENV PYTHONPATH="/:/vllm-workspace"


COPY src /src
COPY builder/local_model_args.json/ /
# Start the handler
CMD ["python3", "/src/handler.py"]