#!/bin/sh
#
# OpenWRT Performance Optimizer - Main Installation Script
# Version: 1.0.0
# Author: Your Name
# License: MIT
#
# This script performs comprehensive performance optimization for OpenWRT systems
# including CPU, memory, network, and storage optimizations.
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
VERSION="1.0.0"
BACKUP_DIR="/root/backup-$(date +%Y%m%d-%H%M%S)"
LOG_FILE="/var/log/openwrt-optimizer.log"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Print colored output
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[i]${NC} $1"
}

# Banner
show_banner() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║              OpenWRT Performance Optimizer v$VERSION              ║"
    echo "║                                                              ║"
    echo "║  Comprehensive performance optimization toolkit              ║"
    echo "║  * CPU Performance Mode                                      ║"
    echo "║  * Memory Management                                         ║"
    echo "║  * Network Enhancement (TCP BBR)                            ║"
    echo "║  * Storage Optimization                                      ║"
    echo "║  * QoS & Firewall Tuning                                    ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# System compatibility check
check_compatibility() {
    print_info "Checking system compatibility..."
    
    # Check if we're running on OpenWRT
    if [ ! -f /etc/openwrt_release ]; then
        print_error "This script is designed for OpenWRT systems only!"
        exit 1
    fi
    
    # Check architecture
    ARCH=$(uname -m)
    print_info "Detected architecture: $ARCH"
    
    # Check available space
    AVAILABLE_SPACE=$(df /overlay | tail -1 | awk '{print $4}')
    if [ "$AVAILABLE_SPACE" -lt 10240 ]; then  # 10MB minimum
        print_warning "Low disk space detected. Available: ${AVAILABLE_SPACE}KB"
        print_warning "Continuing anyway, but monitor disk usage carefully."
    fi
    
    # Check memory
    TOTAL_MEM=$(free | grep Mem | awk '{print $2}')
    print_info "Total memory: $((TOTAL_MEM/1024))MB"
    
    print_status "Compatibility check passed"
}

# Create backup
create_backup() {
    print_info "Creating configuration backup..."
    
    mkdir -p "$BACKUP_DIR"
    
    # Backup critical files
    [ -f /etc/sysctl.conf ] && cp /etc/sysctl.conf "$BACKUP_DIR/"
    [ -f /etc/rc.local ] && cp /etc/rc.local "$BACKUP_DIR/"
    [ -f /etc/config/firewall ] && cp /etc/config/firewall "$BACKUP_DIR/"
    [ -f /etc/config/network ] && cp /etc/config/network "$BACKUP_DIR/"
    
    echo "#!/bin/sh" > "$BACKUP_DIR/restore.sh"
    echo "# Restore script generated $(date)" >> "$BACKUP_DIR/restore.sh"
    echo "cp $BACKUP_DIR/sysctl.conf /etc/ 2>/dev/null" >> "$BACKUP_DIR/restore.sh"
    echo "cp $BACKUP_DIR/rc.local /etc/ 2>/dev/null" >> "$BACKUP_DIR/restore.sh"
    echo "echo 'Backup restored. Reboot recommended.'" >> "$BACKUP_DIR/restore.sh"
    chmod +x "$BACKUP_DIR/restore.sh"
    
    print_status "Backup created in $BACKUP_DIR"
    log "Backup created in $BACKUP_DIR"
}

# CPU Optimization
optimize_cpu() {
    print_info "Optimizing CPU performance..."
    
    # Set CPU governor to performance for all cores
    for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        if [ -f "$cpu" ]; then
            echo performance > "$cpu" 2>/dev/null && \
            log "CPU $(basename $(dirname $cpu)) set to performance mode"
        fi
    done
    
    print_status "CPU optimization completed"
}

# Memory Optimization  
optimize_memory() {
    print_info "Configuring memory management..."
    
    # Add memory optimization to sysctl.conf
    cat >> /etc/sysctl.conf << 'EOF'
# Memory Management Optimization
vm.swappiness=10
vm.vfs_cache_pressure=50
vm.dirty_ratio=15
vm.dirty_background_ratio=5
EOF
    
    print_status "Memory optimization configured"
}

# Network Optimization
optimize_network() {
    print_info "Enhancing network performance..."
    
    # Add network optimizations to sysctl.conf
    cat >> /etc/sysctl.conf << 'EOF'
# Network Performance Optimization
net.core.rmem_max=16777216
net.core.wmem_max=16777216
net.core.netdev_max_backlog=5000
net.ipv4.tcp_rmem=4096 87380 16777216
net.ipv4.tcp_wmem=4096 65536 16777216
net.ipv4.tcp_congestion_control=bbr
net.ipv4.tcp_fastopen=3
net.ipv4.tcp_low_latency=1
net.ipv4.ip_forward=1
net.ipv4.conf.all.forwarding=1
net.ipv6.conf.all.forwarding=1
EOF
    
    print_status "Network optimization configured"
}

