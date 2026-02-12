#!/bin/bash
set -e # Exit on error

# 1. Change Ubuntu sources
# https://mirrors.tuna.tsinghua.edu.cn/help/ubuntu/
# Ubuntu 24.04 uses /etc/apt/sources.list.d/ubuntu.sources
TARGET_SOURCE="/etc/apt/sources.list.d/ubuntu.sources"

# Backup the original source file
if [ ! -f "${TARGET_SOURCE}.bak" ]; then
    echo "[WSL-Mirror] Backing up original APT sources to ${TARGET_SOURCE}.bak"
    sudo cp $TARGET_SOURCE "${TARGET_SOURCE}.bak"
fi

# Use a heredoc to overwrite the file with the new DEB822 format for 24.04 (noble)
echo "[WSL-Mirror] Updating APT sources to Tsinghua mirror"
sudo tee $TARGET_SOURCE <<EOF
Types: deb
URIs: https://mirrors.tuna.tsinghua.edu.cn/ubuntu
Suites: noble noble-updates noble-backports
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

# 默认注释了源码镜像以提高 apt update 速度，如有需要可自行取消注释
# Types: deb-src
# URIs: https://mirrors.tuna.tsinghua.edu.cn/ubuntu
# Suites: noble noble-updates noble-backports
# Components: main restricted universe multiverse
# Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

# 以下安全更新软件源包含了官方源与镜像站配置，如有需要可自行修改注释切换
Types: deb
URIs: http://security.ubuntu.com/ubuntu/
Suites: noble-security
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

# Types: deb-src
# URIs: http://security.ubuntu.com/ubuntu/
# Suites: noble-security
# Components: main restricted universe multiverse
# Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

# 预发布软件源，不建议启用

# Types: deb
# URIs: https://mirrors.tuna.tsinghua.edu.cn/ubuntu
# Suites: noble-proposed
# Components: main restricted universe multiverse
# Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

# # Types: deb-src
# # URIs: https://mirrors.tuna.tsinghua.edu.cn/ubuntu
# # Suites: noble-proposed
# # Components: main restricted universe multiverse
# # Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
EOF

# 2. Update the package index files and upgrade packages
sudo apt update
sudo DEBIAN_FRONTEND=noninteractive apt -y upgrade

# 3. Python and Pip Setup
# https://learn.microsoft.com/en-us/windows/python/web-frameworks
# only upgrade python3 here
sudo apt -y upgrade python3

sudo apt -y install python3-pip

# Set Tsinghua PyPI mirror
# https://mirrors.tuna.tsinghua.edu.cn/help/pypi/
pip3 config set global.index-url https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple

sudo apt -y install python3-venv

# 4. Node.js via NVM
# https://learn.microsoft.com/en-us/windows/dev-environment/javascript/nodejs-on-wsl
sudo apt -y install curl
# https://gitee.com/mirrors/nvm
if [ ! -d "$HOME/.nvm" ]; then
    echo "[WSL-Mirror] Installing NVM"
    curl -o- https://gitee.com/mirrors/nvm/raw/master/install.sh | bash
fi

export NVM_NODEJS_ORG_MIRROR=https://npmmirror.com/mirrors/node

# Load NVM for current session
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# https://github.com/nvm-sh/nvm?tab=readme-ov-file#install--update-script
# https://askubuntu.com/a/969923
# Write activation script to ~/.bashrc to auto-start nvm
if ! grep -q "NVM_DIR" ~/.bashrc; then
    echo "[WSL-Mirror] Adding NVM to ~/.bashrc"

    echo -e "\nexport NVM_NODEJS_ORG_MIRROR=https://npmmirror.com/mirrors/node" >> ~/.bashrc
    echo -e \
        "\nexport NVM_DIR=\"\$([ -z \"\${XDG_CONFIG_HOME-}\" ] && printf %s \"\${HOME}/.nvm\" || printf %s \"\${XDG_CONFIG_HOME}/nvm\")\"\
        \n[ -s \"\$NVM_DIR/nvm.sh\" ] && \\. \"\$NVM_DIR/nvm.sh\" # This loads nvm" \
        >> ~/.bashrc
fi

# Install Node LTS in nvm
nvm install --lts
nvm use --lts

# 5. Change NPM Registry
# https://npmmirror.com/
npm config set registry https://registry.npmmirror.com

# If you need to use GPU CUDA on WSL
# https://github.com/microsoft/WSL/issues/5663#issuecomment-760679748
#sudo ln -s /usr/lib/wsl/lib/libcuda.so.1 /usr/local/cuda/lib64/libcuda.so

echo "[WSL-Mirror] Setup Complete"
