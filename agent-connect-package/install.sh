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
