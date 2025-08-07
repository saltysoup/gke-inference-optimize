FROM python:3.12-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update -y && apt upgrade -y && \
    apt install -y --no-install-recommends \
    git \
    gcc-12 \
    g++-12 \
    libnuma-dev && \
    #python3.12-venv && \
    # Clean up apt cache to keep the layer small
    rm -rf /var/lib/apt/lists/*

# Set gcc-12 as the default compiler
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-12 10 --slave /usr/bin/g++ g++ /usr/bin/g++-12

# Clone the vLLM repository
WORKDIR /vllm
RUN git clone https://github.com/vllm-project/vllm.git .

#RUN python3 -m venv vllm_env
#RUN . vllm_env/bin/activate

RUN pip install --upgrade pip && \
    pip install "cmake>=3.26" wheel packaging ninja "setuptools-scm>=8" numpy datasets && \
    pip install -v -r requirements/cpu.txt --extra-index-url https://download.pytorch.org/whl/cpu && \
    VLLM_TARGET_DEVICE=cpu python setup.py install

