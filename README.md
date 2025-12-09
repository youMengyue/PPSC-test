# Harmonic Series Summation - Parallel Computing Project

**Author:** Fan Zhanhong  
**Student ID:** 58  
**Variant:** 9 (OpenMP with task mechanism)  
**Programming Language:** C++  
**Libraries Used:** STL (std::chrono), OpenMP

---

## Quick Start

```bash
# Build both sequential and parallel versions
make

# Run both versions
make run-all

# Run individual versions
./harmonic_seq    # Sequential version
./harmonic_par    # Parallel version

# Clean build files
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
- **OpenMP**: Required for parallel version (included with GCC)
- **Make**: GNU Make build system

### Makefile Targets

```bash
make              # Build both versions (default)
make run-seq      # Build and run sequential version
make run-par      # Build and run parallel version
make run-all      # Build and run both versions
make clean        # Remove compiled executables
```

### Build with Custom Thread Count

```bash
# Build parallel version with 8 threads
make PAR_TARGET NUM_THREADS=8
```

### Manual Compilation

If you prefer to compile manually without Make:

```bash
# Sequential version
g++ -std=c++11 -Wall -O2 harmonic_sum.cpp -o harmonic_seq

# Parallel version with 4 threads
g++ -std=c++11 -Wall -O2 -fopenmp -DUSE_PARALLEL -DNUM_THREADS=4 harmonic_sum.cpp -o harmonic_par
```

---

## Running the Program

### Sequential Version

```bash
make run-seq
# or
./harmonic_seq
```

**Output:**
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

### Parallel Version

```bash
make run-par
# or
./harmonic_par
```

**Output:**
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

### Run Both Versions

```bash
make run-all
```

This will run both the sequential and parallel versions consecutively for easy comparison.

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

### Expected Results

The parallel and sequential versions have **similar execution times** (~0.012 seconds). This is expected and demonstrates an important lesson in parallel computing.

**Typical Results:**
```
Sequential: 0.012 seconds
Parallel:   0.013 seconds (similar or slightly slower)
```

### Why Parallel Is Not Faster?

This is **normal behavior** for this particular problem:

1. **Low Computational Intensity**
   - Each iteration: one division + one addition
   - Operations are extremely fast on modern CPUs
   - Calculation time << parallelization overhead

2. **Parallelization Overhead**
   - OpenMP task creation and scheduling
   - Thread synchronization (`#pragma omp atomic`)
   - Cache coherency between CPU cores
   - Memory access coordination

3. **Small Problem Size**
   - N = 10,000,000 completes in ~0.012 seconds
   - Overhead cannot be amortized
   - Problem is not large enough to benefit from parallelism

4. **Overhead vs. Benefit**
   ```
   Parallel benefit: ~0.012s / 4 threads = 0.003s
   Parallel overhead: ~0.010s (task management, sync)
   Net gain: 0.003s - 0.010s = -0.007s (slower!)
   ```

### Educational Value

This result is **valuable** because it demonstrates:
- Parallelization is not always beneficial
- Need to analyze problem characteristics before applying parallel techniques
- Overhead analysis is crucial in parallel computing
- Simple problems may run faster sequentially

### When Would Parallel Be Faster?

Parallel versions excel when:
- **Larger problem size**: N = 1,000,000,000 or more
- **Complex computations**: Heavy mathematical operations per iteration
- **Computation > Overhead**: When calculation time significantly exceeds parallelization overhead

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