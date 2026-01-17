#!/bin/bash

# 远程Debian精简脚本
# 此脚本将被主脚本下载并执行，用于精简Debian系统

set -euo pipefail

# 配置变量
SCRIPT_VERSION="1.0.0"
LOG_PREFIX="[MINIMIZE]"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}${LOG_PREFIX}${NC} $1"
}

warning() {
    echo -e "${YELLOW}${LOG_PREFIX}${NC} $1"
}

error() {
    echo -e "${RED}${LOG_PREFIX}${NC} $1"
    exit 1
}

# 基于实际系统分析的精简包列表
PACKAGES_TO_REMOVE=(
    # 文档和手册系统
    "man-db"
    "manpages"
    "manpages-dev"
    "doc-debian"
    "debian-faq"
    
    # 编辑器（只保留nano）
    "vim"
    "vim-common" 
    "vim-runtime"
    "vim-tiny"
    
    # 开发工具链
    "build-essential"
    "gcc"
    "gcc-12"
    "gcc-12-base"
    "g++"
    "g++-12"
    "cpp"
    "cpp-12"
    "make"
    "libc6-dev"
    "libc-dev-bin"
    "libc-devtools"
    "linux-libc-dev"
    "libgcc-12-dev"
    "libstdc++-12-dev"
    "dpkg-dev"
    "patch"
    "fakeroot"
    
    # Python开发包（保留基础python3）
    "python3-dev"
    "python3-pip"
    "libpython3-dev"
    "libpython3.11-dev"
    "python3.11-dev"
    
    # 调试和分析工具
    "crash"
    "strace"
    "systemtap"
    "systemtap-common"
    "systemtap-runtime"
    "makedumpfile"
    "kdump-tools"
    "kexec-tools"
    
    # 网络调试工具
    "telnet"
    "inetutils-telnet"
    "netcat-traditional"
    "traceroute"
    
    # 性能测试工具
    "fio"
    "iperf"
    
    # X11相关（服务器不需要）
    "libx11-6"
    "libx11-data"
    "libxau6"
    "libxcb1"
    "libxdmcp6"
    "libxext6"
    "libxmuu1"
    "libxpm4"
    "xauth"
    "xdg-user-dirs"
    "xkb-data"
    
    # 字体和图形
    "fonts-dejavu-core"
    "fontconfig-config"
    "libfontconfig1"
    "libfreetype6"
    
    # 多媒体库
    "libgstreamer1.0-0"
    "libjpeg62-turbo"
    "libpng16-16"
    "libtiff6"
    "libwebp7"
    "libavif15"
    "libheif1"
    "libde265-0"
    "libdav1d6"
    "libgav1-1"
    "librav1e0"
    "libsvtav1enc1"
    "libx265-199"
    "libyuv0"
    "libaom3"
    
    # 图像处理
    "libgd3"
    "libjbig0"
    "liblerc4"
    
    # 任务管理器
    "tasksel"
    "tasksel-data"
    "task-english"
    "task-ssh-server"
    
    # 语言和本地化
    "dictionaries-common"
    "iamerican"
    "ibritish"
    "ienglish-common"
    "ispell"
    "wamerican"
    
    # 报告工具
    "reportbug"
    "python3-reportbug"
    "python3-debianbts"
    "installation-report"
    
    # 包管理GUI
    "packagekit"
    "packagekit-tools"
    "libpackagekit-glib2-18"
    "gir1.2-packagekitglib-1.0"
    
    # 发现服务
    "discover"
    "discover-data"
    
    # 硬件检测
    "laptop-detect"
    
    # 云相关（根据需要保留）
    "cloud-guest-utils"
    
    # 邮件相关
    "mailcap"
    
    # JavaScript库（服务器不需要）
    "javascript-common"
    "libjs-jquery"
    "libjs-sphinxdoc"
    "libjs-underscore"
    
    # 不必要的库文件
    "emacsen-common"
    "shared-mime-info"
    "media-types"
    "mime-support"
    
    # Xen虚拟化（如果不使用）
    "libxen*"
    
    # 开发库的开发包
    "libexpat1-dev"
    "libnsl-dev"
    "libtirpc-dev"
    "zlib1g-dev"
)