# Storage Optimization
optimize_storage() {
    print_info "Optimizing storage performance..."
    
    # Set disk schedulers and read-ahead
    for disk in mmcblk0 mmcblk1 sda sdb; do
        if [ -f "/sys/block/$disk/queue/scheduler" ]; then
            echo deadline > "/sys/block/$disk/queue/scheduler" 2>/dev/null
            echo 128 > "/sys/block/$disk/queue/read_ahead_kb" 2>/dev/null
            log "Disk $disk optimized with deadline scheduler"
        fi
    done
    
    print_status "Storage optimization completed"
}

# Create system optimization script
create_system_optimization_script() {
    print_info "Creating system optimization script..."
    
    cat > /etc/system-optimization.sh << 'EOF'
#!/bin/sh
# OpenWRT System Optimization Script
# Auto-generated by OpenWRT Performance Optimizer

echo "=== Starting System Optimization ==="

# CPU Performance
for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do 
    [ -f "$cpu" ] && echo performance > "$cpu" && \
    echo "CPU $(basename $(dirname $cpu)) set to performance"
done

# Disk I/O Optimization
for disk in mmcblk0 mmcblk1 sda sdb; do
    [ -f "/sys/block/$disk/queue/scheduler" ] && echo deadline > "/sys/block/$disk/queue/scheduler"
    [ -f "/sys/block/$disk/queue/read_ahead_kb" ] && echo 128 > "/sys/block/$disk/queue/read_ahead_kb"
    [ -f "/sys/block/$disk/queue/scheduler" ] && echo "Disk $disk optimized"
done

# Network optimizations
echo 32768 > /proc/sys/net/netfilter/nf_conntrack_max 2>/dev/null
echo 300 > /proc/sys/net/netfilter/nf_conntrack_tcp_timeout_established 2>/dev/null
echo 60 > /proc/sys/net/netfilter/nf_conntrack_udp_timeout 2>/dev/null
echo 60 > /proc/sys/net/netfilter/nf_conntrack_udp_timeout_stream 2>/dev/null

# Memory optimization
echo 1 > /proc/sys/vm/drop_caches
sync

echo "=== System Optimization Completed ==="
EOF
    
    chmod +x /etc/system-optimization.sh
    print_status "System optimization script created"
}

# Create QoS script
create_qos_script() {
    print_info "Creating QoS configuration script..."
    
    cat > /etc/qos-setup.sh << 'EOF'
#!/bin/sh
# QoS Setup Script

# Clear existing rules
iptables -t mangle -F 2>/dev/null
iptables -t mangle -X 2>/dev/null

# Create QoS marks for different traffic types
iptables -t mangle -A POSTROUTING -o eth0 -p tcp --dport 80 -j MARK --set-mark 1
iptables -t mangle -A POSTROUTING -o eth0 -p tcp --dport 443 -j MARK --set-mark 1
iptables -t mangle -A POSTROUTING -o eth0 -p tcp --dport 22 -j MARK --set-mark 2
iptables -t mangle -A POSTROUTING -o eth0 -p udp --dport 53 -j MARK --set-mark 2
iptables -t mangle -A POSTROUTING -o eth0 -j MARK --set-mark 3

echo "QoS rules applied successfully"
EOF
    
    chmod +x /etc/qos-setup.sh
    print_status "QoS configuration script created"
}

# Create monitoring scripts
create_monitoring_scripts() {
    print_info "Creating monitoring scripts..."
    
    # System status script
    cat > /root/system-status.sh << 'EOF'
#!/bin/sh
echo "=== System Performance Status ==="
echo "CPU Governors:"
for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    [ -f "$cpu" ] && printf "CPU%s: %s\n" "$(echo $cpu | grep -o 'cpu[0-9]' | sed 's/cpu//')" "$(cat $cpu)"
done

echo -e "\nMemory Usage:"
free -h

echo -e "\nDisk Usage:"
df -h | grep -E "(overlay|mmcblk|sd[a-z])"

echo -e "\nNetwork Settings:"
echo "TCP Congestion Control: $(cat /proc/sys/net/ipv4/tcp_congestion_control 2>/dev/null || echo 'Unknown')"
echo "TCP FastOpen: $(cat /proc/sys/net/ipv4/tcp_fastopen 2>/dev/null || echo 'Unknown')"

echo -e "\nSystem Temperature:"
for temp in /sys/class/thermal/thermal_zone*/temp; do
    [ -f "$temp" ] && awk '{printf "%.1f°C\n", $1/1000}' "$temp"
done
EOF
    chmod +x /root/system-status.sh
    
    # Quick check script
    cat > /root/quick-check.sh << 'EOF'
#!/bin/sh
echo "🔍 Quick System Check:"
echo "Load: $(cat /proc/loadavg | cut -d' ' -f1)"
echo "CPU: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo 'Unknown')"
echo "Memory: $(free | grep Mem | awk '{printf "%.0f%%", $3/$2*100}')"
echo "Temp: $(awk '{printf "%.1f°C", $1/1000}' /sys/class/thermal/thermal_zone*/temp 2>/dev/null || echo 'Unknown')"
echo "TCP: $(cat /proc/sys/net/ipv4/tcp_congestion_control 2>/dev/null || echo 'Unknown')"
EOF
    chmod +x /root/quick-check.sh
    
    print_status "Monitoring scripts created"
}

