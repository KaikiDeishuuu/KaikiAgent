#!/bin/bash

# =============================================================================
# 创建 Agent 连接部署包
# 包含所有必要的脚本和配置文件
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
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 创建部署包目录
PACKAGE_DIR="agent-connect-package"
PACKAGE_NAME="agent-connect-$(date +%Y%m%d-%H%M%S).tar.gz"

log_info "创建部署包目录: $PACKAGE_DIR"
rm -rf "$PACKAGE_DIR"
mkdir -p "$PACKAGE_DIR"

# 复制脚本文件
log_info "复制脚本文件..."
cp connect-to-main.sh "$PACKAGE_DIR/"
cp simple-connect.sh "$PACKAGE_DIR/"
cp custom-connect.sh "$PACKAGE_DIR/"

# 创建 README
log_info "创建 README..."
cat > "$PACKAGE_DIR/README.md" << 'EOF'
# Agent 连接部署包

这个部署包包含了连接到 `your-agent-server.com` 主接收器的所有必要脚本。

## 包含的脚本

1. **connect-to-main.sh** - 完整版连接脚本（推荐）
   - 自动下载预编译的 Nezha Agent
   - 自动安装依赖和配置服务
   - 支持多种 Linux 发行版

2. **simple-connect.sh** - 简化版连接脚本
   - 快速部署，最小依赖
   - 适合快速测试

3. **custom-connect.sh** - 自定义编译脚本
   - 从源码编译 Agent
   - 适合需要自定义配置的场景

## 使用方法

### 方法一：一键部署（推荐）

```bash
# 下载并运行
curl -fsSL https://raw.githubusercontent.com/your-repo/agent-connect-package/main/connect-to-main.sh | bash

# 或者下载后运行
wget https://raw.githubusercontent.com/your-repo/agent-connect-package/main/connect-to-main.sh
chmod +x connect-to-main.sh
sudo ./connect-to-main.sh
```

### 方法二：使用部署包

```bash
# 解压部署包
tar -xzf agent-connect-*.tar.gz
cd agent-connect-package

# 选择并运行脚本
sudo ./connect-to-main.sh    # 推荐
# 或
sudo ./simple-connect.sh     # 简化版
# 或
sudo ./custom-connect.sh     # 自定义编译
```

## 配置说明

- **主接收器地址**: your-agent-server.com:443
- **API 密钥**: \${AGENT_API_KEY:-your_agent_api_key_here}
- **Agent 名称**: Agent-{主机名}
- **TLS 加密**: 启用

## 服务管理

```bash
# 查看状态
sudo systemctl status nezha-agent

# 查看日志
sudo journalctl -u nezha-agent -f

# 重启服务
sudo systemctl restart nezha-agent

# 停止服务
sudo systemctl stop nezha-agent
```

## 故障排除

1. **连接失败**: 检查网络连接和防火墙设置
2. **服务启动失败**: 查看日志 `sudo journalctl -u nezha-agent`
3. **权限问题**: 确保以 root 权限运行脚本

## 支持的系统

- Ubuntu 18.04+
- Debian 9+
- CentOS 7+
- RHEL 7+
- Fedora 30+

## 支持的架构

- x86_64 (amd64)
- arm64 (aarch64)
- armv7l (arm)
EOF

# 创建快速安装脚本
log_info "创建快速安装脚本..."
cat > "$PACKAGE_DIR/install.sh" << 'EOF'
#!/bin/bash

# 快速安装脚本
echo "=========================================="
echo "  Agent 连接快速安装"
echo "=========================================="
echo

# 检查权限
if [ "$EUID" -ne 0 ]; then
    echo "请使用 sudo 运行此脚本"
    exit 1
fi

# 选择安装方式
echo "请选择安装方式:"
echo "1) 完整版 (推荐) - 自动下载预编译 Agent"
echo "2) 简化版 - 快速部署"
echo "3) 自定义编译 - 从源码编译"
echo
read -p "请输入选择 (1-3): " choice