# 要保留的关键包（基于实际系统分析）
ESSENTIAL_PACKAGES=(
    # 核心系统
    "base-files"
    "base-passwd"
    "bash"
    "bash-completion"
    "bsdutils"
    "bsdextrautils"
    "coreutils"
    "dash"
    "debconf"
    "debian-archive-keyring"
    "debianutils"
    "diffutils"
    "dpkg"
    "e2fsprogs"
    "findutils"
    "grep"
    "gzip"
    "hostname"
    "init"
    "init-system-helpers"
    "libc6"
    "libc-bin"
    "login"
    "lsb-base"
    "lsb-release"
    "mawk"
    "mount"
    "passwd"
    "perl-base"
    "sed"
    "systemd"
    "systemd-sysv"
    "systemd-resolved"
    "sysvinit-utils"
    "tar"
    "util-linux"
    "util-linux-extra"
    "tzdata"
    "usr-is-merged"
    
    # 包管理
    "apt"
    "apt-utils"
    "apt-listchanges"
    
    # 基础工具
    "nano"
    "less"
    "file"
    "lsof"
    "psmisc"
    "procps"
    "which"
    "ncurses-base"
    "ncurses-bin"
    "ncurses-term"
    "readline-common"
    
    # 网络基础
    "iproute2"
    "iputils-ping"
    "netbase"
    "net-tools"
    "wget"
    "curl"
    "ca-certificates"
    "bind9-dnsutils"
    "bind9-host"
    "bind9-libs"
    
    # SSH和安全
    "openssh-server"
    "openssh-client"
    "openssh-sftp-server"
    "ssh"
    "sudo"
    "gnupg"
    "gnupg-utils"
    "gpg"
    "gpg-agent"
    "gpgconf"
    "gpgv"
    "openssl"
    
    # 系统监控和管理
    "dstat"
    "sysstat"
    "htop"
    "dmidecode"
    "pciutils"
    "pci.ids"
    "usbutils"
    "ethtool"
    "lm-sensors"
    "libsensors5"
    "libsensors-config"
    
    # 压缩工具
    "gzip"
    "bzip2"
    "xz-utils"
    "zstd"
    
    # 文本处理
    "awk"
    "sed"
    "grep"
    
    # 系统服务
    "cron"
    "cron-daemon-common"
    "rsyslog"
    "logrotate"
    "chrony"
    
    # 网络配置
    "netplan.io"
    "isc-dhcp-client"
    "isc-dhcp-common"
    
    # 基础Python（系统工具依赖）
    "python3"
    "python3-minimal"
    "python3.11"
    "python3.11-minimal"
    "libpython3.11"
    "libpython3.11-minimal"
    "libpython3.11-stdlib"
    
    # 必要的库文件
    "libc6"
    "libssl3"
    "libcrypt1"
    "libgcc-s1"
    "libstdc++6"
    "zlib1g"
    
    # 硬件支持
    "udev"
    "kmod"
    "firmware-linux-free"
    
    # 引导相关
    "grub-common"
    "grub2-common"
    "initramfs-tools"
    "initramfs-tools-core"
    
    # 阿里云相关（如果在阿里云）
    "aliyun-assist"
    
    # 容器/虚拟化支持
    "adduser"
)

# 检查包是否为关键包
is_essential_package() {
    local package="$1"
    for essential in "${ESSENTIAL_PACKAGES[@]}"; do
        if [[ "$package" == "$essential" ]]; then
            return 0
        fi
    done
    return 1
}

