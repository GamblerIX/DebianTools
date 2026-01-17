#!/bin/bash
#===============================================================================
# Debian Tools v2.0.0
# 现代化的Debian系统管理工具
#
# 作者: GamblerIX
#===============================================================================

set -euo pipefail

#===============================================================================
# 全局变量和常量
#===============================================================================

# 版本信息
readonly VERSION="2.0.0"
readonly SCRIPT_NAME="debiantools"

# 颜色定义
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[1;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_CYAN='\033[0;36m'
readonly COLOR_RESET='\033[0m'

# 错误码
readonly ERR_SUCCESS=0
readonly ERR_GENERAL=1
readonly ERR_INVALID_ARGS=2
readonly ERR_PERMISSION=3
readonly ERR_NOT_FOUND=4
readonly ERR_PACKAGE=6

#===============================================================================
# 工具函数
#===============================================================================

# 打印彩色消息
print_color() {
    local color="$1"
    local message="$2"
    echo -e "${color}${message}${COLOR_RESET}"
}

# 打印信息消息
print_info() {
    print_color "$COLOR_BLUE" "ℹ $1"
}

# 打印成功消息
print_success() {
    print_color "$COLOR_GREEN" "✓ $1"
}

# 打印警告消息
print_warning() {
    print_color "$COLOR_YELLOW" "⚠ $1"
}

# 打印错误消息
print_error() {
    print_color "$COLOR_RED" "✗ $1" >&2
}

# 错误处理并退出
die() {
    local message="$1"
    local code="${2:-$ERR_GENERAL}"
    print_error "$message"
    exit "$code"
}

# 确认对话框
confirm() {
    local message="$1"
    local default="${2:-n}"
    
    local prompt
    if [[ "$default" == "y" ]]; then
        prompt="${message} [Y/n]: "
    else
        prompt="${message} [y/N]: "
    fi
    
    read -p "$prompt" -n 1 -r
    echo
    
    if [[ -z "$REPLY" ]]; then
        [[ "$default" == "y" ]]
    else
        [[ $REPLY =~ ^[Yy]$ ]]
    fi
}

# 显示进度条
show_progress() {
    local current="$1"
    local total="$2"
    local width=50
    
    local percent=$((current * 100 / total))
    local filled=$((percent * width / 100))
    local empty=$((width - filled))
    
    printf "\r["
    printf "%${filled}s" | tr ' ' '='
    printf "%${empty}s" | tr ' ' ' '
    printf "] %3d%%" "$percent"
    
    if [[ "$current" -eq "$total" ]]; then
        echo
    fi
}

# 格式化字节大小
format_size() {
    local size="$1"
    local units=("B" "KB" "MB" "GB" "TB")
    local unit=0
    
    while ((size > 1024 && unit < 4)); do
        size=$((size / 1024))
        ((unit++))
    done
    
    echo "${size} ${units[$unit]}"
}

# 检查命令是否存在
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 检查是否为root用户
is_root() {
    [[ $EUID -eq 0 ]]
}

#===============================================================================
# 核心功能函数
#===============================================================================

# 获取已安装包列表
get_installed_packages() {
    dpkg-query -W -f='${Package}\t${Installed-Size}\t${Status}\n' 2>/dev/null | \
    awk '$3=="install" && $4=="ok" && $5=="installed" {print $1"\t"$2}'
}

# 分析包信息
analyze_packages() {
    print_info "正在分析已安装的包..."
    
    local total_packages=0
    local total_size=0
    
    # 统计包信息
    while IFS=$'\t' read -r package size; do
        ((total_packages++))
        ((total_size += size))
        
        # 显示进度
        if ((total_packages % 100 == 0)); then
            printf "\r正在分析... 已处理 %d 个包" "$total_packages"
        fi
    done < <(get_installed_packages)
    
    echo
    
    # 显示结果
    print_success "包分析完成"
    echo
    echo "统计信息:"
    echo "  总包数: $total_packages"
    echo "  总大小: $(format_size $((total_size * 1024)))"
    echo "  平均大小: $(format_size $((total_size * 1024 / total_packages)))"
}

# 获取系统信息
get_system_info() {
    print_info "系统信息:"
    echo
    
    # 操作系统信息
    if command_exists lsb_release; then
        echo "  操作系统: $(lsb_release -ds 2>/dev/null || echo '未知')"
        echo "  发行版本: $(lsb_release -cs 2>/dev/null || echo '未知')"
    fi
    
    # 内核信息
    echo "  内核版本: $(uname -r)"
    echo "  系统架构: $(dpkg --print-architecture 2>/dev/null || uname -m)"
    
    # 磁盘使用
    local disk_info=$(df -h / 2>/dev/null | tail -1)
    if [[ -n "$disk_info" ]]; then
        local used=$(echo "$disk_info" | awk '{print $3}')
        local total=$(echo "$disk_info" | awk '{print $2}')
        local percent=$(echo "$disk_info" | awk '{print $5}')
        echo "  磁盘使用: ${used} / ${total} (${percent})"
    fi
    
    # 内存信息
    if [[ -f /proc/meminfo ]]; then
        local mem_total=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
        local mem_available=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
        echo "  内存总量: $(format_size $((mem_total * 1024)))"
        echo "  可用内存: $(format_size $((mem_available * 1024)))"
    fi
    
    echo
}

# 系统升级
upgrade_system() {
    if ! is_root; then
        die "系统升级需要root权限，请使用sudo运行" "$ERR_PERMISSION"
    fi
    
    print_info "准备升级系统..."
    
    if ! confirm "确定要升级系统吗？这可能需要较长时间"; then
        print_warning "操作已取消"
        return
    fi
    
    # 更新包列表
    print_info "正在更新包列表..."
    if apt-get update; then
        print_success "包列表更新完成"
    else
        die "更新包列表失败" "$ERR_PACKAGE"
    fi
    
    # 升级系统
    print_info "正在升级系统..."
    if apt-get dist-upgrade -y; then
        print_success "系统升级完成"
    else
        print_error "系统升级失败"
        return "$ERR_GENERAL"
    fi
    
    # 清理
    print_info "正在清理..."
    apt-get autoremove -y >/dev/null 2>&1
    apt-get autoclean -y >/dev/null 2>&1
    
    print_success "所有操作完成"
}

# 系统精简
minimize_system() {
    if ! is_root; then
        die "系统精简需要root权限，请使用sudo运行" "$ERR_PERMISSION"
    fi
    
    print_info "准备精简系统..."
    
    if ! confirm "确定要精简系统吗？这将移除不必要的包"; then
        print_warning "操作已取消"
        return
    fi
    
    # 移除不需要的包
    print_info "正在移除不需要的包..."
    apt-get autoremove -y
    
    # 清理包缓存
    print_info "正在清理包缓存..."
    apt-get autoclean -y
    apt-get clean -y
    
    # 清理日志
    print_info "正在清理旧日志..."
    journalctl --vacuum-time=7d 2>/dev/null || true
    
    print_success "系统精简完成"
}

#===============================================================================
# 命令处理函数
#===============================================================================

# analyze命令 - 分析系统
cmd_analyze() {
    get_system_info
    analyze_packages
}

# upgrade命令 - 升级系统
cmd_upgrade() {
    upgrade_system
}

# minimize命令 - 精简系统
cmd_minimize() {
    minimize_system
}

# help命令 - 显示帮助
cmd_help() {
    cat << EOF
${COLOR_CYAN}Debian Tools v${VERSION}${COLOR_RESET}
现代化的Debian系统管理工具

${COLOR_YELLOW}使用方法:${COLOR_RESET}
    $SCRIPT_NAME [选项]

${COLOR_YELLOW}选项:${COLOR_RESET}
    ${COLOR_GREEN}--analyze${COLOR_RESET}            分析系统和包信息
    ${COLOR_GREEN}--upgrade${COLOR_RESET}            升级系统（需要root权限）
    ${COLOR_GREEN}--minimize${COLOR_RESET}           精简系统，移除不必要的包（需要root权限）
    ${COLOR_GREEN}--help, -h${COLOR_RESET}           显示此帮助信息
    ${COLOR_GREEN}--version, -v${COLOR_RESET}        显示版本信息

${COLOR_YELLOW}示例:${COLOR_RESET}
    $SCRIPT_NAME --analyze
    sudo $SCRIPT_NAME --upgrade
    sudo $SCRIPT_NAME --minimize

${COLOR_YELLOW}更多信息:${COLOR_RESET}
    GitHub: https://github.com/GamblerIX/DebianTools
    Gitee:  https://gitee.com/GamblerIX/DebianTools

EOF
}

# version命令 - 显示版本
cmd_version() {
    echo "Debian Tools v${VERSION}"
}

#===============================================================================
# 主函数
#===============================================================================

main() {
    # 获取命令
    local command="${1:---help}"
    shift || true
    
    # 检查root权限（某些命令需要）
    if [[ "$command" =~ ^(--upgrade|--minimize)$ ]] && ! is_root; then
        die "命令 '$command' 需要root权限，请使用sudo运行" "$ERR_PERMISSION"
    fi
    
    # 分发命令
    case "$command" in
        --analyze)
            cmd_analyze "$@"
            ;;
        --upgrade)
            cmd_upgrade "$@"
            ;;
        --minimize)
            cmd_minimize "$@"
            ;;
        --help|-h)
            cmd_help
            ;;
        --version|-v)
            cmd_version
            ;;
        *)
            print_error "未知命令: $command"
            echo "使用 '$SCRIPT_NAME --help' 查看帮助"
            exit "$ERR_INVALID_ARGS"
            ;;
    esac
}

#===============================================================================
# 脚本入口点
#===============================================================================

# 执行主函数
main "$@"
