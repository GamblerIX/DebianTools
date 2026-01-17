# DebianTools 2.0

现代化的Debian系统管理工具 - 单文件bash脚本实现

## 简介

DebianTools是一个强大而简单的Debian系统无头管理工具，采用单文件bash脚本实现，无需安装依赖，开箱即用。

## 快速开始

### 下载和使用

```bash
# 从GitHub下载
wget https://github.com/GamblerIX/DebianTools/raw/main/debiantools.sh
```

```bash
# 或从Gitee下载（国内推荐）
wget https://gitee.com/GamblerIX/DebianTools/raw/main/debiantools.sh
```

```bash
# 添加可执行权限
chmod +x debiantools.sh

# 运行
./debiantools.sh --help
```

### 基本命令

```bash
# 分析系统
./debiantools.sh --analyze
```

```bash
# 升级系统（需要root权限）
./debiantools.sh --upgrade
```

```bash
# 精简系统（需要root权限）
./debiantools.sh --minimize
```


## 系统要求

- Debian 9+ 或基于Debian的发行版（Ubuntu, Linux Mint等）
- Bash 4.0+
- 标准Debian工具（apt, dpkg等）
