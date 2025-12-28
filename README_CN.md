# 调和级数求和 - 并行计算项目

**作者：** Fan Zhanhong  
**学号：** 58  
**变体：** 9 (OpenMP 任务机制)  
**编程语言：** C++  
**使用的库：** STL (std::chrono), OpenMP

---

## 快速开始

```bash
# 编译串行和并行两个版本
make

# 运行两个版本
make run-all

# 分别运行
./harmonic_seq    # 串行版本
./harmonic_par    # 并行版本

# 清理编译文件
make clean
```

---

## 项目概述

本项目计算调和级数前 **N = 10,000,000** 项的和：

$$
\text{Sum} = \sum_{i=1}^{10,000,000} \frac{1}{i} = \frac{1}{1} + \frac{1}{2} + \frac{1}{3} + \cdots + \frac{1}{10,000,000}
$$

程序实现了两种计算模式：

1. **串行模式**：单线程计算
2. **并行模式**：使用 OpenMP 任务机制的多线程计算

两种模式都输出 **20 位小数** 精度的结果，并测量执行时间。

---

## 编译说明

### 前置要求

- **C++ 编译器**：g++ 或 clang++，支持 C++11
- **OpenMP**：并行版本需要（GCC 自带）
- **Make**：GNU Make 构建系统

### Makefile 命令

```bash
make              # 编译两个版本（默认）
make run-seq      # 编译并运行串行版本
make run-par      # 编译并运行并行版本
make run-all      # 编译并运行两个版本
make clean        # 删除编译文件
```

### 自定义线程数

```bash
# 使用 8 个线程编译并行版本
make PAR_TARGET NUM_THREADS=8
```

### 手动编译

如果不使用 Make，可以手动编译：

```bash
# 串行版本
g++ -std=c++11 -Wall -O2 harmonic_sum.cpp -o harmonic_seq

# 并行版本（4线程）
g++ -std=c++11 -Wall -O2 -fopenmp -DUSE_PARALLEL -DNUM_THREADS=4 harmonic_sum.cpp -o harmonic_par
```

---

## 运行程序

### 串行版本

```bash
make run-seq
# 或
./harmonic_seq
```

**输出示例：**
```
================================================
Harmonic Series Summation Program
================================================
Author: Fan Zhanhong
Student ID: 58
Variant: 9 (OpenMP with task mechanism)
Number of terms (N): 10000000
Mode: Sequential
================================================

Computation completed!
Execution time: 0.0120235 seconds
Result: 16.69531136585996478061
================================================
```

### 并行版本

```bash
make run-par
# 或
./harmonic_par
```

**输出示例：**
```
================================================
Harmonic Series Summation Program
================================================
Author: Fan Zhanhong
Student ID: 58
Variant: 9 (OpenMP with task mechanism)
Number of terms (N): 10000000
Mode: Parallel (OpenMP Task)
Number of threads: 4
================================================

Computation completed!
Execution time: 0.0130872 seconds
Result: 16.69531136585979425035
================================================
```

### 运行两个版本对比

```bash
make run-all
```

此命令会依次运行串行和并行版本，方便进行对比。

---

## 实现细节

### 算法设计

#### 1. 逆序求和策略

两个版本都使用 **逆序求和**（从 N 到 1）来减少浮点误差：

```cpp
// 从 N 到 1 求和（更高精度）
for (long long i = n; i >= 1; i--) {
    sum += 1.0 / i;
}
```

**为什么要逆序？**
- 调和级数的项随 i 增大而减小：1/10000000 << 1/1
- 当把小数加到大数上时，会发生精度损失
- 通过先累加小值，我们能保持更好的数值精度
- 和值缓慢增长，保留更多有效数字

#### 2. 串行实现

串行版本非常直接：

```cpp
double compute_harmonic_sequential(long long n) {
    double sum = 0.0;
    for (long long i = n; i >= 1; i--) {
        sum += 1.0 / static_cast<double>(i);
    }
    return sum;
}
```

**关键特性：**
- 简单的循环结构
- 没有同步开销
- 作为性能对比的基准

#### 3. 并行实现（OpenMP Task）

并行版本使用 OpenMP 的 **任务机制**，符合变体 9 的要求：

```cpp
double compute_harmonic_parallel(long long n, int num_threads) {
    double global_sum = 0.0;
    omp_set_num_threads(num_threads);
    
    #pragma omp parallel
    {
        #pragma omp single
        {
            long long block_size = n / num_threads;
            
            for (int k = 0; k < num_threads; k++) {
                long long start = k * block_size + 1;
                long long end = (k == num_threads - 1) ? n : (k + 1) * block_size;
                
                #pragma omp task firstprivate(start, end)
                {
                    double local_sum = 0.0;
                    for (long long i = end; i >= start; i--) {
                        local_sum += 1.0 / static_cast<double>(i);
                    }
                    
                    #pragma omp atomic
                    global_sum += local_sum;
                }
            }
            
            #pragma omp taskwait
        }
    }
    
    return global_sum;
}
```

**设计原理：**

1. **基于块的任务创建**
   - 为每次加法创建任务会有过高开销
   - 我们将范围 [1, N] 划分为 `num_threads` 个块
   - 每个块由一个任务处理

2. **单线程创建任务**
   - `#pragma omp single` 确保只有一个线程创建任务
   - 其他线程等待并执行创建的任务
   - 避免重复创建任务

3. **任务独立性**
   - `firstprivate(start, end)` 给每个任务自己的范围边界副本
   - 任务可以在任何可用线程上以任何顺序执行
   - 每个任务独立计算其局部和

