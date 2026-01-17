#!/bin/bash
# ========================================================================
# DebianTools - 现代化的Debian系统管理工具
# 单文件bash脚本实现，无需安装依赖，开箱即用
# ========================================================================
# 相关文件:
#   - README.md        : 项目说明文档
# ========================================================================
# 作者: GamblerIX
# 许可: AGPL-3.0
# 仓库: https://github.com/GamblerIX/DebianTools
#       https://gitee.com/GamblerIX/DebianTools
# ========================================================================

# ========================================================================
# 全局变量定义 - 将所有可配置项放在文件开头便于修改
# ========================================================================

# 版本信息
readonly VERSION="1.0.0"
readonly SCRIPT_NAME="DebianTools"
readonly SCRIPT_CMD="DBT"

# 安装路径配置
readonly INSTALL_PATH="/usr/local/bin/${SCRIPT_CMD}"

# 远程下载地址
readonly GITHUB_RAW_URL="https://raw.githubusercontent.com/GamblerIX/DebianTools/main/debiantools.sh"
readonly GITEE_RAW_URL="https://gitee.com/GamblerIX/DebianTools/raw/main/debiantools.sh"

# 颜色定义 (ANSI转义码)
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m' # No Color (重置)

# 要精简移除的软件包列表
readonly MINIMIZE_PACKAGES=(
    "nano"
    "vim-tiny"
    "man-db"
    "manpages"
    "info"
    "install-info"
    "bash-completion"
    "command-not-found"
    "friendly-recovery"
    "popularity-contest"
    "laptop-detect"
    "usbutils"
    "pciutils"
    "lshw"
)

# 要停用的服务列表
readonly MINIMIZE_SERVICES=(
    "bluetooth"
    "cups"
    "cups-browsed"
    "avahi-daemon"
    "ModemManager"
)

# ========================================================================
# 工具函数
# ========================================================================

# 打印带颜色的标题
# 参数: $1 - 标题文本
print_header() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    printf "║  %-60s║\n" "$1"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# 打印成功消息
# 参数: $1 - 消息文本
print_success() {
    echo -e "${GREEN}[✓] $1${NC}"
}

# 打印错误消息
# 参数: $1 - 消息文本
print_error() {
    echo -e "${RED}[✗] $1${NC}"
}

# 打印警告消息
# 参数: $1 - 消息文本
print_warning() {
    echo -e "${YELLOW}[!] $1${NC}"
}

# 打印信息消息
# 参数: $1 - 消息文本
print_info() {
    echo -e "${BLUE}[i] $1${NC}"
}

# 打印步骤消息
# 参数: $1 - 步骤文本
print_step() {
    echo -e "${PURPLE}>>> $1${NC}"
}

# 检查是否以root权限运行
# 返回: 0 = 是root, 1 = 非root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "此操作需要root权限，请使用 sudo 运行"
        return 1
    fi
    return 0
}

# 检查是否为Debian系统
# 返回: 0 = 是Debian系统, 1 = 非Debian系统
check_debian() {
    if [[ ! -f /etc/debian_version ]]; then
        print_error "此脚本仅支持Debian及其衍生版本（如Ubuntu、Linux Mint等）"
        return 1
    fi
    return 0
}

# 检查Bash版本
# 返回: 0 = 版本符合要求, 1 = 版本过低
check_bash_version() {
    local bash_major="${BASH_VERSINFO[0]}"
    if [[ "$bash_major" -lt 4 ]]; then
        print_error "此脚本需要Bash 4.0+，当前版本: ${BASH_VERSION}"
        return 1
    fi
    return 0
}

# 获取当前脚本的绝对路径
get_script_path() {
    local script_path
    script_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
    echo "$script_path"
}

# ========================================================================
# 核心功能函数
# ========================================================================

# 显示帮助信息
show_help() {
    print_header "${SCRIPT_NAME} v${VERSION} - Debian系统管理工具"
    
    echo -e "${WHITE}描述:${NC}"
    echo "  现代化的Debian系统无头管理工具，单文件bash脚本实现"
    echo "  无需安装依赖，开箱即用"
    echo ""
    
    echo -e "${WHITE}用法:${NC}"
    echo "  ./debiantools.sh [选项]"
    echo "  ${SCRIPT_CMD} [选项]          (安装后可用)"
    echo ""
    
    echo -e "${WHITE}可用选项:${NC}"
    echo -e "  ${GREEN}--help, -h${NC}      显示此帮助信息"
    echo -e "  ${GREEN}--version, -v${NC}   显示版本信息"
    echo -e "  ${GREEN}--install${NC}       安装到系统 (需要root权限)"
    echo -e "  ${GREEN}--uninstall${NC}     从系统卸载 (需要root权限)"
    echo -e "  ${GREEN}--upgrade${NC}       一键升级系统 (需要root权限)"
    echo -e "  ${GREEN}--minimize${NC}      一键精简系统 (需要root权限)"
    echo ""
    
    echo -e "${WHITE}使用示例:${NC}"
    echo "  # 远程执行 - 一键升级系统"
    echo "  bash <(curl -fsSL ${GITHUB_RAW_URL}) --upgrade"
    echo ""
    echo "  # 远程执行 - 安装到系统"
    echo "  bash <(curl -fsSL ${GITHUB_RAW_URL}) --install"
    echo ""
    echo "  # 安装后直接使用DBT命令"
    echo "  DBT --upgrade"
    echo "  DBT --minimize"
    echo ""
    
    echo -e "${WHITE}系统要求:${NC}"
    echo "  - Debian 9+ 或基于Debian的发行版"
    echo "  - Bash 4.0+"
    echo "  - 标准Debian工具 (apt, dpkg等)"
    echo ""
    
    echo -e "${WHITE}项目地址:${NC}"
    echo "  GitHub: https://github.com/GamblerIX/DebianTools"
    echo "  Gitee:  https://gitee.com/GamblerIX/DebianTools"
}

