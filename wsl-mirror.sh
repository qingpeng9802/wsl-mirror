#!/bin/bash
#
# Update APT sources and pip indexes (PyPI) to Tsinghua mirrors,
# update npm registry and node mirror to npmmirror,
# and configure Python and Node.js environments for WSL
# according to Microsoft's guide

set -euo pipefail # Exit on error

err() {
  # Red color for errors
  printf "\033[1;31m[WSL-Mirror] ERROR:\033[0m %s\n" "$*" >&2
}

log() {
  # Blue color for logs
  printf "\033[1;34m[WSL-Mirror]\033[0m %s\n" "$*"
}

# 1. Change APT sources
# https://mirrors.tuna.tsinghua.edu.cn/help/ubuntu/
# https://mirrors.tuna.tsinghua.edu.cn/help/debian/
setup_apt_mirrors() {
  # Detect OS
  if [[ -f /etc/os-release ]]; then
    # Use a subshell to avoid polluting the current shell environment
    local -r OS_ID=$(grep -oP '^ID=\K.*' /etc/os-release | tr -d '"')
    local -r CODENAME=$(grep -oP '^VERSION_CODENAME=\K.*' /etc/os-release | tr -d '"')
    
    # Fallback: If CODENAME is empty, try to parse it from the VERSION string
    # Example: VERSION="12 (bookworm)" -> extracts "bookworm"
    if [[ -z "${CODENAME}" ]]; then
        CODENAME=$(grep -oP '^VERSION=.*\(\K[^)]+' /etc/os-release)
    fi
  else
    err "Cannot detect OS type."
    return 1
  fi

  if [[ ! ("${OS_ID}" == "ubuntu" || "${OS_ID}" == "debian") ]]; then
    err "Unsupported OS: ${OS_ID}. Only Ubuntu and Debian are supported."
    return 1
  fi

  # Ubuntu 24.04 (noble) and later uses /etc/apt/sources.list.d/ubuntu.sources by default
  # Since Debian 13 (trixie) /etc/apt/sources.list.d/debian.sources is recommended
  local -r TARGET_SOURCE="/etc/apt/sources.list.d/${OS_ID}.sources"

  # Check if ubuntu.sources or debian.sources path exists
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

  # Use a heredoc to overwrite the file with the new DEB822 format
  log "Updating APT sources to Tsinghua mirror"
  
  case "${OS_ID}" in
    "ubuntu")
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
      ;;

    "debian")
      sudo tee "${TARGET_SOURCE}" > /dev/null <<EOF || { err "Failed to write to ${TARGET_SOURCE}"; return 1; }
Types: deb
URIs: http://mirrors.tuna.tsinghua.edu.cn/debian
Suites: trixie trixie-updates trixie-backports
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

# 默认注释了源码镜像以提高 apt update 速度，如有需要可自行取消注释
# Types: deb-src
# URIs: http://mirrors.tuna.tsinghua.edu.cn/debian
# Suites: trixie trixie-updates trixie-backports
# Components: main contrib non-free non-free-firmware
# Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

# 以下安全更新软件源包含了官方源与镜像站配置，如有需要可自行修改注释切换
Types: deb
URIs: https://security.debian.org/debian-security
Suites: trixie-security
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

# Types: deb-src
# URIs: https://security.debian.org/debian-security
# Suites: trixie-security
# Components: main contrib non-free non-free-firmware
# Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF
      ;;

    *) err "Unsupported OS for mirror setup"; return 1 ;;
  esac

  sudo sed -E -i "s/(noble|trixie)/${CODENAME}/g" "${TARGET_SOURCE}"
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

  # In case user uses UV
  log "Setting UV_DEFAULT_INDEX"
  export UV_DEFAULT_INDEX="https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple"
  if ! grep -q "UV_DEFAULT_INDEX" "${HOME}/.bashrc"; then
    cat << 'EOF' >> ~/.bashrc

export UV_DEFAULT_INDEX="https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple"
EOF
  fi
}

# 4. Node.js via NVM
# https://learn.microsoft.com/en-us/windows/dev-environment/javascript/nodejs-on-wsl
setup_node_nvm_and_npm_registry() {
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
    curl -fsSL --proto '=https' --tlsv1.3 https://gitee.com/mirrors/nvm/raw/master/install.sh | bash || {
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

  # Change NPM Registry
  # https://npmmirror.com/
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
    err "${LIB_PATH} not found, check your NVIDIA driver installation on Windows"
    return 1
  fi

  sudo mkdir -p "${TARGET_DIR}"

  # If it is already a link, check if it is correct
  if [[ -L "${TARGET_PATH}" ]]; then
    if [[ "$(readlink -f "${TARGET_PATH}")" == "${LIB_PATH}" ]]; then
      log "CUDA symlink already exists. Skip creating symlink"
      return 0
    else
      err "Existing link points elsewhere. Skip creating symlink"
      return 1
    fi
  # If it is a real file, do not touch it
  elif [[ -e "${TARGET_PATH}" ]]; then
    err "${TARGET_PATH} is a real file. Skip creating symlink"
    return 1
  fi

  # sudo ln -s /usr/lib/wsl/lib/libcuda.so.1 /usr/local/cuda/lib64/libcuda.so
  sudo ln -sn "${LIB_PATH}" "${TARGET_PATH}" || {
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
        printf "Usage: %s [--cuda]\n" "$0"
        printf "  -c, --cuda    Create a CUDA symlink\n"
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
  setup_node_nvm_and_npm_registry

  if [[ "$enable_cuda" = true ]]; then
    set_cuda
  else
    log "If you need to create a CUDA symlink, use -c option"
  fi

  log "Setup Complete"
}

# Invoke the main function
if [[ "${BASH_SOURCE[0]:-$0}" == "${0}" ]]; then
    main "$@"
fi
