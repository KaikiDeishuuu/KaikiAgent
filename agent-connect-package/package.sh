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