# 显示版本信息
show_version() {
    echo "${SCRIPT_NAME} v${VERSION}"
}

# 安装脚本到系统
# 支持两种方式：本地文件安装 或 远程下载安装（通过管道执行时）
do_install() {
    print_header "安装 ${SCRIPT_NAME}"
    
    # 检查权限
    check_root || return 1
    
    local script_path
    script_path="$(get_script_path)"
    
    print_step "正在安装到 ${INSTALL_PATH}..."
    
    # 判断是否通过管道执行（BASH_SOURCE[0] 为空或不存在）
    if [[ -f "$script_path" ]] && [[ "$script_path" != "/"* || -s "$script_path" ]]; then
        # 本地文件存在，直接复制
        if cp "$script_path" "$INSTALL_PATH"; then
            print_success "脚本已从本地复制"
        else
            print_error "复制脚本失败"
            return 1
        fi
    else
        # 通过管道执行，需要从远程下载
        print_info "检测到管道执行模式，正在从远程下载脚本..."
        
        # 优先尝试 GitHub
        if curl -fsSL "$GITHUB_RAW_URL" -o "$INSTALL_PATH" 2>/dev/null; then
            print_success "已从 GitHub 下载脚本"
        # 备选 Gitee
        elif curl -fsSL "$GITEE_RAW_URL" -o "$INSTALL_PATH" 2>/dev/null; then
            print_success "已从 Gitee 下载脚本"
        else
            print_error "下载脚本失败，请检查网络连接"
            return 1
        fi
    fi
    
    # 设置执行权限
    if chmod +x "$INSTALL_PATH"; then
        print_success "已设置执行权限"
    else
        print_error "设置权限失败"
        return 1
    fi
    
    echo ""
    print_success "安装完成!"
    echo ""
    echo -e "${WHITE}现在可以使用以下命令:${NC}"
    echo -e "  ${GREEN}${SCRIPT_CMD} --help${NC}     查看帮助"
    echo -e "  ${GREEN}${SCRIPT_CMD} --upgrade${NC}  升级系统"
    echo -e "  ${GREEN}${SCRIPT_CMD} --minimize${NC} 精简系统"
}

# 卸载脚本
do_uninstall() {
    print_header "卸载 ${SCRIPT_NAME}"
    
    # 检查权限
    check_root || return 1
    
    if [[ -f "$INSTALL_PATH" ]]; then
        print_step "正在卸载..."
        
        if rm -f "$INSTALL_PATH"; then
            print_success "卸载完成! ${SCRIPT_CMD} 命令已移除"
        else
            print_error "卸载失败"
            return 1
        fi
    else
        print_warning "${SCRIPT_NAME} 未安装"
    fi
}

# 一键升级系统
do_upgrade() {
    print_header "系统升级"
    
    # 检查权限和系统
    check_root || return 1
    check_debian || return 1
    
    local start_time
    start_time=$(date +%s)
    
    # 步骤1: 更新软件源
    print_step "步骤 1/4: 更新软件源列表..."
    if apt-get update -y; then
        print_success "软件源已更新"
    else
        print_error "更新软件源失败"
        return 1
    fi
    
    echo ""
    
    # 步骤2: 升级软件包
    print_step "步骤 2/4: 升级所有软件包..."
    if DEBIAN_FRONTEND=noninteractive apt-get upgrade -y; then
        print_success "软件包已升级"
    else
        print_error "升级软件包失败"
        return 1
    fi
    
    echo ""
    
    # 步骤3: 自动移除不需要的软件包
    print_step "步骤 3/4: 清理不需要的软件包..."
    if apt-get autoremove -y; then
        print_success "已清理不需要的软件包"
    else
        print_warning "清理失败，但这不影响升级结果"
    fi
    
    echo ""
    
    # 步骤4: 清理下载缓存
    print_step "步骤 4/4: 清理下载缓存..."
    if apt-get autoclean -y; then
        print_success "缓存已清理"
    else
        print_warning "清理缓存失败，但这不影响升级结果"
    fi
    
    # 计算耗时
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo ""
    print_success "系统升级完成! 耗时: ${duration}秒"
    
    # 检查是否需要重启
    if [[ -f /var/run/reboot-required ]]; then
        echo ""
        print_warning "系统需要重启以完成更新"
        echo -e "    运行 ${GREEN}sudo reboot${NC} 重启系统"
    fi
}

