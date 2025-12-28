#include <stdio.h>
#include <cuda_runtime.h>

int main() {
    int deviceCount = 0;
    cudaError_t error = cudaGetDeviceCount(&deviceCount);
    
    if (error != cudaSuccess) {
        printf("CUDA Error: %s\n", cudaGetErrorString(error));
        return 1;
    }
    
    if (deviceCount == 0) {
        printf("没有检测到支持CUDA的GPU设备\n");
        return 1;
    }
    
    printf("检测到 %d 个CUDA设备\n\n", deviceCount);
    
    for (int dev = 0; dev < deviceCount; dev++) {
        cudaDeviceProp deviceProp;
        cudaGetDeviceProperties(&deviceProp, dev);
        
        printf("========== GPU %d: %s ==========\n", dev, deviceProp.name);
        printf("\n--- 基本信息 ---\n");
        printf("  计算能力:                    %d.%d\n", deviceProp.major, deviceProp.minor);
        printf("  CUDA核心时钟频率:            %.2f GHz\n", deviceProp.clockRate * 1e-6f);
        printf("  多处理器(SM)数量:            %d\n", deviceProp.multiProcessorCount);
        
        printf("\n--- 内存信息 ---\n");
        printf("  全局内存总量:                %.2f GB\n", deviceProp.totalGlobalMem / (1024.0 * 1024.0 * 1024.0));
        printf("  常量内存总量:                %zu KB\n", deviceProp.totalConstMem / 1024);
        printf("  每个Block共享内存:           %zu KB\n", deviceProp.sharedMemPerBlock / 1024);
        printf("  每个Block寄存器数:           %d\n", deviceProp.regsPerBlock);
        printf("  内存总线宽度:                %d bits\n", deviceProp.memoryBusWidth);
        printf("  内存时钟频率:                %.2f GHz\n", deviceProp.memoryClockRate * 1e-6f);
        printf("  L2缓存大小:                  %d KB\n", deviceProp.l2CacheSize / 1024);
        
        printf("\n--- 线程/Block配置 ---\n");
        printf("  Warp大小:                    %d\n", deviceProp.warpSize);
        printf("  每个Block最大线程数:         %d\n", deviceProp.maxThreadsPerBlock);
        printf("  每个SM最大线程数:            %d\n", deviceProp.maxThreadsPerMultiProcessor);
        printf("  Block最大维度:               (%d, %d, %d)\n", 
               deviceProp.maxThreadsDim[0], deviceProp.maxThreadsDim[1], deviceProp.maxThreadsDim[2]);
        printf("  Grid最大维度:                (%d, %d, %d)\n", 
               deviceProp.maxGridSize[0], deviceProp.maxGridSize[1], deviceProp.maxGridSize[2]);
        
        printf("\n--- 其他特性 ---\n");
        printf("  异步引擎数量:                %d\n", deviceProp.asyncEngineCount);
        printf("  统一内存支持:                %s\n", deviceProp.unifiedAddressing ? "是" : "否");
        printf("  并发内核执行:                %s\n", deviceProp.concurrentKernels ? "是" : "否");
        printf("  ECC内存支持:                 %s\n", deviceProp.ECCEnabled ? "是" : "否");
        printf("  设备可以映射主机内存:        %s\n", deviceProp.canMapHostMemory ? "是" : "否");
        printf("  计算模式:                    ");
        switch (deviceProp.computeMode) {
            case cudaComputeModeDefault:
                printf("默认 (多线程共享)\n");
                break;
            case cudaComputeModeExclusive:
                printf("独占 (单线程独占)\n");
                break;
            case cudaComputeModeProhibited:
                printf("禁止 (不可用于计算)\n");
                break;
            default:
                printf("未知\n");
        }
        
        printf("\n");
    }
    
    // 显示CUDA驱动和运行时版本
    int driverVersion = 0, runtimeVersion = 0;
    cudaDriverGetVersion(&driverVersion);
    cudaRuntimeGetVersion(&runtimeVersion);
    
    printf("========== CUDA版本信息 ==========\n");
    printf("  CUDA驱动版本:                %d.%d\n", driverVersion / 1000, (driverVersion % 100) / 10);
    printf("  CUDA运行时版本:              %d.%d\n", runtimeVersion / 1000, (runtimeVersion % 100) / 10);
    
    return 0;
}
