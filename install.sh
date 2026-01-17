#!/bin/bash

# 安装脚本 - 设置执行权限和环境

set -euo pipefail

echo "正在设置Debian管理工具..."

# 设置脚本执行权限
chmod +x scripts/*.sh
chmod +x utils/*.sh
chmod +x remote/*.sh

# 创建符号链接到系统路径（可选）
if [[ $EUID -eq 0 ]]; then
    echo "创建系统链接..."
    ln -sf "$(pwd)/scripts/debianminimize.sh" /usr/local/bin/debianminimize
    ln -sf "$(pwd)/scripts/debianupgrade.sh" /usr/local/bin/debianupgrade
    ln -sf "$(pwd)/utils/systeminfo.sh" /usr/local/bin/systeminfo
    echo "✅ 系统链接已创建"
else
    echo "ℹ️  以root权限运行可创建系统链接"
fi

echo "✅ 安装完成！"
echo
echo "使用方法："
echo "  系统精简: ./scripts/debianminimize.sh"
echo "  系统升级: ./scripts/debianupgrade.sh"  
echo "  系统信息: ./utils/systeminfo.sh"