#!/bin/bash

# =============================================================================
# 简化版 Agent 连接脚本
# 使用我们自己的 Agent 实现连接到 ag1nt.lambdax.me
# =============================================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 配置
MAIN_RECEIVER_URL="ag1nt.lambdax.me"
MAIN_RECEIVER_PORT="443"
MAIN_RECEIVER_GRPC_PATH="/grpc"
API_KEY="${AGENT_API_KEY:-your_agent_api_key_here}"
AGENT_NAME="Agent-$(hostname)"

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 检查系统
check_system() {
    log_info "检查系统环境..."
    
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        log_error "此脚本仅支持 Linux 系统"
        exit 1
    fi
    
    # 检查架构
    ARCH=$(uname -m)
    case $ARCH in
        x86_64) ARCH="amd64" ;;
        arm64|aarch64) ARCH="arm64" ;;
        armv7l) ARCH="arm" ;;
        *) log_error "不支持的架构: $ARCH"; exit 1 ;;
    esac
    
    log_success "系统检查通过: Linux-$ARCH"
}

# 安装依赖
install_dependencies() {
    log_info "安装系统依赖..."
    
    if command -v apt-get &> /dev/null; then
        sudo apt-get update
        sudo apt-get install -y wget curl
    elif command -v yum &> /dev/null; then
        sudo yum update -y
        sudo yum install -y wget curl
    elif command -v dnf &> /dev/null; then
        sudo dnf update -y
        sudo dnf install -y wget curl
    else
        log_warning "无法自动安装依赖，请手动安装 wget, curl"
    fi
    
    log_success "依赖安装完成"
}

# 下载预编译的 Agent
download_agent() {
    log_info "下载预编译的 Agent..."
    
    # 创建目录
    sudo mkdir -p /opt/nezha-agent
    cd /opt/nezha-agent
    
    # 下载预编译的二进制文件
    BINARY_URL="https://github.com/naiba/nezha/releases/latest/download/nezha-agent_linux_${ARCH}"
    
    log_info "下载: $BINARY_URL"
    if ! sudo wget -q "$BINARY_URL" -O nezha-agent; then
        log_error "下载失败，尝试备用方案..."
        BINARY_URL="https://github.com/naiba/nezha/releases/download/v0.15.6/nezha-agent_linux_${ARCH}"
        sudo wget -q "$BINARY_URL" -O nezha-agent || {
            log_error "下载失败，请检查网络连接"
            exit 1
        }
    fi
    
    sudo chmod +x nezha-agent
    sudo ln -sf /opt/nezha-agent/nezha-agent /usr/local/bin/nezha-agent
    
    log_success "Agent 下载完成"
}

# 创建配置文件
create_config() {
    log_info "创建配置文件..."
    
    CONFIG_FILE="/opt/nezha-agent/config.yaml"
    
    sudo tee "$CONFIG_FILE" > /dev/null << EOF
# Nezha Agent 配置文件
# 连接到主接收器: $MAIN_RECEIVER_URL

server: $MAIN_RECEIVER_URL:$MAIN_RECEIVER_PORT$MAIN_RECEIVER_GRPC_PATH
tls: true
client_secret: $API_KEY
hostname: $AGENT_NAME
EOF

    sudo chmod 600 "$CONFIG_FILE"
    log_success "配置文件创建完成"
}

# 创建 systemd 服务
create_service() {
    log_info "创建 systemd 服务..."
    
    sudo tee /etc/systemd/system/nezha-agent.service > /dev/null << EOF
[Unit]
Description=Nezha Agent
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/nezha-agent -c /opt/nezha-agent/config.yaml
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable nezha-agent
    
    log_success "systemd 服务创建完成"
}

# 启动服务
start_service() {
    log_info "启动 Agent 服务..."
    
    sudo systemctl start nezha-agent
    sleep 3
    
    if sudo systemctl is-active --quiet nezha-agent; then
        log_success "Agent 服务启动成功"
    else
        log_error "Agent 服务启动失败"
        sudo systemctl status nezha-agent
        exit 1
    fi
}

# 显示状态
show_status() {
    log_info "=== 部署完成 ==="
    echo
    echo "Agent 名称: $AGENT_NAME"
    echo "连接到: $MAIN_RECEIVER_URL:$MAIN_RECEIVER_PORT$MAIN_RECEIVER_GRPC_PATH"
    echo "配置文件: /opt/nezha-agent/config.yaml"
    echo "服务状态: $(sudo systemctl is-active nezha-agent)"
    echo
    echo "常用命令:"
    echo "  查看状态: sudo systemctl status nezha-agent"
    echo "  查看日志: sudo journalctl -u nezha-agent -f"
    echo "  重启服务: sudo systemctl restart nezha-agent"
    echo
    log_success "Agent 已成功连接到主接收器！"
}

# 主函数
main() {
    echo "=========================================="
    echo "  Nezha Agent 快速连接脚本"
    echo "  目标: $MAIN_RECEIVER_URL"
    echo "=========================================="
    echo
    
    check_system
    install_dependencies
    download_agent
    create_config
    create_service
    start_service
    show_status
}

# 运行主函数
main "$@"
