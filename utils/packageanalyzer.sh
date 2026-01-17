#!/bin/bash

# 包分析工具 - 分析当前系统包状态，为精简提供建议

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

# 分析包大小分布
analyze_package_sizes() {
    info "分析包大小分布..."
    
    echo "占用空间最大的20个包："
    dpkg-query -Wf '${Installed-Size}\t${Package}\t${Status}\n' | \
    grep "install ok installed" | \
    sort -n -r | \
    head -20 | \
    while IFS=$'\t' read size package status; do
        printf "  %-30s %8s MB\n" "$package" "$((size / 1024))"
    done
    
    echo
    local total_size=$(dpkg-query -Wf '${Installed-Size}\n' | awk '{sum+=$1} END {print sum/1024}')
    echo "所有包总大小: ${total_size} MB"
}

# 分析开发工具
analyze_dev_packages() {
    info "分析开发工具包..."
    
    local dev_packages=(
        "build-essential" "gcc" "g++" "make" "cmake"
        "python3-dev" "python3-pip" "nodejs" "npm"
        "git" "vim" "emacs"
    )
    
    local dev_size=0
    local dev_count=0
    
    echo "已安装的开发工具："
    for package in "${dev_packages[@]}"; do
        if dpkg -l "$package" 2>/dev/null | grep -q "^ii"; then
            local size=$(dpkg-query -Wf '${Installed-Size}' "$package" 2>/dev/null || echo "0")
            printf "  %-20s %6s KB\n" "$package" "$size"
            ((dev_size += size))
            ((dev_count++))
        fi
    done
    
    if [[ $dev_count -gt 0 ]]; then
        echo "开发工具总计: $dev_count 个包, $((dev_size / 1024)) MB"
        warning "服务器环境建议移除开发工具以节省空间"
    else
        success "未发现大型开发工具包"
    fi
}

# 分析图形界面组件
analyze_gui_packages() {
    info "分析图形界面组件..."
    
    local gui_patterns=("x11" "xorg" "gnome" "kde" "xfce" "font")
    local gui_size=0
    local gui_count=0
    
    echo "图形界面相关包："
    for pattern in "${gui_patterns[@]}"; do
        while IFS= read -r line; do
            if [[ -n "$line" ]]; then
                local package=$(echo "$line" | awk '{print $2}')
                local size=$(dpkg-query -Wf '${Installed-Size}' "$package" 2>/dev/null || echo "0")
                printf "  %-30s %6s KB\n" "$package" "$size"
                ((gui_size += size))
                ((gui_count++))
            fi
        done < <(dpkg -l | grep "^ii" | grep -i "$pattern" | head -5)
    done
    
    if [[ $gui_count -gt 0 ]]; then
        echo "图形组件总计: $gui_count 个包, $((gui_size / 1024)) MB"
        warning "服务器环境建议移除图形界面组件"
    else
        success "未发现图形界面组件"
    fi
}

# 分析文档包
analyze_doc_packages() {
    info "分析文档包..."
    
    local doc_patterns=("doc" "man" "info")
    local doc_size=0
    local doc_count=0
    
    for pattern in "${doc_patterns[@]}"; do
        while IFS= read -r line; do
            if [[ -n "$line" ]]; then
                local package=$(echo "$line" | awk '{print $2}')
                local size=$(dpkg-query -Wf '${Installed-Size}' "$package" 2>/dev/null || echo "0")
                ((doc_size += size))
                ((doc_count++))
            fi
        done < <(dpkg -l | grep "^ii" | grep -E "(^ii.*-doc|^ii.*man|^ii.*info)")
    done
    
    echo "文档包统计: $doc_count 个包, $((doc_size / 1024)) MB"
    if [[ $doc_size -gt 10240 ]]; then  # 大于10MB
        warning "文档包占用较多空间，服务器环境可考虑移除"
    fi
}

# 分析服务状态
analyze_services() {
    info "分析系统服务..."
    
    local total_services=$(systemctl list-units --type=service --all --no-pager | grep -c "service")
    local running_services=$(systemctl list-units --type=service --state=running --no-pager | grep -c "running")
    local failed_services=$(systemctl list-units --type=service --state=failed --no-pager | grep -c "failed" || echo "0")
    
    echo "服务统计:"
    echo "  总服务数: $total_services"
    echo "  运行中: $running_services"
    echo "  失败: $failed_services"
    
    if [[ $failed_services -gt 0 ]]; then
        warning "发现失败的服务，建议检查"
        systemctl list-units --type=service --state=failed --no-pager
    fi
    
    # 检查不必要的服务
    local unnecessary_services=("bluetooth" "cups" "avahi-daemon" "ModemManager")
    echo
    echo "可能不需要的服务:"
    for service in "${unnecessary_services[@]}"; do
        if systemctl is-enabled "$service" 2>/dev/null | grep -q "enabled"; then
            warning "  $service 服务已启用（服务器可能不需要）"
        fi
    done
}

# 生成精简建议
generate_recommendations() {
    info "生成精简建议..."
    
    echo "======================================"
    echo "系统精简建议"
    echo "======================================"
    
    # 计算可节省的空间
    local total_removable=0
    
    # 开发工具
    local dev_size=$(dpkg-query -Wf '${Installed-Size}\n' build-essential gcc g++ make 2>/dev/null | awk '{sum+=$1} END {print sum}' || echo "0")
    if [[ $dev_size -gt 0 ]]; then
        echo "1. 移除开发工具可节省: $((dev_size / 1024)) MB"
        ((total_removable += dev_size))
    fi
    
    # 文档
    local doc_size=$(dpkg -l | grep -E "(^ii.*-doc|^ii.*man)" | wc -l)
    if [[ $doc_size -gt 10 ]]; then
        echo "2. 移除文档包可节省约: 50-100 MB"
        ((total_removable += 51200))  # 估算50MB
    fi
    
    # 图形组件
    local gui_size=$(dpkg -l | grep -i "x11\|font\|xorg" | wc -l)
    if [[ $gui_size -gt 5 ]]; then
        echo "3. 移除图形组件可节省约: 100-200 MB"
        ((total_removable += 102400))  # 估算100MB
    fi
    
    echo
    echo "预计总共可节省空间: $((total_removable / 1024)) MB"
    
    echo
    echo "建议执行的精简操作:"
    echo "  curl -fsSL https://github.com/GamblerIX/DebianTools/raw/main/scripts/debianminimize.sh | bash"
    echo "  curl -fsSL https://github.com/GamblerIX/DebianTools/raw/main/scripts/debianupgrade.sh | bash"
    echo "======================================"
}

# 主函数
main() {
    echo "======================================"
    echo "       Debian包分析工具"
    echo "======================================"
    echo
    
    analyze_package_sizes
    echo
    analyze_dev_packages
    echo
    analyze_gui_packages
    echo
    analyze_doc_packages
    echo
    analyze_services
    echo
    generate_recommendations
}

# 脚本入口
if [[ "${BASH_SOURCE[0]:-$0}" == "${0}" ]]; then
    main "$@"
fi