# 移除非必需包
remove_unnecessary_packages() {
    log "开始移除非必需包..."
    
    local removed_count=0
    local failed_count=0
    
    # 首先移除大型包和明显不需要的包
    for package in "${PACKAGES_TO_REMOVE[@]}"; do
        # 检查包是否已安装
        if dpkg -l 2>/dev/null | grep -q "^ii.*$package"; then
            if ! is_essential_package "$package"; then
                log "移除包: $package"
                if apt-get remove --purge -y "$package" 2>/dev/null; then
                    ((removed_count++))
                else
                    warning "无法移除 $package"
                    ((failed_count++))
                fi
            else
                warning "跳过关键包: $package"
            fi
        fi
    done
    
    # 移除推荐包和建议包
    log "移除自动安装的推荐包..."
    apt-get autoremove --purge -y
    
    # 移除开发相关的库文件
    log "移除开发库文件..."
    apt-get remove --purge -y '*-dev' '*-doc' 2>/dev/null || true
    
    log "包移除完成: 成功移除 $removed_count 个包，失败 $failed_count 个包"
}

# 清理孤立包
clean_orphaned_packages() {
    log "清理孤立包..."
    
    # 移除自动安装但不再需要的包
    apt-get autoremove --purge -y
    
    # 清理包缓存
    apt-get autoclean
    apt-get clean
    
    # 移除孤立的配置文件
    dpkg --list | grep "^rc" | cut -d" " -f3 | xargs -r dpkg --purge
}

