#!/bin/bash

# Debian系统升级脚本
# 将旧版本Debian升级到最新稳定版本

set -euo pipefail

# 配置变量
SCRIPT_NAME="Debian系统升级工具"
LOG_FILE="/var/log/debianupgrade.log"
BACKUP_DIR="/root/debianupgrade-backup"
CURRENT_CODENAME=""
TARGET_CODENAME="bookworm"  # Debian 12

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

info() {
    echo -e "${BLUE}[信息]${NC} $1" | tee -a "$LOG_FILE"
}

# 检查权限
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "此脚本需要root权限运行。请使用 sudo 或以root用户执行。"
    fi
}

# 检测当前Debian版本
detect_debian_version() {
    if [[ ! -f /etc/debian_version ]]; then
        error "未检测到Debian系统"
    fi
    
    CURRENT_CODENAME=$(lsb_release -cs 2>/dev/null || grep VERSION_CODENAME /etc/os-release | cut -d= -f2 | tr -d '"')
    
    if [[ -z "$CURRENT_CODENAME" ]]; then
        error "无法检测当前Debian版本代号"
    fi
    
    info "当前系统版本: $CURRENT_CODENAME"
    info "目标升级版本: $TARGET_CODENAME"
}

# 检查升级路径
check_upgrade_path() {
    case "$CURRENT_CODENAME" in
        "stretch")   # Debian 9
            info "检测到Debian 9 (Stretch)，将逐步升级"
            ;;
        "buster")    # Debian 10
            info "检测到Debian 10 (Buster)，将升级到Debian 12"
            ;;
        "bullseye")  # Debian 11
            info "检测到Debian 11 (Bullseye)，将升级到Debian 12"
            ;;
        "bookworm")  # Debian 12
            info "系统已是最新版本 Debian 12"
            read -p "是否继续执行系统更新？(y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 0
            fi
            ;;
        *)
            warning "未知的Debian版本: $CURRENT_CODENAME"
            read -p "是否强制继续？(y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 1
            fi
            ;;
    esac
}

# 创建备份
create_backup() {
    log "创建系统备份..."
    mkdir -p "$BACKUP_DIR"
    
    # 备份APT配置
    cp /etc/apt/sources.list "$BACKUP_DIR/sources.list.backup"
    cp -r /etc/apt/sources.list.d "$BACKUP_DIR/" 2>/dev/null || true
    
    # 备份已安装包列表
    dpkg --get-selections > "$BACKUP_DIR/installed-packages.txt"
    apt-mark showmanual > "$BACKUP_DIR/manual-packages.txt"
    
    # 备份重要配置
    tar -czf "$BACKUP_DIR/etc-backup.tar.gz" /etc 2>/dev/null || true
    
    log "备份完成: $BACKUP_DIR"
}

# 更新sources.list
update_sources_list() {
    local target_codename="$1"
    
    log "更新APT源配置到 $target_codename..."
    
    # 备份当前sources.list
    cp /etc/apt/sources.list /etc/apt/sources.list.bak
    
    # 生成新的sources.list
    cat > /etc/apt/sources.list << EOF
# Debian $target_codename 官方源
deb http://deb.debian.org/debian/ $target_codename main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian/ $target_codename main contrib non-free non-free-firmware

# 安全更新
deb http://security.debian.org/debian-security $target_codename-security main contrib non-free non-free-firmware
deb-src http://security.debian.org/debian-security $target_codename-security main contrib non-free non-free-firmware

# 更新源
deb http://deb.debian.org/debian/ $target_codename-updates main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian/ $target_codename-updates main contrib non-free non-free-firmware
EOF

    log "APT源已更新到 $target_codename"
}

# 执行升级
perform_upgrade() {
    local target_codename="$1"
    
    log "开始升级到 $target_codename..."
    
    # 更新包列表
    log "更新包列表..."
    apt update
    
    # 升级现有包
    log "升级现有包..."
    apt upgrade -y
    
    # 更新sources.list
    update_sources_list "$target_codename"
    
    # 再次更新包列表
    log "使用新源更新包列表..."
    apt update
    
    # 执行发行版升级
    log "执行发行版升级..."
    DEBIAN_FRONTEND=noninteractive apt full-upgrade -y
    
    # 清理
    log "清理不需要的包..."
    apt autoremove -y
    apt autoclean
    
    log "升级到 $target_codename 完成！"
}

# 逐步升级（针对老版本）
step_by_step_upgrade() {
    case "$CURRENT_CODENAME" in
        "stretch")
            log "执行 Stretch -> Buster -> Bullseye -> Bookworm 逐步升级"
            perform_upgrade "buster"
            perform_upgrade "bullseye"
            perform_upgrade "bookworm"
            ;;
        "buster")
            log "执行 Buster -> Bullseye -> Bookworm 升级"
            perform_upgrade "bullseye"
            perform_upgrade "bookworm"
            ;;
        "bullseye")
            log "执行 Bullseye -> Bookworm 升级"
            perform_upgrade "bookworm"
            ;;
        *)
            perform_upgrade "$TARGET_CODENAME"
            ;;
    esac
}

# 验证升级结果
verify_upgrade() {
    log "验证升级结果..."
    
    local new_version
    new_version=$(lsb_release -cs 2>/dev/null || grep VERSION_CODENAME /etc/os-release | cut -d= -f2 | tr -d '"')
    
    if [[ "$new_version" == "$TARGET_CODENAME" ]]; then
        log "✅ 升级成功！当前版本: $new_version"
    else
        warning "升级可能未完全成功。当前版本: $new_version，目标版本: $TARGET_CODENAME"
    fi
    
    # 检查系统状态
    systemctl --failed --no-legend | head -10
}

# 主函数
main() {
    echo "========================================"
    echo "       $SCRIPT_NAME"
    echo "========================================"
    echo
    
    check_root
    detect_debian_version
    check_upgrade_path
    
    echo
    warning "⚠️  重要提醒："
    echo "1. 升级过程可能需要较长时间"
    echo "2. 请确保网络连接稳定"
    echo "3. 建议在升级前备份重要数据"
    echo "4. 升级过程中请勿中断"
    echo
    
    read -p "确认开始升级？(y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "用户取消升级"
        exit 0
    fi
    
    create_backup
    step_by_step_upgrade
    verify_upgrade
    
    log "系统升级完成！"
    log "日志文件: $LOG_FILE"
    log "备份目录: $BACKUP_DIR"
    
    echo
    echo "🎉 升级完成！建议重启系统："
    echo "sudo reboot"
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi