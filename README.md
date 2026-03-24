# Windows Subsystem for Linux (WSL) 换国内镜像源 Script

这个 script 主要针对初始状态的 WSL 来完成 apt、pip 和 npm 的一站式镜像源更换，利用国内镜像源来解决网络连接问题.  

apt 和 pip 使用清华源 [ubuntu](https://mirrors.tuna.tsinghua.edu.cn/help/ubuntu/) | [debian](https://mirrors.tuna.tsinghua.edu.cn/help/debian/) | [pypi](https://mirrors.tuna.tsinghua.edu.cn/help/pypi/)，npm 和 node 使用[阿里源](https://npmmirror.com/).  
兼容 WSL 及非 WSL 下的 Ubuntu 和 Debian.  

同时，对于 WSL 第一次安装 Python、pip、Node.js 和 npm 的方式，遵循微软的最佳实践指引，即 [Python](https://learn.microsoft.com/en-us/windows/python/web-frameworks) 和 [Node.js](https://learn.microsoft.com/en-us/windows/dev-environment/javascript/nodejs-on-wsl).
  
shell 命令都包含详细注释，强烈推荐使用前阅读.  
请注意，如果 WSL 不是在初始状态，即已被修改和使用过，该 script 可能会造成文件的意外修改，特别注意 `/etc/apt/sources.list.d/ubuntu.sources` (Debian: `/etc/apt/sources.list.d/debian.sources`) 和 `~/.bashrc`.  

## 使用方式
```shell
bash wsl-mirror.sh
```
> 如果需要创建 libcuda.so symlink https://github.com/microsoft/WSL/issues/5663#issuecomment-760679748 :
```shell
bash wsl-mirror.sh -c
```
</br>

#### 单行命令（下载并运行）
选择 curl 或 wget
```shell
curl -fsSL --proto '=https' --tlsv1.3 https://raw.githubusercontent.com/qingpeng9802/wsl-mirror/285f76a/wsl-mirror.sh | bash
```
```shell
wget -qO- --https-only --secure-protocol=TLSv1_3 https://raw.githubusercontent.com/qingpeng9802/wsl-mirror/285f76a/wsl-mirror.sh | bash
```
</br>

> 如果需要创建 libcuda.so symlink https://github.com/microsoft/WSL/issues/5663#issuecomment-760679748 :
```shell
curl -fsSL --proto '=https' --tlsv1.3 https://raw.githubusercontent.com/qingpeng9802/wsl-mirror/285f76a/wsl-mirror.sh | bash -s -- -c
```
```shell
wget -qO- --https-only --secure-protocol=TLSv1_3 https://raw.githubusercontent.com/qingpeng9802/wsl-mirror/285f76a/wsl-mirror.sh | bash -s -- -c
```
#### 仅下载文件
选择 git clone, curl 或 wget 下载文件
```shell
curl -fsSLO --proto '=https' --tlsv1.3 https://raw.githubusercontent.com/qingpeng9802/wsl-mirror/285f76a/wsl-mirror.sh
```
```shell
wget -q --https-only --secure-protocol=TLSv1_3 https://raw.githubusercontent.com/qingpeng9802/wsl-mirror/285f76a/wsl-mirror.sh
```

