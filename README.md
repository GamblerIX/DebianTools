# DebianTools

一键式Debian系统精简与升级工具集

## 功能特性

### 🔧 系统精简工具
- 自动测试GitHub和Gitee下载速度，选择最快源
- 彻底精简到服务器命令行必需包
- 移除所有图形界面、开发工具、文档系统
- 只保留SSH、网络工具、系统监控等核心功能
- 无头模式运行，适合生产服务器

### 🚀 系统升级工具  
- 自动检测当前Debian版本
- 升级到最新稳定版本
- 安全的升级流程
- 备份重要配置

## 🚀 一键使用

### 系统精简（远程执行）
```bash
# GitHub源（国外网络推荐）
curl -fsSL https://github.com/GamblerIX/DebianTools/raw/main/scripts/debianminimize.sh | bash
wget -qO- https://github.com/GamblerIX/DebianTools/raw/main/scripts/debianminimize.sh | bash

# Gitee源（国内网络推荐）
curl -fsSL https://gitee.com/GamblerIX/DebianTools/raw/main/scripts/debianminimize.sh | bash
wget -qO- https://gitee.com/GamblerIX/DebianTools/raw/main/scripts/debianminimize.sh | bash
```

### 系统升级（远程执行）
```bash
# GitHub源（国外网络推荐）
curl -fsSL https://github.com/GamblerIX/DebianTools/raw/main/scripts/debianupgrade.sh | bash
wget -qO- https://github.com/GamblerIX/DebianTools/raw/main/scripts/debianupgrade.sh | bash

# Gitee源（国内网络推荐）
curl -fsSL https://gitee.com/GamblerIX/DebianTools/raw/main/scripts/debianupgrade.sh | bash
wget -qO- https://gitee.com/GamblerIX/DebianTools/raw/main/scripts/debianupgrade.sh | bash
```

### 系统分析（本地执行）
```bash
# GitHub源
git clone https://github.com/GamblerIX/DebianTools.git

# Gitee源（国内网络推荐）
git clone https://gitee.com/GamblerIX/DebianTools.git

cd DebianTools
bash install.sh
./utils/packageanalyzer.sh
```

## 特性说明

### 🌐 一键远程执行
- 无需下载整个项目，直接执行远程脚本
- 支持curl和wget两种方式
- 自动选择最快的下载源（GitHub/Gitee）

### 智能源选择
- 自动测试GitHub和Gitee的连接速度
- 选择最快的下载源，提升脚本下载效率
- 支持国内外网络环境自适应

### 极致精简
- 只保留服务器命令行运行必需的包
- 移除所有图形界面组件（X11、桌面环境等）
- 清理开发工具、文档系统、多媒体组件
- 保留SSH、网络工具、系统监控等核心功能

### 安全升级
- 支持从Debian 9逐步升级到最新版本
- 自动备份重要配置文件
- 验证升级完整性

## 📋 使用场景

### 生产服务器精简
```bash
# GitHub源（国外网络推荐）
curl -fsSL https://github.com/GamblerIX/DebianTools/raw/main/scripts/debianminimize.sh | bash

# Gitee源（国内网络推荐）
curl -fsSL https://gitee.com/GamblerIX/DebianTools/raw/main/scripts/debianminimize.sh | bash
```

### 系统版本升级
```bash
# GitHub源（国外网络推荐）
curl -fsSL https://github.com/GamblerIX/DebianTools/raw/main/scripts/debianupgrade.sh | bash

# Gitee源（国内网络推荐）
curl -fsSL https://gitee.com/GamblerIX/DebianTools/raw/main/scripts/debianupgrade.sh | bash
```

### 系统状态分析
```bash
# GitHub源
git clone https://github.com/GamblerIX/DebianTools.git

# Gitee源（国内网络推荐）
git clone https://gitee.com/GamblerIX/DebianTools.git

cd DebianTools && bash install.sh
./utils/packageanalyzer.sh
```

## ⚠️ 注意事项

- 运行前请备份重要数据
- 建议在测试环境中先行验证
- 精简操作不可逆，请谨慎使用

## 系统要求

- Debian 9+ (Stretch或更新版本)
- Root权限或sudo访问
- 网络连接
- curl或wget工具

## 许可证

MIT License