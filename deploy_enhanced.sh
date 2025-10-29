#!/bin/bash

# 增强版gRPC接收器部署脚本
# Enhanced gRPC Receiver Deployment Script

set -e

echo "🚀 开始部署增强版gRPC接收器到awsserver..."
echo "🚀 Deploying Enhanced gRPC Receiver to awsserver..."

# 检查参数
if [ $# -eq 0 ]; then
    echo "❌ 请提供awsserver的SSH连接信息"
    echo "❌ Please provide awsserver SSH connection info"
    echo "用法: $0 <ssh_user@host>"
    echo "Usage: $0 <ssh_user@host>"
    exit 1
fi

AWSSERVER="$1"
LOCAL_BINARY="./grpc_receiver_enhanced_v2"
REMOTE_DIR="/opt/nezha-agent"
CONFIG_FILE="config.example.json"

# 检查本地文件
if [ ! -f "$LOCAL_BINARY" ]; then
    echo "❌ 本地二进制文件不存在: $LOCAL_BINARY"
    echo "❌ Local binary file not found: $LOCAL_BINARY"
    echo "请先运行构建脚本: ./build_enhanced.sh"
    echo "Please run build script first: ./build_enhanced.sh"
    exit 1
fi

if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ 配置文件不存在: $CONFIG_FILE"
    echo "❌ Config file not found: $CONFIG_FILE"
    exit 1
fi

echo "📦 准备部署文件..."
echo "📦 Preparing deployment files..."

# 创建临时目录
TEMP_DIR=$(mktemp -d)
echo "📁 临时目录: $TEMP_DIR"
echo "📁 Temp directory: $TEMP_DIR"

# 复制文件到临时目录
cp "$LOCAL_BINARY" "$TEMP_DIR/"
cp "$CONFIG_FILE" "$TEMP_DIR/config.json"

echo "📤 上传文件到awsserver..."
echo "📤 Uploading files to awsserver..."

# 上传文件
scp "$TEMP_DIR/grpc_receiver_enhanced_v2" "$AWSSERVER:/tmp/"
scp "$TEMP_DIR/config.json" "$AWSSERVER:/tmp/"

echo "🔧 在awsserver上配置服务..."
echo "🔧 Configuring service on awsserver..."

# 在awsserver上执行部署命令
ssh "$AWSSERVER" << 'EOF'
set -e

echo "🛑 停止旧服务..."
echo "🛑 Stopping old service..."
sudo systemctl stop nezha-agent-receiver || true

echo "📁 备份旧文件..."
echo "📁 Backing up old files..."
sudo cp /opt/nezha-agent/grpc_receiver /opt/nezha-agent/grpc_receiver.backup.$(date +%Y%m%d_%H%M%S) || true

echo "📋 安装新文件..."
echo "📋 Installing new files..."
sudo mv /tmp/grpc_receiver_enhanced_v2 /opt/nezha-agent/grpc_receiver
sudo chmod +x /opt/nezha-agent/grpc_receiver

echo "⚙️ 配置服务..."
echo "⚙️ Configuring service..."

# 更新systemd服务配置
sudo tee /etc/systemd/system/nezha-agent-receiver.service > /dev/null << 'SERVICE_EOF'
[Unit]
Description=Nezha Agent Receiver Enhanced
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/nezha-agent
ExecStart=/opt/nezha-agent/grpc_receiver -config /opt/nezha-agent/config.json
Restart=always
RestartSec=5
Environment=GOOS=linux
Environment=GOARCH=amd64

# 资源限制
LimitNOFILE=65536
LimitNPROC=32768

# 安全设置
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/nezha-agent

[Install]
WantedBy=multi-user.target
SERVICE_EOF

echo "📄 安装配置文件..."
echo "📄 Installing config file..."
sudo mv /tmp/config.json /opt/nezha-agent/

echo "🔄 重新加载systemd配置..."
echo "🔄 Reloading systemd configuration..."
sudo systemctl daemon-reload

echo "✅ 部署完成！"
echo "✅ Deployment completed!"

echo ""
echo "🎯 增强功能已部署:"
echo "🎯 Enhanced features deployed:"
echo "  ✅ 配置热重载 (Config Hot Reload)"
echo "  ✅ 数据压缩 (Data Compression)"
echo "  ✅ Redis缓存 (Redis Cache)"
echo "  ✅ Prometheus指标 (Prometheus Metrics)"
echo "  ✅ Telegram告警 (Telegram Alerts)"
echo "  ✅ 并发优化 (Concurrency Optimization)"
echo "  ✅ 批量处理 (Batch Processing)"
echo "  ✅ 健康检查 (Health Checks)"
echo "  ✅ 统计信息 (Statistics)"

echo ""
echo "📋 下一步操作:"
echo "📋 Next steps:"
echo "  1. 编辑配置文件: sudo nano /opt/nezha-agent/config.json"
echo "  1. Edit config file: sudo nano /opt/nezha-agent/config.json"
echo "  2. 启动服务: sudo systemctl start nezha-agent-receiver"
echo "  2. Start service: sudo systemctl start nezha-agent-receiver"
echo "  3. 检查状态: sudo systemctl status nezha-agent-receiver"
echo "  3. Check status: sudo systemctl status nezha-agent-receiver"
echo "  4. 查看日志: sudo journalctl -u nezha-agent-receiver -f"
echo "  4. View logs: sudo journalctl -u nezha-agent-receiver -f"

echo ""
echo "🔗 API端点:"
echo "🔗 API Endpoints:"
echo "  • 健康检查: http://localhost:8081/api/v1/health"
echo "  • Health check: http://localhost:8081/api/v1/health"
echo "  • Agent列表: http://localhost:8081/api/v1/agents"
echo "  • Agent list: http://localhost:8081/api/v1/agents"
echo "  • 统计信息: http://localhost:8081/api/v1/agents/stats"
echo "  • Statistics: http://localhost:8081/api/v1/agents/stats"
echo "  • Prometheus指标: http://localhost:9090/metrics"
echo "  • Prometheus metrics: http://localhost:9090/metrics"

EOF

# 清理临时目录
rm -rf "$TEMP_DIR"

echo ""
echo "🎉 部署完成！"
echo "🎉 Deployment completed!"
echo ""
echo "📋 后续配置步骤:"
echo "📋 Post-deployment configuration steps:"
echo "  1. SSH到awsserver: ssh $AWSSERVER"
echo "  1. SSH to awsserver: ssh $AWSSERVER"
echo "  2. 编辑配置文件: sudo nano /opt/nezha-agent/config.json"
echo "  2. Edit config file: sudo nano /opt/nezha-agent/config.json"
echo "  3. 配置Redis连接信息"
echo "  3. Configure Redis connection info"
echo "  4. 配置Telegram Bot Token和Chat ID"
echo "  4. Configure Telegram Bot Token and Chat ID"
echo "  5. 启动服务: sudo systemctl start nezha-agent-receiver"
echo "  5. Start service: sudo systemctl start nezha-agent-receiver"
echo "  6. 启用自启动: sudo systemctl enable nezha-agent-receiver"
echo "  6. Enable auto-start: sudo systemctl enable nezha-agent-receiver"
echo ""
echo "🔍 监控和调试:"
echo "🔍 Monitoring and debugging:"
echo "  • 服务状态: sudo systemctl status nezha-agent-receiver"
echo "  • Service status: sudo systemctl status nezha-agent-receiver"
echo "  • 实时日志: sudo journalctl -u nezha-agent-receiver -f"
echo "  • Real-time logs: sudo journalctl -u nezha-agent-receiver -f"
echo "  • 健康检查: curl -H 'X-API-Key: YOUR_KEY' http://localhost:8081/api/v1/health"
echo "  • Health check: curl -H 'X-API-Key: YOUR_KEY' http://localhost:8081/api/v1/health"
echo "  • Prometheus指标: curl http://localhost:9090/metrics"
echo "  • Prometheus metrics: curl http://localhost:9090/metrics"

