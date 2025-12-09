# Harmonic Series Summation - Parallel Computing Project

**Student ID:** 58  
**Variant:** 9 (OpenMP with task mechanism)  
**Programming Language:** C++  
**Libraries Used:** STL (std::chrono), OpenMP

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Project Overview](#project-overview)
3. [Build Instructions](#build-instructions)
4. [Running the Program](#running-the-program)
5. [Implementation Details](#implementation-details)
6. [Performance Analysis](#performance-analysis)
7. [Technical Requirements](#technical-requirements)

---

## Quick Start

### Compile and Run Both Versions

```bash
# Build both sequential and parallel versions
make all

# Run sequential version
./harmonic_seq

# Run parallel version
./harmonic_par

# Or use make commands
make run-all
```

### Benchmark Performance

```bash
# Run both versions 3 times each for comparison
make benchmark
```

### Clean Build Artifacts

```bash
make clean
```

---

## Project Overview

This project computes the sum of the first **N = 10,000,000** terms of the harmonic series:

$$
\text{Sum} = \sum_{i=1}^{10,000,000} \frac{1}{i} = \frac{1}{1} + \frac{1}{2} + \frac{1}{3} + \cdots + \frac{1}{10,000,000}
$$

The program implements two computation modes:

1. **Sequential Mode**: Single-threaded computation
2. **Parallel Mode**: Multi-threaded computation using OpenMP's task mechanism

Both modes output the result with **20 decimal places** precision and measure execution time.

---

## Build Instructions

### Prerequisites

- **C++ Compiler**: g++ or clang++ with C++11 support
- **OpenMP**: Required for parallel version (typically included with GCC)
- **Make**: GNU Make build system

### Available Make Targets

| Command | Description |
|---------|-------------|
| `make all` | Build both sequential and parallel versions (default) |
| `make sequential` | Build only the sequential version |
| `make parallel` | Build only the parallel version |
| `make parallel NUM_THREADS=8` | Build parallel version with 8 threads |
| `make clean` | Remove all compiled executables |
| `make help` | Display detailed help information |

### Build Examples

```bash
# Build both versions with default settings
make

# Build parallel version with 8 threads
make parallel NUM_THREADS=8

# Build with custom compiler
CXX=clang++ make all
```

---

## Running the Program

### Run Sequential Version

```bash
# Method 1: Direct execution
./harmonic_seq

# Method 2: Using make
make run-seq
```

**Expected Output:**
```
================================================
Harmonic Series Summation Program
================================================
Student ID: 58
Variant: 9 (OpenMP with task mechanism)
Number of terms (N): 10000000
Mode: Sequential
================================================

Computation completed!
Execution time: 0.0122752 seconds
Result: 16.69531136585996478061
================================================
```

### Run Parallel Version

```bash
# Method 1: Direct execution
./harmonic_par

# Method 2: Using make
make run-par
```

**Expected Output:**
```
================================================
Harmonic Series Summation Program
================================================
Student ID: 58
Variant: 9 (OpenMP with task mechanism)
Number of terms (N): 10000000
Mode: Parallel (OpenMP Task)
Number of threads: 4
================================================

Computation completed!
Execution time: 0.0123459 seconds
Result: 16.69531136585979425035
================================================
```

### Run Both Versions for Comparison

```bash
# Run both versions sequentially
make run-all

# Run multiple times for benchmarking
make benchmark
```

---

## Implementation Details

### Algorithm Design

#### 1. Reverse Summation Strategy

Both implementations use **reverse summation** (from N to 1) to minimize floating-point rounding errors:

```cpp
// Sum from N down to 1 (better precision)
for (long long i = n; i >= 1; i--) {
    sum += 1.0 / i;
}
```

**Why reverse order?**
- Harmonic series terms decrease as i increases: 1/10000000 << 1/1
- When adding small numbers to large numbers, precision loss occurs
- By accumulating small values first, we maintain better numerical accuracy
- The sum grows slowly, preserving more significant digits

#### 2. Sequential Implementation

The sequential version is straightforward:

```cpp
double compute_harmonic_sequential(long long n) {
    double sum = 0.0;
    for (long long i = n; i >= 1; i--) {
        sum += 1.0 / static_cast<double>(i);
    }
    return sum;
}
```

**Key features:**
- Simple loop structure
- No synchronization overhead
- Serves as baseline for performance comparison

#### 3. Parallel Implementation (OpenMP Task)

The parallel version uses OpenMP's **task mechanism** as required by Variant 9:

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

**Design rationale:**

1. **Block-based task creation**
   - Creating a task for each addition would have excessive overhead
   - We divide the range [1, N] into `num_threads` blocks
   - Each block is processed by one task

2. **Single thread creates tasks**
   - `#pragma omp single` ensures only one thread creates tasks
   - Other threads wait and execute created tasks
   - Avoids redundant task creation

3. **Task independence**
   - `firstprivate(start, end)` gives each task its own copy of range boundaries
   - Tasks can execute in any order on any available thread
   - Each task computes its local sum independently

4. **Thread-safe accumulation**
   - `#pragma omp atomic` ensures thread-safe addition to global_sum
   - Prevents data races when multiple tasks update the shared variable
   - Alternative: use reduction clause (OpenMP 5.0+)

5. **Synchronization**
   - `#pragma omp taskwait` waits for all tasks to complete
   - Ensures global_sum contains the final result before returning

#### 4. Time Measurement

High-resolution timing using C++ chrono library:

```cpp
auto start_time = std::chrono::steady_clock::now();
// ... computation ...
auto end_time = std::chrono::steady_clock::now();
std::chrono::duration<double> elapsed = end_time - start_time;
```

**Why steady_clock?**
- Monotonic: always increases, never goes backward
- Not affected by system clock adjustments
- Provides accurate elapsed time measurement

#### 5. Precision Control

Output with 20 decimal places as required:

```cpp
std::cout << std::fixed << std::setprecision(20);
std::cout << "Result: " << result << std::endl;
```

---

## Performance Analysis

### Expected Behavior

**Important Note:** Due to the nature of this problem, parallel version may NOT show significant speedup:

1. **Low computational intensity**
   - Each iteration: one division + one addition
   - Very little actual computation per element
   - Memory bandwidth is not a bottleneck

2. **Task creation overhead**
   - Creating and scheduling tasks has overhead
   - For simple computations, overhead may exceed benefit
   - This is expected and demonstrates real-world parallel computing challenges

3. **Synchronization cost**
   - Atomic operations have overhead
   - Cache coherency traffic between cores
   - May slow down parallel version

### Typical Results

```
Sequential: ~0.012 seconds
Parallel:   ~0.012 seconds (similar or slightly slower)
```

This is **expected behavior** for this problem size and complexity. It demonstrates that parallelization is not always beneficial and must be carefully considered based on:
- Problem size
- Computational complexity per iteration
- Overhead vs. benefit trade-off

### Optimization Considerations

To potentially improve parallel performance:
1. **Larger problem size**: Increase N to amortize task overhead
2. **Fewer tasks**: Use fewer blocks with more work per task
3. **Manual reduction**: Use private arrays and reduce at end
4. **Different parallel pattern**: Consider `#pragma omp parallel for reduction`

---

## Technical Requirements

### Compiler Requirements

- **C++11 or later**: Required for `std::chrono`
- **OpenMP support**: Typically included with GCC/Clang
  - GCC: Use `-fopenmp` flag
  - Clang: May need to install libomp separately

### Compilation Flags

The Makefile uses the following flags:

```makefile
CXXFLAGS = -std=c++11 -Wall -Wextra -O2
OPENMP_FLAG = -fopenmp
```

- `-std=c++11`: Enable C++11 features
- `-Wall -Wextra`: Enable comprehensive warnings
- `-O2`: Optimization level 2 (good balance)
- `-fopenmp`: Enable OpenMP support

### Macro Definitions

- `USE_PARALLEL`: Enables parallel code compilation
- `NUM_THREADS=N`: Sets number of threads (default: 4)

---

## Project Structure

```
PPSC-test/
├── harmonic_sum.cpp    # Main source code with detailed comments
├── Makefile           # Build system with multiple targets
├── README.md          # This documentation file
├── techology.md       # Technical specification (Chinese)
├── harmonic_seq       # Sequential executable (after build)
└── harmonic_par       # Parallel executable (after build)
```

---

## Troubleshooting

### OpenMP Not Found

If you get "openmp not found" errors:

```bash
# Ubuntu/Debian
sudo apt-get install libomp-dev

# macOS (with Homebrew)
brew install libomp
```

### Different Results Between Runs

Small variations in decimal places (especially beyond 15 digits) are normal due to:
- Floating-point arithmetic precision limits
- Different summation orders in parallel execution
- IEEE 754 double precision limitations

### Performance Issues

If parallel version is significantly slower:
- This is expected for this problem!
- Try adjusting `NUM_THREADS` to match your CPU cores
- Consider the problem size vs. overhead trade-off

---

## References

- **OpenMP Task Documentation**: [OpenMP API Specification](https://www.openmp.org/specifications/)
- **Floating-Point Arithmetic**: Goldberg, "What Every Computer Scientist Should Know About Floating-Point Arithmetic"
- **Harmonic Series**: [Wikipedia - Harmonic Series](https://en.wikipedia.org/wiki/Harmonic_series_(mathematics))

---

## Author

**Student ID:** 58  
**Course:** Parallel and Distributed Computing  
**Assignment:** Variant 9 - OpenMP Task Mechanism  
**Date:** December 2025