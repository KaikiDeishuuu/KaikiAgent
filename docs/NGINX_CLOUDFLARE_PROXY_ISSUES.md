# Nginx + Cloudflare gRPC 代理配置问题解决方案

## 问题描述

在部署 Nezha Agent 系统时，遇到了一个罕见的 Nginx + Cloudflare gRPC 代理配置问题。Agent 能够连接到服务器，但在接收任务时出现 520 错误。

## 错误现象

```
I: 02:18:47 NEZHA@2025-10-28 02:18:47>> receiveTasks exit: rpc error: code = Unknown desc = unexpected HTTP status code received from server: 520 (); transport: received unexpected content-type "text/plain; charset=UTF-8"
```

## 问题分析

### 1. 520 错误含义

- Cloudflare 返回的 520 错误表示 "Web Server Returned an Unknown Error"
- 这通常发生在 Cloudflare 无法正确代理 gRPC 请求时

### 2. 根本原因

- **gRPC 路径配置错误**：Agent 客户端尝试访问 `/grpc` 路径，但 Nginx 配置不正确
- **Cloudflare gRPC 支持**：需要正确配置 Cloudflare 的 gRPC 代理设置
- **Nginx gRPC 代理**：需要使用正确的 gRPC 代理配置

## 解决方案

### 1. Nginx 配置修复

使用 Nezha 官方的 Nginx 配置模板：

```nginx
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name your-domain.com;

    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    underscores_in_headers on;
    set_real_ip_from 0.0.0.0/0; # Cloudflare IPs
    real_ip_header CF-Connecting-IP;

    # gRPC 相关 - 关键配置
    location ^~ /proto.NezhaService/ {
        grpc_set_header Host $host;
        grpc_set_header nz-realip $http_CF_Connecting_IP;
        grpc_read_timeout 600s;
        grpc_send_timeout 600s;
        grpc_socket_keepalive on;
        client_max_body_size 10m;
        grpc_buffer_size 4m;
        grpc_pass grpc://agent_receiver;
    }

    # REST API 部分
    location /api/ {
        proxy_pass http://127.0.0.1:8081/api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # CORS headers
        add_header Access-Control-Allow-Origin * always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization,X-API-Key" always;
        add_header Access-Control-Max-Age 1728000 always;

        # Handle OPTIONS preflight requests
        if ($request_method = 'OPTIONS') {
            add_header 'Access-Control-Allow-Origin' '*';
            add_header 'Access-Control-Allow-Methods' 'GET, POST, PUT, DELETE, OPTIONS';
            add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range,Authorization,X-API-Key';
            add_header 'Access-Control-Max-Age' 1728000;
            add_header 'Content-Type' 'text/plain charset=utf-8';
            add_header 'Content-Length' 0;
            return 204;
        }
    }
}

upstream agent_receiver {
    server 127.0.0.1:50051;
    keepalive 512;
}
```

### 2. Cloudflare 配置

#### 启用 gRPC 支持

1. 在 Cloudflare Dashboard 中进入 "Network" 设置
2. 启用 "gRPC" 选项
3. 确保 "HTTP/2" 已启用

#### 页面规则配置

```
URL: ag1nt.lambdax.me/*
设置:
- Cache Level: Bypass
- Browser Cache TTL: Respect Existing Headers
- Edge Cache TTL: 1 hour
```

### 3. Agent 配置

Agent 客户端配置应该使用域名而不是 IP + 路径：

```yaml
server: ag1nt.lambdax.me:443
tls: true
client_secret: YOUR_CLIENT_SECRET_HERE
uuid: YOUR_UUID_HERE
debug: true
insecure_tls: true
report_delay: 3
ip_report_period: 1800
```

**重要**：不要使用 `ag1nt.lambdax.me:443/grpc` 这样的配置，因为 Agent 客户端不会正确解析路径。

## 关键要点

### 1. gRPC 路径处理

- Nezha Agent 使用特定的 gRPC 服务路径：`/proto.NezhaService/`
- 这个路径必须在 Nginx 中正确配置
- Agent 客户端不需要在配置中指定路径

### 2. Cloudflare gRPC 代理

- Cloudflare 需要明确启用 gRPC 支持
- 某些 Cloudflare 功能可能与 gRPC 不兼容
- 建议使用 "Bypass Cache" 模式

### 3. 真实 IP 传递

- 使用 `CF-Connecting-IP` 头传递真实客户端 IP
- 在 gRPC 服务端需要从 metadata 中提取真实 IP
- Nginx 的 `grpc_set_header` 用于设置 gRPC metadata

## 验证方法

### 1. 检查 Agent 连接

```bash
tail -f agent.log
```

应该看到：

```
I: XX:XX:XX NEZHA@2025-XX-XX XX:XX:XX>> Connection to ag1nt.lambdax.me:443 established
I: XX:XX:XX NEZHA@2025-XX-XX XX:XX:XX>> 正在更新本地缓存IP信息
```

### 2. 检查 gRPC 服务

```bash
journalctl -u agent-receiver -f
```

应该看到正常的 gRPC 请求处理日志。

### 3. 测试 API

```bash
curl -H "X-API-Key: YOUR_API_KEY" "https://ag1nt.lambdax.me/api/v1/agents"
```

## 常见问题

### Q: Agent 连接成功但无法接收任务

A: 检查 Cloudflare 的 gRPC 设置和 Nginx 的 gRPC 路径配置

### Q: 520 错误持续出现

A: 确保 Cloudflare 已启用 gRPC 支持，并检查 Nginx 配置中的 gRPC 路径

### Q: 真实 IP 显示为 127.0.0.1

A: 检查 Nginx 的 `real_ip_header` 配置和 gRPC 服务端的 IP 提取逻辑

## 总结

这个问题的核心在于正确配置 Nginx 的 gRPC 代理路径和 Cloudflare 的 gRPC 支持。使用 Nezha 官方的 Nginx 配置模板可以避免大部分配置问题。关键是要理解 gRPC 代理与普通 HTTP 代理的区别，以及 Cloudflare 对 gRPC 的特殊处理要求。
