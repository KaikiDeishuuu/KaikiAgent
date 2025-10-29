# Nezha Agent 系统监控

基于 [Nezha](https://github.com/nezhahq/agent) 开源项目的分布式系统监控解决方案。

## 🙏 特别感谢

本项目基于 [Nezha](https://github.com/nezhahq/agent) 开源项目构建，感谢 Nezha 团队提供的优秀开源监控解决方案。

## 🚀 快速部署

### 1. 部署 Agent 接收器

在服务器上部署 gRPC 接收器：

```bash
# 编译接收器
cd cmd/grpc_receiver
go build -o grpc_receiver main.go

# 启动服务
./grpc_receiver --port=50051 --api-key=your_api_key_here
```

### 2. 配置 Nginx 代理

```nginx
server {
    listen 443 ssl http2;
    server_name your-domain.com;

    # gRPC 代理配置
    location ^~ /proto.NezhaService/ {
        grpc_set_header Host $host;
        grpc_set_header nz-realip $http_CF_Connecting_IP;
        grpc_pass grpc://agent_receiver;
    }

    # REST API 配置
    location /api/ {
        proxy_pass http://127.0.0.1:8081/api/;
        # CORS 配置...
    }
}

upstream agent_receiver {
    server 127.0.0.1:50051;
    keepalive 512;
}
```

### 3. 部署 Agent 客户端

在需要监控的服务器上：

```bash
# 下载 Agent
wget https://github.com/nezhahq/agent/releases/download/v1.14.1/nezha-agent_linux_amd64.zip
unzip nezha-agent_linux_amd64.zip
chmod +x nezha-agent

# 创建配置文件
cat > config.yml << EOF
server: your-domain.com:443
tls: true
client_secret: YOUR_CLIENT_SECRET_HERE
uuid: $(uuidgen)
debug: true
report_delay: 3
ip_report_period: 1800
EOF

# 启动 Agent
nohup ./nezha-agent -c config.yml > agent.log 2>&1 &
```

## 📦 部署包

使用提供的部署包快速部署：

```bash
# 解压部署包
tar -xzf agent-connect-*.tar.gz
cd agent-connect-package

# 运行安装
sudo ./install.sh
```

## 🔧 配置说明

### Agent 配置

```yaml
server: your-domain.com:443 # 接收器地址
tls: true # 启用 TLS 加密
client_secret: YOUR_CLIENT_SECRET # 客户端密钥
uuid: YOUR_UUID # 唯一标识符
debug: true # 调试模式
report_delay: 3 # 上报间隔（秒）
ip_report_period: 1800 # IP 上报周期（秒）
```

## 🌐 Web 仪表板

配合前端项目使用，提供现代化的 Web 监控界面：

- 多服务器实时监控
- CPU、内存、网络、磁盘监控
- 性能趋势图表
- 自定义服务器命名
- 移动端适配
- 明暗主题切换

## 📚 文档

- [Nginx + Cloudflare gRPC 代理配置问题解决方案](docs/NGINX_CLOUDFLARE_PROXY_ISSUES.md)
- [部署包使用说明](agent-connect-package/README.md)

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

本项目基于 MIT 许可证开源。

## 🔗 相关链接

- [Nezha 官方项目](https://github.com/nezhahq/agent)
- [Nezha Dashboard](https://github.com/nezhahq/nezha)
