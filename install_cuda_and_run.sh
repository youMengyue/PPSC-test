#!/bin/bash

# CUDA 安装和 GPU 信息程序运行脚本
# 适用于 Ubuntu 24.04

set -e

echo "=========================================="
echo "CUDA 安装脚本"
echo "=========================================="

# 检查是否有 NVIDIA GPU
echo "检查 NVIDIA GPU..."
if lspci 2>/dev/null | grep -i nvidia > /dev/null; then
    echo "✓ 检测到 NVIDIA GPU"
else
    echo "⚠ 警告: 未检测到 NVIDIA GPU 硬件"
    echo "  如果在虚拟机或容器中，可能无法访问 GPU"
    echo "  继续安装 CUDA 工具包..."
fi

# 检查是否已安装 nvcc
if command -v nvcc &> /dev/null; then
    echo "✓ CUDA 已安装"
    nvcc --version
else
    echo "正在安装 CUDA..."
    
    # 更新包管理器
    sudo apt-get update
    
    # 安装 CUDA 工具包 (使用 Ubuntu 仓库中的版本)
    echo "安装 nvidia-cuda-toolkit..."
    sudo apt-get install -y nvidia-cuda-toolkit
    
    # 验证安装
    if command -v nvcc &> /dev/null; then
        echo "✓ CUDA 安装成功"
        nvcc --version
    else
        echo "✗ CUDA 安装失败，尝试其他方法..."
        
        # 使用 NVIDIA 官方仓库
        wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb
        sudo dpkg -i cuda-keyring_1.1-1_all.deb
        sudo apt-get update
        sudo apt-get install -y cuda-toolkit-12-6
        
        # 设置环境变量
        echo 'export PATH=/usr/local/cuda/bin:$PATH' >> ~/.bashrc
        echo 'export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH' >> ~/.bashrc
        export PATH=/usr/local/cuda/bin:$PATH
        export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
    fi
fi

echo ""
echo "=========================================="
echo "编译 GPU 信息程序"
echo "=========================================="

cd /workspaces/PPSC-test

# 编译程序
echo "编译 gpu_info.cu..."
nvcc -o gpu_info gpu_info.cu

if [ -f ./gpu_info ]; then
    echo "✓ 编译成功"
    echo ""
    echo "=========================================="
    echo "运行 GPU 信息程序"
    echo "=========================================="
    ./gpu_info
else
    echo "✗ 编译失败"
    exit 1
fi
