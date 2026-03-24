ARG BASE_IMAGE=ubuntu:24.04
FROM ${BASE_IMAGE}

RUN apt-get update && apt-get install -y \
    sudo python3 python3-pytest && \
    rm -rf /var/lib/apt/lists/*

# MOCK CUDA: Create the directory and a dummy file that the script checks for
RUN mkdir -p /usr/lib/wsl/lib/ && \
    touch /usr/lib/wsl/lib/libcuda.so.1

# Setup user to match a standard WSL non-root experience
RUN useradd -m tester && echo "tester ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER tester
WORKDIR /home/tester

COPY --chown=tester:tester wsl-mirror.sh .
COPY --chown=tester:tester test/test.py .

RUN chmod +x wsl-mirror.sh