# 清理系统文件
clean_system_files() {
    log "深度清理系统文件..."
    
    # 清理日志文件
    find /var/log -type f -name "*.log" -exec truncate -s 0 {} \; 2>/dev/null || true
    find /var/log -type f -name "*.log.*" -delete 2>/dev/null || true
    find /var/log -type f -name "*.gz" -delete 2>/dev/null || true
    
    # 清理临时文件
    rm -rf /tmp/* 2>/dev/null || true
    rm -rf /var/tmp/* 2>/dev/null || true
    
    # 清理缓存
    rm -rf /var/cache/apt/archives/*.deb 2>/dev/null || true
    rm -rf /var/cache/debconf/* 2>/dev/null || true
    rm -rf /var/cache/man/* 2>/dev/null || true
    
    # 彻底移除文档
    rm -rf /usr/share/doc/* 2>/dev/null || true
    rm -rf /usr/share/man/* 2>/dev/null || true
    rm -rf /usr/share/info/* 2>/dev/null || true
    rm -rf /usr/share/help/* 2>/dev/null || true
    rm -rf /usr/share/gtk-doc/* 2>/dev/null || true
    
    # 清理语言文件（只保留英文和C）
    find /usr/share/locale -mindepth 1 -maxdepth 1 -type d ! -name 'en*' ! -name 'C' -exec rm -rf {} \; 2>/dev/null || true
    
    # 清理字体文件（保留基础字体）
    find /usr/share/fonts -name "*.ttf" -o -name "*.otf" | head -n -10 | xargs rm -f 2>/dev/null || true
    
    # 清理图标和主题
    rm -rf /usr/share/icons/* 2>/dev/null || true
    rm -rf /usr/share/themes/* 2>/dev/null || true
    rm -rf /usr/share/pixmaps/* 2>/dev/null || true
    
    # 清理应用程序数据
    rm -rf /usr/share/applications/* 2>/dev/null || true
    rm -rf /usr/share/menu/* 2>/dev/null || true
    
    # 清理内核模块（保留当前内核）
    local current_kernel=$(uname -r)
    find /lib/modules -maxdepth 1 -type d ! -name "$current_kernel" -exec rm -rf {} \; 2>/dev/null || true
    
    # 清理头文件
    rm -rf /usr/include/* 2>/dev/null || true
    
    log "系统文件清理完成"
}

# 优化系统配置
optimize_system_config() {
    log "优化服务器系统配置..."
    
    # 禁用不需要的服务
    local services_to_disable=(
        "bluetooth"
        "cups"
        "avahi-daemon"
        "ModemManager"
        "NetworkManager"
        "wpa_supplicant"
        "alsa-state"
        "pulseaudio"
        "gdm"
        "lightdm"
        "sddm"
        "display-manager"
    )
    
    for service in "${services_to_disable[@]}"; do
        if systemctl is-enabled "$service" 2>/dev/null | grep -q "enabled"; then
            systemctl disable "$service" 2>/dev/null || true
            systemctl stop "$service" 2>/dev/null || true
            log "已禁用服务: $service"
        fi
    done
    
    # 配置APT不安装推荐包和建议包
    cat > /etc/apt/apt.conf.d/99no-recommends << 'EOF'
APT::Install-Recommends "false";
APT::Install-Suggests "false";
APT::AutoRemove::RecommendsImportant "false";
APT::AutoRemove::SuggestsImportant "false";
EOF
    
    # 配置dpkg不处理文档和语言文件
    cat > /etc/dpkg/dpkg.cfg.d/99no-docs << 'EOF'
# 排除文档
path-exclude /usr/share/doc/*
path-exclude /usr/share/man/*
path-exclude /usr/share/groff/*
path-exclude /usr/share/info/*
path-exclude /usr/share/lintian/*
path-exclude /usr/share/linda/*

# 排除语言文件（保留英文）
path-exclude /usr/share/locale/*
path-include /usr/share/locale/en*

# 排除其他不需要的文件
path-exclude /usr/share/help/*
path-exclude /usr/share/gtk-doc/*
path-exclude /usr/share/pixmaps/*
path-exclude /usr/share/icons/*
path-exclude /usr/share/themes/*
path-exclude /usr/share/applications/*
EOF
    
    # 配置系统只保留必要的运行级别
    systemctl set-default multi-user.target 2>/dev/null || true
    
    # 优化内核参数（服务器优化）
    cat > /etc/sysctl.d/99-server-optimize.conf << 'EOF'
# 网络优化
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 65536 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216

# 减少swap使用
vm.swappiness = 10

# 文件系统优化
fs.file-max = 65536
EOF
    
    log "系统配置优化完成"
}

# 显示精简结果
show_results() {
    log "精简完成！系统状态："
    
    echo "磁盘使用情况："
    df -h /
    
    echo
    echo "内存使用情况："
    free -h
    
    echo
    echo "已安装包数量："
    dpkg --get-selections | grep -c "install"
    
    echo
    echo "运行中的服务："
    systemctl list-units --type=service --state=running --no-pager | wc -l
    
    echo
    echo "系统启动目标："
    systemctl get-default
}

# 分析当前系统并生成精简报告
analyze_system() {
    log "分析当前系统状态..."
    
    local total_packages=$(dpkg --get-selections | grep -c "install")
    local removable_count=0
    local size_saved=0
    
    echo "======================================"
    echo "系统精简分析报告"
    echo "======================================"
    echo "当前已安装包数量: $total_packages"
    echo
    
    echo "可移除的包："
    for package in "${PACKAGES_TO_REMOVE[@]}"; do
        if dpkg -l 2>/dev/null | grep -q "^ii.*$package"; then
            if ! is_essential_package "$package"; then
                local pkg_size=$(dpkg-query -Wf '${Installed-Size}' "$package" 2>/dev/null || echo "0")
                echo "  - $package (${pkg_size}KB)"
                ((removable_count++))
                ((size_saved += pkg_size))
            fi
        fi
    done
    
    echo
    echo "预计可移除包数量: $removable_count"
    echo "预计节省空间: $((size_saved / 1024))MB"
    echo
    
    # 检查大型包
    echo "占用空间最大的包（前10个）："
    dpkg-query -Wf '${Installed-Size}\t${Package}\n' | sort -n -r | head -10 | while read size package; do
        echo "  $package: $((size / 1024))MB"
    done
    
    echo "======================================"
}

# 主函数
main() {
    log "Debian系统精简脚本 v$SCRIPT_VERSION"
    
    # 首先分析系统
    analyze_system
    
    echo
    read -p "是否继续执行精简操作？(y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "用户取消精简操作"
        exit 0
    fi
    
    log "开始精简系统..."
    
    # 更新包列表
    apt-get update
    
    # 执行精简操作
    remove_unnecessary_packages
    clean_orphaned_packages
    clean_system_files
    optimize_system_config
    
    # 最终清理
    apt-get autoremove --purge -y
    apt-get autoclean
    
    show_results
    
    log "系统精简完成！"
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi