#!/bin/bash

# =============================================================================
# Agent 连接到主接收器的一键部署脚本
# 目标：连接到 ag1nt.lambdax.me 的主 Agent 接收器
# =============================================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
MAIN_RECEIVER_URL="ag1nt.lambdax.me"
MAIN_RECEIVER_PORT="443"
MAIN_RECEIVER_GRPC_PATH="/grpc"
API_KEY="${AGENT_API_KEY:-your_agent_api_key_here}"
AGENT_NAME="Agent-$(hostname)"
AGENT_VERSION="v0.1.0"

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查系统
check_system() {
    log_info "检查系统环境..."
    
    # 检查操作系统
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="darwin"
    else
        log_error "不支持的操作系统: $OSTYPE"
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
    
    log_success "系统检查通过: $OS-$ARCH"
}

# 安装依赖
install_dependencies() {
    log_info "安装系统依赖..."
    
    if command -v apt-get &> /dev/null; then
        # Ubuntu/Debian
        sudo apt-get update
        sudo apt-get install -y wget curl unzip
    elif command -v yum &> /dev/null; then
        # CentOS/RHEL
        sudo yum update -y
        sudo yum install -y wget curl unzip
    elif command -v dnf &> /dev/null; then
        # Fedora
        sudo dnf update -y
        sudo dnf install -y wget curl unzip
    else
        log_warning "无法自动安装依赖，请手动安装 wget, curl, unzip"
    fi
    
    log_success "依赖安装完成"
}

# 下载 Agent 二进制文件
download_agent() {
    log_info "下载 Agent 二进制文件..."
    
    # 创建临时目录
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    # 下载预编译的二进制文件
    BINARY_URL="https://github.com/naiba/nezha/releases/latest/download/nezha-agent_${OS}_${ARCH}.zip"
    
    log_info "从 GitHub 下载: $BINARY_URL"
    if ! wget -q "$BINARY_URL" -O nezha-agent.zip; then
        log_error "下载失败，尝试备用方案..."
        # 备用下载方案
        BINARY_URL="https://github.com/naiba/nezha/releases/download/v0.15.6/nezha-agent_${OS}_${ARCH}.zip"
        wget -q "$BINARY_URL" -O nezha-agent.zip || {
            log_error "备用下载也失败"
            exit 1
        }
    fi
    
    # 解压
    unzip -q nezha-agent.zip
    chmod +x nezha-agent
    
    # 移动到系统目录
    sudo mv nezha-agent /usr/local/bin/
    
    # 清理
    cd /
    rm -rf "$TEMP_DIR"
    
    log_success "Agent 二进制文件安装完成"
}

# 创建配置文件
create_config() {
    log_info "创建配置文件..."
    
    CONFIG_FILE="/etc/nezha-agent.yaml"
    
    cat > /tmp/nezha-agent.yaml << EOF
# Nezha Agent 配置文件
# 连接到主接收器: $MAIN_RECEIVER_URL

# 服务器配置
server: $MAIN_RECEIVER_URL:$MAIN_RECEIVER_PORT$MAIN_RECEIVER_GRPC_PATH
tls: true

# Agent 配置
client_secret: $API_KEY
hostname: $AGENT_NAME
version: $AGENT_VERSION

# 监控配置
monitor:
  # 系统监控
  system: true
  # 网络监控
  network: true
  # 进程监控
  process: true
  # GPU 监控
  gpu: false

# 日志配置
log:
  level: info
  file: /var/log/nezha-agent.log

# 上报间隔（秒）
report_interval: 10
EOF

    sudo mv /tmp/nezha-agent.yaml "$CONFIG_FILE"
    sudo chmod 600 "$CONFIG_FILE"
    
    log_success "配置文件创建完成: $CONFIG_FILE"
}

# 创建 systemd 服务
create_service() {
    log_info "创建 systemd 服务..."
    
    SERVICE_FILE="/etc/systemd/system/nezha-agent.service"
    
    cat > /tmp/nezha-agent.service << EOF
[Unit]
Description=Nezha Agent
Documentation=https://github.com/naiba/nezha
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/nezha-agent -c $CONFIG_FILE
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

# 安全配置
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/log

[Install]
WantedBy=multi-user.target
EOF

    sudo mv /tmp/nezha-agent.service "$SERVICE_FILE"
    sudo systemctl daemon-reload
    sudo systemctl enable nezha-agent
    
    log_success "systemd 服务创建完成"
}

# 启动服务
start_service() {
    log_info "启动 Agent 服务..."
    
    sudo systemctl start nezha-agent
    
    # 等待服务启动
    sleep 3
    
    if sudo systemctl is-active --quiet nezha-agent; then
        log_success "Agent 服务启动成功"
    else
        log_error "Agent 服务启动失败"
        sudo systemctl status nezha-agent
        exit 1
    fi
}

# 验证连接
verify_connection() {
    log_info "验证连接状态..."
    
    # 等待一段时间让 Agent 连接
    sleep 10
    
    # 检查服务状态
    if sudo systemctl is-active --quiet nezha-agent; then
        log_success "Agent 服务运行正常"
    else
        log_error "Agent 服务未运行"
        return 1
    fi
    
    # 检查日志
    log_info "最近的日志:"
    sudo journalctl -u nezha-agent --no-pager -n 10
    
    log_success "连接验证完成"
}

# 显示状态信息
show_status() {
    log_info "=== 部署完成 ==="
    echo
    echo "Agent 名称: $AGENT_NAME"
    echo "连接到: $MAIN_RECEIVER_URL:$MAIN_RECEIVER_PORT$MAIN_RECEIVER_GRPC_PATH"
    echo "配置文件: /etc/nezha-agent.yaml"
    echo "服务状态: $(sudo systemctl is-active nezha-agent)"
    echo
    echo "常用命令:"
    echo "  查看状态: sudo systemctl status nezha-agent"
    echo "  查看日志: sudo journalctl -u nezha-agent -f"
    echo "  重启服务: sudo systemctl restart nezha-agent"
    echo "  停止服务: sudo systemctl stop nezha-agent"
    echo
    log_success "Agent 已成功连接到主接收器！"
}

# 主函数
main() {
    echo "=========================================="
    echo "  Nezha Agent 连接到主接收器"
    echo "  目标: $MAIN_RECEIVER_URL"
    echo "=========================================="
    echo
    
    check_system
    install_dependencies
    download_agent
    create_config
    create_service
    start_service
    verify_connection
    show_status
}

# 运行主函数
main "$@"