# 一键精简系统
do_minimize() {
    print_header "系统精简"
    
    # 检查权限和系统
    check_root || return 1
    check_debian || return 1
    
    print_warning "此操作将移除以下软件包和服务以减小系统体积:"
    echo ""
    echo -e "${YELLOW}软件包:${NC}"
    printf '  %s\n' "${MINIMIZE_PACKAGES[@]}"
    echo ""
    echo -e "${YELLOW}服务:${NC}"
    printf '  %s\n' "${MINIMIZE_SERVICES[@]}"
    echo ""
    
    # 确认操作
    read -r -p "是否继续? [y/N] " response
    case "$response" in
        [yY][eE][sS]|[yY])
            ;;
        *)
            print_info "操作已取消"
            return 0
            ;;
    esac
    
    echo ""
    local start_time
    start_time=$(date +%s)
    
    # 记录初始磁盘使用
    local initial_space
    initial_space=$(df -BM / | awk 'NR==2 {print $3}' | tr -d 'M')
    
    # 步骤1: 移除不必要的软件包
    print_step "步骤 1/4: 移除不必要的软件包..."
    local removed_count=0
    for pkg in "${MINIMIZE_PACKAGES[@]}"; do
        if dpkg -l "$pkg" &>/dev/null; then
            if apt-get purge -y "$pkg" &>/dev/null; then
                print_success "已移除: $pkg"
                ((removed_count++))
            fi
        fi
    done
    
    if [[ $removed_count -eq 0 ]]; then
        print_info "没有找到可移除的软件包"
    else
        print_success "已移除 ${removed_count} 个软件包"
    fi
    
    echo ""
    
    # 步骤2: 停用不必要的服务
    print_step "步骤 2/4: 停用不必要的服务..."
    local disabled_count=0
    for service in "${MINIMIZE_SERVICES[@]}"; do
        if systemctl is-enabled "$service" &>/dev/null; then
            if systemctl disable --now "$service" &>/dev/null; then
                print_success "已停用: $service"
                ((disabled_count++))
            fi
        fi
    done
    
    if [[ $disabled_count -eq 0 ]]; then
        print_info "没有找到可停用的服务"
    else
        print_success "已停用 ${disabled_count} 个服务"
    fi
    
    echo ""
    
    # 步骤3: 清理依赖和缓存
    print_step "步骤 3/4: 清理依赖和缓存..."
    apt-get autoremove -y &>/dev/null
    apt-get autoclean -y &>/dev/null
    apt-get clean &>/dev/null
    print_success "依赖和缓存已清理"
    
    echo ""
    
    # 步骤4: 清理日志
    print_step "步骤 4/4: 清理系统日志..."
    if command -v journalctl &>/dev/null; then
        journalctl --vacuum-time=1d &>/dev/null
        print_success "日志已清理 (保留1天)"
    fi
    
    # 计算节省的空间
    local final_space
    final_space=$(df -BM / | awk 'NR==2 {print $3}' | tr -d 'M')
    local saved_space=$((initial_space - final_space))
    
    # 计算耗时
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    echo ""
    print_success "系统精简完成!"
    echo ""
    echo -e "${WHITE}统计信息:${NC}"
    echo -e "  移除软件包: ${GREEN}${removed_count}${NC} 个"
    echo -e "  停用服务:   ${GREEN}${disabled_count}${NC} 个"
    if [[ $saved_space -gt 0 ]]; then
        echo -e "  节省空间:   ${GREEN}${saved_space}MB${NC}"
    fi
    echo -e "  耗时:       ${GREEN}${duration}${NC} 秒"
}

# ========================================================================
# 主程序入口
# ========================================================================

main() {
    # 检查Bash版本
    check_bash_version || exit 1
    
    # 解析命令行参数
    case "${1:-}" in
        --help|-h|"")
            show_help
            ;;
        --version|-v)
            show_version
            ;;
        --install)
            do_install
            ;;
        --uninstall)
            do_uninstall
            ;;
        --upgrade)
            do_upgrade
            ;;
        --minimize)
            do_minimize
            ;;
        *)
            print_error "未知选项: $1"
            echo ""
            echo "运行 '${SCRIPT_NAME} --help' 查看可用选项"
            exit 1
            ;;
    esac
}

# 调用主函数，传入所有参数
main "$@"
