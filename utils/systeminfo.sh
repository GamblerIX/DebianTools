#!/bin/bash

# 系统信息检测工具
# 用于检测当前系统状态和版本信息

set -euo pipefail

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检测操作系统
detect_os() {
    info "检测操作系统信息..."
    
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        echo "操作系统: $PRETTY_NAME"
        echo "版本代号: $VERSION_CODENAME"
        echo "版本ID: $VERSION_ID"
    else
        warning "无法读取 /etc/os-release"
    fi
    
    if [[ -f /etc/debian_version ]]; then
        echo "Debian版本: $(cat /etc/debian_version)"
    fi
}

# 检测系统架构
detect_architecture() {
    info "检测系统架构..."
    echo "架构: $(uname -m)"
    echo "内核: $(uname -r)"
    echo "处理器: $(nproc) 核心"
}

# 检测内存和存储
detect_resources() {
    info "检测系统资源..."
    
    # 内存信息
    local total_mem=$(free -h | awk '/^Mem:/ {print $2}')
    local used_mem=$(free -h | awk '/^Mem:/ {print $3}')
    local free_mem=$(free -h | awk '/^Mem:/ {print $4}')
    
    echo "内存总量: $total_mem"
    echo "已使用: $used_mem"
    echo "可用内存: $free_mem"
    
    # 磁盘信息
    echo
    echo "磁盘使用情况:"
    df -h | grep -E '^/dev/'
}

# 检测网络状态
detect_network() {
    info "检测网络状态..."
    
    # 检查网络接口
    local interfaces=$(ip link show | grep -E '^[0-9]+:' | cut -d: -f2 | tr -d ' ')
    echo "网络接口: $interfaces"
    
    # 检查网络连通性
    if ping -c 1 8.8.8.8 &>/dev/null; then
        success "网络连接正常"
    else
        warning "网络连接异常"
    fi
}

# 检测已安装包数量
detect_packages() {
    info "检测软件包信息..."
    
    local total_packages=$(dpkg --get-selections | grep -c "install")
    echo "已安装包数量: $total_packages"
    
    # 检测包管理器
    if command -v apt &>/dev/null; then
        echo "包管理器: APT"
    fi
    
    # 检查可更新的包
    local upgradable=$(apt list --upgradable 2>/dev/null | grep -c "upgradable" || echo "0")
    echo "可更新包数量: $upgradable"
}

# 检测运行服务
detect_services() {
    info "检测系统服务..."
    
    local running_services=$(systemctl list-units --type=service --state=running --no-pager | grep -c "running")
    echo "运行中服务数量: $running_services"
    
    # 检查关键服务状态
    local critical_services=("ssh" "systemd-networkd" "systemd-resolved")
    
    for service in "${critical_services[@]}"; do
        if systemctl is-active "$service" &>/dev/null; then
            success "$service 服务运行正常"
        else
            warning "$service 服务未运行"
        fi
    done
}

# 检测系统负载
detect_load() {
    info "检测系统负载..."
    
    local load_avg=$(uptime | awk -F'load average:' '{print $2}')
    echo "系统负载:$load_avg"
    
    local uptime_info=$(uptime -p)
    echo "运行时间: $uptime_info"
}

# 安全检查
security_check() {
    info "执行安全检查..."
    
    # 检查root登录
    if [[ $EUID -eq 0 ]]; then
        warning "当前以root用户运行"
    else
        success "当前以普通用户运行"
    fi
    
    # 检查SSH配置
    if [[ -f /etc/ssh/sshd_config ]]; then
        if grep -q "PermitRootLogin no" /etc/ssh/sshd_config; then
            success "SSH root登录已禁用"
        else
            warning "SSH root登录未禁用"
        fi
    fi
    
    # 检查防火墙状态
    if command -v ufw &>/dev/null; then
        local ufw_status=$(ufw status | head -1)
        echo "防火墙状态: $ufw_status"
    fi
}

# 生成系统报告
generate_report() {
    local report_file="/tmp/system-report-$(date +%Y%m%d-%H%M%S).txt"
    
    info "生成系统报告: $report_file"
    
    {
        echo "======================================"
        echo "系统信息报告"
        echo "生成时间: $(date)"
        echo "======================================"
        echo
        
        detect_os
        echo
        detect_architecture
        echo
        detect_resources
        echo
        detect_network
        echo
        detect_packages
        echo
        detect_services
        echo
        detect_load
        echo
        security_check
        
    } > "$report_file"
    
    success "报告已保存到: $report_file"
}

# 主函数
main() {
    echo "======================================"
    echo "       系统信息检测工具"
    echo "======================================"
    echo
    
    detect_os
    echo
    detect_architecture
    echo
    detect_resources
    echo
    detect_network
    echo
    detect_packages
    echo
    detect_services
    echo
    detect_load
    echo
    security_check
    
    echo
    read -p "是否生成详细报告？(y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        generate_report
    fi
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi