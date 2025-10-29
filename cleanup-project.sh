#!/bin/bash

# =============================================================================
# Agent 项目清理脚本
# 删除不需要的文件，保留核心功能
# =============================================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 要删除的文件和目录
FILES_TO_DELETE=(
    # 旧的部署脚本
    "deploy.sh"
    "deploy-vps-fast.sh"
    "deploy-vps-overseas.sh"
    "quick-docker.sh"
    "run-local.sh"
    "build-for-vps.sh"
    "deploy-complete.sh"
    "deploy-agent-to-vps.sh"
    "vps-setup.sh"
    "one-click-deploy.sh"
    "update-all-scripts.sh"
    "update-receiver.sh"
    "update-nginx-config.sh"
    "secure-vps.sh"
    "port-config.sh"
    "configure-api-key.sh"
    "test_security.sh"
    "deploy_secure.sh"
    "uninstall.sh"
    
    # Docker 相关
    "docker-build.sh"
    "docker-compose.yml"
    "Dockerfile"
    "Dockerfile.light"
    "nginx.conf"
    
    # 文档
    "DEPLOYMENT_GUIDE.md"
    "README_AGENT_DEPLOYMENT.md"
    "README_RECEIVER.md"
    "SCRIPT_EXPLANATION.md"
    "VPS_DEPLOYMENT_GUIDE.md"
    "MULTI_VPS_DEPLOYMENT.md"
    "API_TOKEN_CONFIG.md"
    
    # 配置文件
    "config.example"
    "agent-config-template.yml"
    "multi-vps-agent-config.yml"
    "nginx-agent-proxy.conf"
    
    # 示例和测试
    "api_client_example.py"
    "test_security.sh"
    
    # 构建产物
    "grpc_receiver"
    "vps-deploy"
    "vps-deploy-*.tar.gz"
    "agent-connect-*.tar.gz"
    
    # 脚本目录
    "scripts"
    "workers"
    
    # 文档目录
    "docs"
)

# 要保留的核心文件
CORE_FILES=(
    "cmd/"
    "model/"
    "pkg/"
    "proto/"
    "go.mod"
    "go.sum"
    "LICENSE"
    "README.md"
    "connect-to-main.sh"
    "simple-connect.sh"
    "custom-connect.sh"
    "one-line-install.sh"
    "create-deployment-package.sh"
    "cleanup-project.sh"
)

log_info "开始清理 Agent 项目..."

# 显示要删除的文件
log_info "将要删除的文件和目录:"
for file in "${FILES_TO_DELETE[@]}"; do
    if [ -e "$file" ]; then
        echo "  - $file"
    fi
done

# 确认删除
echo
read -p "确认删除这些文件吗？(y/N): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    log_info "取消清理操作"
    exit 0
fi

# 删除文件
log_info "删除文件..."
for file in "${FILES_TO_DELETE[@]}"; do
    if [ -e "$file" ]; then
        if [ -d "$file" ]; then
            rm -rf "$file"
            log_info "删除目录: $file"
        else
            rm -f "$file"
            log_info "删除文件: $file"
        fi
    fi
done

# 清理构建产物
log_info "清理构建产物..."
find . -name "*.exe" -delete 2>/dev/null || true
find . -name "*.dll" -delete 2>/dev/null || true
find . -name "*.so" -delete 2>/dev/null || true
find . -name "*.dylib" -delete 2>/dev/null || true
find . -name "*.a" -delete 2>/dev/null || true
find . -name "*.o" -delete 2>/dev/null || true
find . -name "*.test" -delete 2>/dev/null || true
find . -name "*.out" -delete 2>/dev/null || true
find . -name "*.log" -delete 2>/dev/null || true
find . -name ".DS_Store" -delete 2>/dev/null || true
find . -name "Thumbs.db" -delete 2>/dev/null || true

# 清理 Go 模块缓存
log_info "清理 Go 模块缓存..."
go clean -cache 2>/dev/null || true
go clean -modcache 2>/dev/null || true

# 显示清理结果
log_success "项目清理完成！"
echo
echo "保留的核心文件:"
for file in "${CORE_FILES[@]}"; do
    if [ -e "$file" ]; then
        echo "  ✓ $file"
    fi
done

echo
echo "当前项目结构:"
ls -la

echo
log_success "Agent 项目已清理完成！"
echo
echo "现在你可以使用以下脚本在其他 VPS 上部署 Agent:"
echo "1. connect-to-main.sh    - 完整版连接脚本"
echo "2. simple-connect.sh     - 简化版连接脚本"
echo "3. custom-connect.sh     - 自定义编译脚本"
echo "4. one-line-install.sh   - 一行安装脚本"
echo
echo "或者创建部署包:"
echo "  ./create-deployment-package.sh"


