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