case $choice in
    1)
        echo "运行完整版安装..."
        ./connect-to-main.sh
        ;;
    2)
        echo "运行简化版安装..."
        ./simple-connect.sh
        ;;
    3)
        echo "运行自定义编译安装..."
        ./custom-connect.sh
        ;;
    *)
        echo "无效选择，退出"
        exit 1
        ;;
esac
EOF

chmod +x "$PACKAGE_DIR/install.sh"

# 创建卸载脚本
log_info "创建卸载脚本..."
cat > "$PACKAGE_DIR/uninstall.sh" << 'EOF'
#!/bin/bash

# Agent 卸载脚本
echo "=========================================="
echo "  Agent 卸载脚本"
echo "=========================================="
echo

# 检查权限
if [ "$EUID" -ne 0 ]; then
    echo "请使用 sudo 运行此脚本"
    exit 1
fi

echo "停止 Agent 服务..."
systemctl stop nezha-agent 2>/dev/null || true
systemctl disable nezha-agent 2>/dev/null || true

echo "删除服务文件..."
rm -f /etc/systemd/system/nezha-agent.service
systemctl daemon-reload

echo "删除配置文件..."
rm -rf /opt/nezha-agent

echo "删除二进制文件..."
rm -f /usr/local/bin/nezha-agent

echo "清理日志..."
journalctl --vacuum-time=1d >/dev/null 2>&1 || true

echo "卸载完成！"
EOF

chmod +x "$PACKAGE_DIR/uninstall.sh"

# 创建配置文件模板
log_info "创建配置文件模板..."
cat > "$PACKAGE_DIR/config-template.yaml" << 'EOF'
# Nezha Agent 配置文件模板
# 复制此文件到 /opt/nezha-agent/config.yaml 并修改相应配置

# 主接收器地址
server: your-agent-server.com:443

# 启用 TLS 加密
tls: true

# API 密钥
client_secret: \${AGENT_API_KEY:-your_agent_api_key_here}

# Agent 主机名
hostname: Agent-{主机名}

# 可选配置
# 上报间隔（秒）
# report_interval: 10

# 日志级别
# log_level: info

# 监控配置
# monitor:
#   system: true
#   network: true
#   process: true
#   gpu: false
EOF

# 创建打包脚本
log_info "创建打包脚本..."
cat > "$PACKAGE_DIR/package.sh" << 'EOF'
#!/bin/bash

# 重新打包脚本
echo "重新打包部署包..."

# 获取当前目录名
PACKAGE_DIR=$(basename "$PWD")
PACKAGE_NAME="${PACKAGE_DIR}-$(date +%Y%m%d-%H%M%S).tar.gz"

# 创建压缩包
cd ..
tar -czf "$PACKAGE_NAME" "$PACKAGE_DIR"

echo "打包完成: $PACKAGE_NAME"
echo "文件大小: $(du -h "$PACKAGE_NAME" | cut -f1)"
EOF

chmod +x "$PACKAGE_DIR/package.sh"

# 设置脚本权限
log_info "设置脚本权限..."
chmod +x "$PACKAGE_DIR"/*.sh

# 创建压缩包
log_info "创建压缩包: $PACKAGE_NAME"
tar -czf "$PACKAGE_NAME" "$PACKAGE_DIR"

# 显示结果
log_success "部署包创建完成！"
echo
echo "包名: $PACKAGE_NAME"
echo "大小: $(du -h "$PACKAGE_NAME" | cut -f1)"
echo "包含文件:"
ls -la "$PACKAGE_DIR"
echo
echo "使用方法:"
echo "1. 上传到目标 VPS: scp $PACKAGE_NAME user@vps:/tmp/"
echo "2. 解压: tar -xzf $PACKAGE_NAME"
echo "3. 进入目录: cd agent-connect-package"
echo "4. 运行安装: sudo ./install.sh"
echo
echo "或者直接运行单个脚本:"
echo "  sudo ./connect-to-main.sh    # 推荐"
echo "  sudo ./simple-connect.sh     # 简化版"
echo "  sudo ./custom-connect.sh     # 自定义编译"
