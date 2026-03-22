#!/bin/bash
#
# Update APT sources and pip indexes (PyPI) to Tsinghua mirrors,
# update npm registry and node mirror to npmmirror,
# and configure Python and Node.js environments for WSL
# according to Microsoft's guide

set -euo pipefail # Exit on error

err() {
  # red color
  echo -e "\033[1;31m[WSL-Mirror] ERROR:\033[0m $*" >&2
}

log() {
  # blue color
  echo -e "\033[1;34m[WSL-Mirror]\033[0m $*"
}

# 1. Change Ubuntu sources
# https://mirrors.tuna.tsinghua.edu.cn/help/ubuntu/
setup_apt_mirrors() {
  # Ubuntu 24.04 and later uses /etc/apt/sources.list.d/ubuntu.sources
  local -r TARGET_SOURCE="/etc/apt/sources.list.d/ubuntu.sources"

  # Check if ubuntu.sources path exists
  if [[ ! -f "${TARGET_SOURCE}" ]]; then
    err "File ${TARGET_SOURCE} not found"
    return 1
  fi

  # Backup the original source file
  if [[ ! -f "${TARGET_SOURCE}.bak" ]]; then
    log "Backing up original APT sources to ${TARGET_SOURCE}.bak"
    sudo cp "${TARGET_SOURCE}" "${TARGET_SOURCE}.bak" || {
      err "Failed to create backup of ${TARGET_SOURCE} by cp command"
      return 1
    }
  fi

  log "Updating APT sources to Tsinghua mirror"
  # Use a heredoc to overwrite the file with the new DEB822 format
  sudo tee "${TARGET_SOURCE}" > /dev/null <<EOF || { err "Failed to write to ${TARGET_SOURCE}"; return 1; }
Types: deb
URIs: http://mirrors.tuna.tsinghua.edu.cn/ubuntu
Suites: noble noble-updates noble-backports
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

# 默认注释了源码镜像以提高 apt update 速度，如有需要可自行取消注释
# Types: deb-src
# URIs: http://mirrors.tuna.tsinghua.edu.cn/ubuntu
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
# URIs: http://mirrors.tuna.tsinghua.edu.cn/ubuntu
# Suites: noble-proposed
# Components: main restricted universe multiverse
# Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

# # Types: deb-src
# # URIs: http://mirrors.tuna.tsinghua.edu.cn/ubuntu
# # Suites: noble-proposed
# # Components: main restricted universe multiverse
# # Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
EOF
}

# 2. Update the package index files and upgrade packages
update_and_upgrade() {
  log "Updating package index"
  sudo apt update || {
    err "APT update failed"
    return 1
  }

  log "Upgrading packages"
  sudo DEBIAN_FRONTEND=noninteractive apt -y upgrade || {
    err "APT upgrade failed"
    return 1
  }
}

# 3. Python and Pip Setup
# https://learn.microsoft.com/en-us/windows/python/web-frameworks
setup_python_pip() {
  # only upgrade python3 here
  log "Setting up Python, pip and venv"
  sudo apt -y upgrade python3 || {
    err "python3 upgrade failed"
    return 1
  }

  sudo apt -y install python3-pip python3-venv || {
    err "Failed to install python3-pip python3-venv"
    return 1
  }

  # Set Tsinghua PyPI mirror
  # https://mirrors.tuna.tsinghua.edu.cn/help/pypi/
  if command -v pip3 &> /dev/null; then
    log "Setting PyPI to Tsinghua mirror"
    pip3 config set global.index-url \
      https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple || {
      err "Failed to set PyPI to Tsinghua mirror globally"
      return 1
    }
  else
    err "pip3 not found after installation. Skipping PyPI config."
  fi
}

# 4. Node.js via NVM
# https://learn.microsoft.com/en-us/windows/dev-environment/javascript/nodejs-on-wsl
setup_node_nvm() {
  if ! command -v curl &> /dev/null; then
    sudo apt -y install curl || {
      err "Failed to install curl"
      return 1
    }
  fi

  set +u
  # https://gitee.com/mirrors/nvm
  if [[ ! -d "${HOME}/.nvm" ]]; then
    log "Installing NVM"
    curl -fsSL https://gitee.com/mirrors/nvm/raw/master/install.sh | bash || {
      err "NVM download or installation script failed"
      return 1
    }
  fi

  # Load NVM for current session
  export NVM_DIR="$HOME/.nvm"
  # shellcheck disable=SC1091
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
  # shellcheck disable=SC1091
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

  # https://github.com/nvm-sh/nvm?tab=readme-ov-file#install--update-script
  # https://askubuntu.com/a/969923
  # Write activation script to ~/.bashrc to auto-start nvm
  if ! grep -q "NVM_DIR" "${HOME}/.bashrc"; then
    log "Adding NVM to ~/.bashrc"
    cat << 'EOF' >> ~/.bashrc

# NVM Configuration
export NVM_NODEJS_ORG_MIRROR=https://npmmirror.com/mirrors/node
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
EOF
  fi

  # Install Node LTS in nvm
  log "Installing Node.js LTS via nvm"
  if ! command -v nvm &> /dev/null; then
    err "nvm is not loaded in the current shell"
    return 1
  fi

  export NVM_NODEJS_ORG_MIRROR=https://npmmirror.com/mirrors/node
  nvm install --lts || {
    err "Failed to install Node.js via nvm"
    return 1
  }

  log "Using Node.js LTS"
  nvm use --lts || {
    err "Failed to use Node LTS via nvm"
    return 1
  }
  set -u
}

# 5. Change NPM Registry
# https://npmmirror.com/
set_npm_registry() {
  log "Setting NPM Registry to npmmirror"
  npm config set registry https://registry.npmmirror.com || {
    err "Failed to set NPM registry to npmmirror"
    return 1
  }
}

# If you need to use GPU CUDA on WSL
# https://github.com/microsoft/WSL/issues/5663#issuecomment-760679748
set_cuda() {
  local -r LIB_PATH="/usr/lib/wsl/lib/libcuda.so.1"
  local -r TARGET_DIR="/usr/local/cuda/lib64"
  local -r TARGET_PATH="${TARGET_DIR}/libcuda.so"

  log "Creating symlink for CUDA"

  if [[ ! -f "${LIB_PATH}" ]]; then
    err "${LIB_PATH} not found, check your driver"
    return 1
  fi

  # sudo ln -s /usr/lib/wsl/lib/libcuda.so.1 /usr/local/cuda/lib64/libcuda.so
  sudo mkdir -p "${TARGET_DIR}"
  sudo ln -sf "${LIB_PATH}" "${TARGET_PATH}" || {
    err "Failed to create symlink"
    return 1
  }

  if ! [[ -L "${TARGET_PATH}" && -e "${TARGET_PATH}" ]]; then
    err "Failed to create symlink"
    return 1
  fi
}

main() {
  local enable_cuda=false

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -c|--cuda)
        enable_cuda=true
        shift
        ;;
      -h|--help)
        echo "Usage: $0 [--cuda]"
        echo "  -c, --cuda    Create a CUDA symlink"
        exit 0
        ;;
      *)
        shift # Skip unknown options
        ;;
    esac
  done

  setup_apt_mirrors
  update_and_upgrade
  setup_python_pip
  setup_node_nvm
  set_npm_registry

  if [[ "$enable_cuda" = true ]]; then
    set_cuda
  else
    log "If you need to create a CUDA symlink, use -c option"
  fi

  log "Setup Complete"
}

# Invoke the main function
main "$@"
