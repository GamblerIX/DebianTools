# DebianTools

现代化的Debian系统管理工具 - 单文件bash脚本实现

## 简介

DebianTools是一个强大而简单的Debian系统无头管理工具，采用单文件bash脚本实现，无需安装依赖，开箱即用。

## 快速开始

### 一键远程执行

```bash
# 从GitHub远程执行 - 查看帮助
bash <(curl -fsSL https://raw.githubusercontent.com/GamblerIX/DebianTools/main/debiantools.sh) --help
```

```bash
# 从Gitee远程执行 - 查看帮助
bash <(curl -fsSL https://gitee.com/GamblerIX/DebianTools/raw/main/debiantools.sh) --help
```

### 常用命令

```bash
# 一键升级系统
bash <(curl -fsSL https://raw.githubusercontent.com/GamblerIX/DebianTools/main/debiantools.sh) --upgrade
```

```bash
# 一键精简系统
bash <(curl -fsSL https://raw.githubusercontent.com/GamblerIX/DebianTools/main/debiantools.sh) --minimize
```

```bash
# 安装到系统 (安装后可用 DBT 命令)
bash <(curl -fsSL https://raw.githubusercontent.com/GamblerIX/DebianTools/main/debiantools.sh) --install
```

### 安装后使用

```bash
# 安装后可直接使用 DBT 命令
DBT --help
DBT --upgrade
DBT --minimize
DBT --uninstall
```

## 功能详情

| 命令 | 说明 |
|------|------|
| `--help, -h` | 显示帮助信息 |
| `--version, -v` | 显示版本信息 |
| `--install` | 安装到系统 (需要root权限) |
| `--uninstall` | 从系统卸载 (需要root权限) |
| `--upgrade` | 一键升级系统 (需要root权限) |
| `--minimize` | 一键精简系统 (需要root权限) |

## 系统要求

- Debian 9+ 或基于Debian的发行版（Ubuntu, Linux Mint等）
- Bash 4.0+
- 标准Debian工具（apt, dpkg等）

## 许可证

AGPL-3.0
