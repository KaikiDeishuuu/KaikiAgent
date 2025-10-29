# VPS Agent 安装指南

本指南将帮助你在 VPS 上安装 Nezha Agent，连接到主接收器。

## 🚀 快速安装

### 方法 1：一行命令安装（推荐）

```bash
curl -fsSL https://raw.githubusercontent.com/your-repo/quick-install-netcup.sh | sudo bash
```

### 方法 2：手动下载安装

```bash
# 下载安装脚本
wget https://raw.githubusercontent.com/your-repo/quick-install-netcup.sh
chmod +x quick-install-netcup.sh
sudo ./quick-install-netcup.sh
```

### 方法 3：完全手动安装

```bash
# 1. 安装依赖
sudo apt-get update && sudo apt-get install -y wget unzip

# 2. 下载Agent
wget https://github.com/naiba/nezha/releases/download/v0.15.6/nezha-agent_linux_amd64.zip
unzip nezha-agent_linux_amd64.zip
sudo mv nezha-agent /usr/local/bin/
sudo chmod +x /usr/local/bin/nezha-agent

# 3. 创建配置目录
sudo mkdir -p /opt/nezha-agent

# 4. 创建配置文件
sudo tee /opt/nezha-agent/config.yaml > /dev/null << EOF
server: your-agent-server.com:443/grpc
tls: true
client_secret: your_agent_api_key_here
hostname: Netcup-$(hostname)
version: v0.15.6
monitor:
  system: true
  network: true
  process: true
  gpu: false
log:
  level: info
  file: /var/log/nezha-agent.log
report_interval: 10
EOF

# 5. 创建systemd服务
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

# 6. 启动服务
sudo systemctl daemon-reload
sudo systemctl enable nezha-agent
sudo systemctl start nezha-agent
```

## 📋 安装后验证

### 检查服务状态

```bash
sudo systemctl status nezha-agent
```

### 查看日志

```bash
# 查看实时日志
sudo journalctl -u nezha-agent -f

# 查看最近日志
sudo journalctl -u nezha-agent --no-pager -n 20
```

### 检查连接

```bash
# 检查Agent是否连接到主接收器
sudo journalctl -u nezha-agent | grep -i "connected\|error\|failed"
```

## 🔧 常用管理命令

```bash
# 启动服务
sudo systemctl start nezha-agent

# 停止服务
sudo systemctl stop nezha-agent

# 重启服务
sudo systemctl restart nezha-agent

# 查看服务状态
sudo systemctl status nezha-agent

# 查看服务日志
sudo journalctl -u nezha-agent -f

# 禁用服务（开机不自启）
sudo systemctl disable nezha-agent

# 启用服务（开机自启）
sudo systemctl enable nezha-agent
```

## 🗑️ 卸载 Agent

```bash
# 停止并禁用服务
sudo systemctl stop nezha-agent
sudo systemctl disable nezha-agent

# 删除服务文件
sudo rm -f /etc/systemd/system/nezha-agent.service

# 删除Agent二进制文件
sudo rm -f /usr/local/bin/nezha-agent

# 删除配置目录
sudo rm -rf /opt/nezha-agent

# 重新加载systemd
sudo systemctl daemon-reload
```

## 📊 监控配置说明

Agent 将监控以下系统信息：

- **系统监控**: CPU、内存、磁盘使用率
- **网络监控**: 网络流量、连接状态
- **进程监控**: 系统进程状态
- **GPU 监控**: 已禁用（大多数 VPS 不需要）

## 🔐 安全说明

- Agent 使用 TLS 加密连接到主接收器
- 配置文件权限设置为 600（仅 root 可读）
- 服务以 root 权限运行（需要系统监控权限）

## 🐛 故障排除

### 服务启动失败

```bash
# 查看详细错误信息
sudo journalctl -u nezha-agent --no-pager -n 50

# 检查配置文件语法
sudo /usr/local/bin/nezha-agent -c /opt/nezha-agent/config.yaml --check-config
```

### 连接失败

```bash
# 检查网络连接
ping ag1nt.lambdax.me

# 检查端口连接
telnet ag1nt.lambdax.me 443

# 检查DNS解析
nslookup ag1nt.lambdax.me
```

### 权限问题

```bash
# 确保Agent有执行权限
sudo chmod +x /usr/local/bin/nezha-agent

# 确保配置文件权限正确
sudo chmod 600 /opt/nezha-agent/config.yaml
```

## 📞 支持

如果遇到问题，请检查：

1. 网络连接是否正常
2. 防火墙是否阻止了 443 端口
3. 系统时间是否正确
4. Agent 服务是否正常运行

## 📝 配置参数说明

| 参数              | 说明              | 默认值                      |
| ----------------- | ----------------- | --------------------------- |
| `server`          | 主接收器地址      | `ag1nt.lambdax.me:443/grpc` |
| `tls`             | 是否使用 TLS 加密 | `true`                      |
| `client_secret`   | API 密钥          | `your_agent_api_key_here`   |
| `hostname`        | Agent 名称        | `Netcup-$(hostname)`        |
| `report_interval` | 上报间隔（秒）    | `10`                        |
