# Windows Subsystem for Linux (WSL) 换镜像源 Script

这个 script 主要针对初始状态的 WSL 来完成 apt、pip 和 npm 的一站式镜像源更换，特别适合不佳的网络环境.  
apt 和 pip 使用清华源 [ubuntu](https://mirrors.tuna.tsinghua.edu.cn/help/ubuntu/) | [pypi](https://mirrors.tuna.tsinghua.edu.cn/help/pypi/)，npm 和 node 使用[阿里源](https://npmmirror.com/).  

同时，对于 WSL 第一次安装 Python、pip、Node.js 和 npm 的方式，遵循微软的最佳实践指引，即 [python](https://learn.microsoft.com/en-us/windows/python/web-frameworks) 和 [Node.js](https://learn.microsoft.com/en-us/windows/dev-environment/javascript/nodejs-on-wsl).
  
shell 命令都包含详细注释，强烈推荐使用前阅读. 
请注意，如果 WSL 不是在初始状态，即已被修改和使用过，该 script 可能会造成文件的意外修改，特别注意 `/etc/apt/sources.list.d/ubuntu.sources` 和 `~/.bashrc`.

## 使用方式
```shell
bash wsl-mirror.sh
```