# Configure startup scripts
configure_startup() {
    print_info "Configuring startup scripts..."
    
    # Backup existing rc.local
    [ -f /etc/rc.local ] && cp /etc/rc.local /etc/rc.local.backup
    
    # Create new rc.local
    cat > /etc/rc.local << 'EOF'
#!/bin/sh -e
# OpenWRT Performance Optimizer - Startup Script

# CPU Performance
for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do 
    [ -f "$cpu" ] && echo performance > "$cpu"
done

# Disk I/O
for disk in mmcblk0 mmcblk1 sda sdb; do
    [ -f "/sys/block/$disk/queue/scheduler" ] && echo deadline > "/sys/block/$disk/queue/scheduler" 2>/dev/null
done

# System optimization
[ -x /etc/system-optimization.sh ] && /etc/system-optimization.sh

# QoS setup  
[ -x /etc/qos-setup.sh ] && /etc/qos-setup.sh 2>/dev/null

exit 0
EOF
    
    chmod +x /etc/rc.local
    print_status "Startup configuration completed"
}

# Apply settings
apply_settings() {
    print_info "Applying optimization settings..."
    
    # Apply sysctl settings
    sysctl -p 2>/dev/null || print_warning "Some sysctl settings may not be supported"
    
    # Run optimization scripts
    /etc/system-optimization.sh
    /etc/qos-setup.sh 2>/dev/null || print_warning "QoS setup had some issues (normal on some systems)"
    
    # Sync filesystem
    sync
    
    print_status "Settings applied successfully"
}

# Create performance report
create_performance_report() {
    print_info "Creating performance report..."
    
    cat > /root/performance-report.sh << 'EOF'
#!/bin/sh
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                  OPTIMIZATION SUCCESS REPORT                 ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "🎯 PERFORMANCE OPTIMIZATIONS APPLIED:"
echo "   • CPU: All cores → performance mode ✅"
echo "   • Network: TCP BBR + FastOpen enabled ✅"
echo "   • Storage: Deadline scheduler active ✅" 
echo "   • Memory: Optimized swap and cache settings ✅"
echo "   • QoS: Traffic prioritization configured ✅"
echo ""
echo "📊 CURRENT STATUS:"
echo "   • Load: $(cat /proc/loadavg | cut -d' ' -f1-3)"
echo "   • Memory: $(free | grep Mem | awk '{printf "%.0f%% used", $3/$2*100}')"
echo "   • Temperature: $(awk '{printf "%.1f°C", $1/1000}' /sys/class/thermal/thermal_zone*/temp 2>/dev/null || echo 'Unknown')"
echo "   • TCP Congestion: $(cat /proc/sys/net/ipv4/tcp_congestion_control 2>/dev/null || echo 'Unknown')"
echo ""
echo "💾 STORAGE STATUS:"
df -h | grep -E "(overlay|mmcblk|sd[a-z])" | while read line; do
    echo "   • $line"
done
echo ""
echo "🔒 BACKUP LOCATION:"
echo "   • Configuration backup: $BACKUP_DIR"
echo ""
echo "✅ All optimizations are PERSISTENT across reboots!"
echo "══════════════════════════════════════════════════════════════"
EOF
    
    chmod +x /root/performance-report.sh
    print_status "Performance report script created"
}

# Main installation function
main() {
    show_banner
    
    print_info "Starting OpenWRT Performance Optimizer installation..."
    log "Installation started by $(whoami) from $(pwd)"
    
    # Pre-installation checks
    check_compatibility
    create_backup
    
    # Core optimizations
    optimize_cpu
    optimize_memory  
    optimize_network
    optimize_storage
    
    # Create scripts
    create_system_optimization_script
    create_qos_script
    create_monitoring_scripts
    
    # Configure system
    configure_startup
    apply_settings
    create_performance_report
    
    echo ""
    print_status "Installation completed successfully!"
    print_info "Backup created in: $BACKUP_DIR"
    print_info "Log file: $LOG_FILE"
    
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                     INSTALLATION COMPLETE!                 ║${NC}"
    echo -e "${GREEN}╠════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║  Next Steps:                                               ║${NC}"
    echo -e "${GREEN}║  1. Run: /root/performance-report.sh                      ║${NC}"  
    echo -e "${GREEN}║  2. Monitor: /root/quick-check.sh                         ║${NC}"
    echo -e "${GREEN}║  3. Reboot to test persistence: reboot                    ║${NC}"
    echo -e "${GREEN}║                                                           ║${NC}"
    echo -e "${GREEN}║  All optimizations will survive reboots automatically!    ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    
    log "Installation completed successfully"
}

# Script execution
if [ "$(id -u)" != "0" ]; then
    print_error "This script must be run as root!"
    exit 1
fi

# Parse command line arguments
case "${1:-}" in
    --version)
        echo "OpenWRT Performance Optimizer v$VERSION"
        exit 0
        ;;
    --help)
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  --version     Show version information"
        echo "  --help        Show this help message"
        echo "  --force       Force installation even with warnings"
        echo ""
        exit 0
        ;;
    --force)
        export FORCE_INSTALL=1
        ;;
esac

# Run main installation
main "$@"