4. **线程安全的累加**
   - `#pragma omp atomic` 确保对 global_sum 的线程安全加法
   - 防止多个任务更新共享变量时的数据竞争
   - 替代方案：使用归约子句（OpenMP 5.0+）

5. **同步机制**
   - `#pragma omp taskwait` 等待所有任务完成
   - 确保 global_sum 在返回前包含最终结果

#### 4. 时间测量

使用 C++ chrono 库进行高精度计时：

```cpp
auto start_time = std::chrono::steady_clock::now();
// ... 计算 ...
auto end_time = std::chrono::steady_clock::now();
std::chrono::duration<double> elapsed = end_time - start_time;
```

**为什么使用 steady_clock？**
- 单调性：始终递增，永不回退
- 不受系统时钟调整影响
- 提供准确的经过时间测量

#### 5. 精度控制

按要求输出 20 位小数：

```cpp
std::cout << std::fixed << std::setprecision(20);
std::cout << "Result: " << result << std::endl;
```

---

## 性能分析

### 预期结果

并行和串行版本的**执行时间相近**（约 0.012 秒）。这是预期结果，展示了并行计算中的重要经验。

**典型结果：**
```
串行：0.012 秒
并行：0.013 秒（相近或稍慢）
```

### 为什么并行不更快？

这是这个特定问题的**正常表现**：

1. **计算强度低**
   - 每次迭代：一次除法 + 一次加法
   - 在现代 CPU 上这些操作极快
   - 计算时间 << 并行化开销

2. **并行化开销**
   - OpenMP 任务创建和调度
   - 线程同步（`#pragma omp atomic`）
   - CPU 核心之间的缓存一致性
   - 内存访问协调

3. **问题规模小**
   - N = 10,000,000 在约 0.012 秒内完成
   - 开销无法被摊销
   - 问题不够大，无法从并行中获益

4. **开销 vs. 收益**
   ```
   并行收益：约 0.012秒 / 4线程 = 0.003秒
   并行开销：约 0.010秒（任务管理、同步）
   净收益：0.003秒 - 0.010秒 = -0.007秒（更慢！）
   ```

### 教育价值

这个结果很**有价值**，因为它展示了：
- 并行化并不总是有益的
- 在应用并行技术前需要分析问题特性
- 开销分析在并行计算中至关重要
- 简单问题可能串行运行更快

### 何时并行会更快？

并行版本在以下情况下表现更好：
- **更大的问题规模**：N = 1,000,000,000 或更多
- **复杂的计算**：每次迭代有大量数学运算
- **计算 > 开销**：计算时间显著超过并行化开销

---

## 技术要求

### 编译器要求

- **C++11 或更高版本**：`std::chrono` 需要
- **OpenMP 支持**：GCC/Clang 通常自带
  - GCC：使用 `-fopenmp` 标志
  - Clang：可能需要单独安装 libomp

### 编译标志

Makefile 使用以下标志：

```makefile
CXXFLAGS = -std=c++11 -Wall -O2
OPENMP_FLAG = -fopenmp
```

- `-std=c++11`：启用 C++11 特性
- `-Wall`：启用所有常见警告
- `-O2`：优化级别 2（速度和编译时间的平衡）
- `-fopenmp`：启用 OpenMP 支持

### 宏定义

- `USE_PARALLEL`：启用并行代码编译
- `NUM_THREADS=N`：设置线程数（默认：4）

---

## 条件编译机制

程序使用**同一个源文件**通过条件编译生成两个版本：

### 串行版本编译：
```bash
g++ -std=c++11 -Wall -O2 harmonic_sum.cpp -o harmonic_seq
```
- **不定义** `USE_PARALLEL` 宏
- **不链接** OpenMP 库
- 只编译串行函数

### 并行版本编译：
```bash
g++ -std=c++11 -Wall -O2 -fopenmp -DUSE_PARALLEL -DNUM_THREADS=4 harmonic_sum.cpp -o harmonic_par
```
- **定义** `USE_PARALLEL` 宏（通过 `-DUSE_PARALLEL`）
- **链接** OpenMP 库（通过 `-fopenmp`）
- 编译并行函数和 OpenMP 代码

### 源码中的切换：
```cpp
#ifdef USE_PARALLEL
// 并行代码
#include <omp.h>
double compute_harmonic_parallel(...) { ... }
#else
// 串行代码
#endif
```

---

## 故障排除

### OpenMP 未找到

如果编译失败并出现 OpenMP 错误：

```bash
# Ubuntu/Debian
sudo apt-get install libomp-dev

# macOS（使用 Homebrew）
brew install libomp
```

### 编译错误

确保你有：
- GCC 4.9+ 或 Clang 3.7+（支持 C++11 和 OpenMP）
- 安装了 Make 工具

### 结果差异

运行之间最后几位小数的微小差异是正常的，原因是：
- 浮点运算精度限制
- 并行执行中不同的求和顺序
- IEEE 754 双精度约束（15-17 位有效数字）

---

## 参考资料

- **OpenMP 任务文档**：[OpenMP API 规范](https://www.openmp.org/specifications/)
- **浮点运算**：Goldberg，"每个计算机科学家都应该知道的浮点运算知识"
- **调和级数**：[维基百科 - 调和级数](https://zh.wikipedia.org/wiki/调和级数)

---

## 作者信息

**姓名：** Fan Zhanhong  
**学号：** 58  
**课程：** 并行与分布式计算  
**作业：** 变体 9 - OpenMP 任务机制  
**日期：** 2025年12月
