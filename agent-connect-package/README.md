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

- **主接收器地址**: ag1nt.lambdax.me:443/grpc
- **API 密钥**: `${AGENT_API_KEY:-your_agent_api_key_here}`
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
