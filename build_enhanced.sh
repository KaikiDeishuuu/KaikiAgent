#!/bin/bash

# 增强版gRPC接收器构建脚本
# Enhanced gRPC Receiver Build Script

set -e

echo "🚀 开始构建增强版gRPC接收器..."
echo "🚀 Building Enhanced gRPC Receiver..."

# 检查Go环境
if ! command -v go &> /dev/null; then
    echo "❌ Go未安装，请先安装Go"
    echo "❌ Go not installed, please install Go first"
    exit 1
fi

# 设置环境变量
export GOOS=linux
export GOARCH=amd64
export CGO_ENABLED=1

# 进入项目目录
cd "$(dirname "$0")"

echo "📦 下载依赖..."
echo "📦 Downloading dependencies..."
go mod tidy
go mod download

echo "🔨 编译增强版gRPC接收器..."
echo "🔨 Building Enhanced gRPC Receiver..."

# 编译主程序
go build -ldflags="-s -w" -o grpc_receiver_enhanced_v2 ./cmd/grpc_receiver/

if [ $? -eq 0 ]; then
    echo "✅ 构建成功！"
    echo "✅ Build successful!"
    echo "📁 输出文件: grpc_receiver_enhanced_v2"
    echo "📁 Output file: grpc_receiver_enhanced_v2"
    
    # 显示文件信息
    ls -lh grpc_receiver_enhanced_v2
    
    echo ""
    echo "🎯 新功能特性:"
    echo "🎯 New Features:"
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
    echo "📋 使用方法:"
    echo "📋 Usage:"
    echo "  ./grpc_receiver_enhanced_v2 -config config.json"
    echo "  ./grpc_receiver_enhanced_v2 -listen :50051 -api-listen :8081 -api-key YOUR_KEY"
    
    echo ""
    echo "🔧 配置文件示例:"
    echo "🔧 Config file example:"
    echo "  cp config.example.json config.json"
    echo "  # 编辑配置文件"
    echo "  # Edit config file"
    echo "  nano config.json"
    
else
    echo "❌ 构建失败！"
    echo "❌ Build failed!"
    exit 1
fi

