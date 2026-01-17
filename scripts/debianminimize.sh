#!/bin/bash

# Debian系统精简脚本
# 一键下载并执行远程脚本，精简系统到最小化安装

set -euo pipefail

# 配置变量
SCRIPT_NAME="Debian最小化工具"
GITHUB_URL="https://github.com/GamblerIX/DebianTools/raw/main/remote/minimizedebian.sh"
GITEE_URL="https://gitee.com/GamblerIX/DebianTools/raw/main/remote/minimizedebian.sh"
LOG_FILE="/var/log/debianminimize.log"
BACKUP_DIR="/root/debianminimize-backup"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 日志函数
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[错误]${NC} $1" | tee -a "$LOG_FILE"
    exit 1
}

warning() {
    echo -e "${YELLOW}[警告]${NC} $1" | tee -a "$LOG_FILE"
}

# 检查权限
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "此脚本需要root权限运行。请使用 sudo 或以root用户执行。"
    fi
}

# 检查系统
check_system() {
    if ! command -v apt &> /dev/null; then
        error "此脚本仅支持基于APT的系统（如Debian/Ubuntu）"
    fi
    
    if ! grep -q "debian" /etc/os-release 2>/dev/null; then
        warning "检测到非Debian系统，继续执行可能存在风险"
        read -p "是否继续？(y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# 创建备份
create_backup() {
    log "创建系统配置备份..."
    mkdir -p "$BACKUP_DIR"
    
    # 备份重要配置文件
    cp /etc/apt/sources.list "$BACKUP_DIR/" 2>/dev/null || true
    cp -r /etc/apt/sources.list.d "$BACKUP_DIR/" 2>/dev/null || true
    dpkg --get-selections > "$BACKUP_DIR/installed-packages.txt"
    
    log "备份已保存到: $BACKUP_DIR"
}

# 测试下载速度并选择最快源
select_fastest_source() {
    log "测试下载源速度..."
    
    # 简单测试：先尝试Gitee（国内网络通常更快），如果失败再用GitHub
    if curl -o /dev/null -s --connect-timeout 3 --max-time 5 "$GITEE_URL" 2>/dev/null; then
        log "选择Gitee源（国内网络优化）"
        echo "$GITEE_URL"
    elif curl -o /dev/null -s --connect-timeout 3 --max-time 5 "$GITHUB_URL" 2>/dev/null; then
        log "选择GitHub源（Gitee不可达）"
        echo "$GITHUB_URL"
    else
        warning "两个源都无法访问，默认使用Gitee源"
        echo "$GITEE_URL"
    fi
}

# 下载远程脚本
download_remote_script() {
    local temp_script="/tmp/minimizedebianremote.sh"
    local remote_url
    
    remote_url=$(select_fastest_source)
    log "正在从最快源下载精简脚本: $remote_url"
    
    if command -v curl &> /dev/null; then
        curl -fsSL "$remote_url" -o "$temp_script"
    elif command -v wget &> /dev/null; then
        wget -q "$remote_url" -O "$temp_script"
    else
        error "需要curl或wget来下载远程脚本"
    fi
    
    # 验证脚本
    if [[ ! -f "$temp_script" ]] || [[ ! -s "$temp_script" ]]; then
        error "远程脚本下载失败或为空"
    fi
    
    chmod +x "$temp_script"
    echo "$temp_script"
}

# 执行精简操作
execute_minimize() {
    local remote_script="$1"
    
    log "开始执行系统精简..."
    
    # 显示即将执行的脚本内容（前20行）
    echo "即将执行的脚本预览："
    head -20 "$remote_script"
    echo "..."
    
    read -p "确认执行精简操作？此操作不可逆！(y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "用户取消操作"
        exit 0
    fi
    
    # 执行远程脚本
    bash "$remote_script" 2>&1 | tee -a "$LOG_FILE"
    
    # 清理临时文件
    rm -f "$remote_script"
}

# 主函数
main() {
    echo "========================================"
    echo "       $SCRIPT_NAME"
    echo "========================================"
    echo
    
    check_root
    check_system
    create_backup
    
    local remote_script
    remote_script=$(download_remote_script)
    
    execute_minimize "$remote_script"
    
    log "系统精简完成！"
    log "日志文件: $LOG_FILE"
    log "备份目录: $BACKUP_DIR"
    
    echo
    echo "建议重启系统以确保所有更改生效："
    echo "sudo reboot"
}

# 脚本入口
if [[ "${BASH_SOURCE[0]:-$0}" == "${0}" ]]; then
    main "$@"
fi