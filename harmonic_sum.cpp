/**
 * Harmonic Series Summation Program
 * 
 * Student ID: 58
 * Variant: 9 (OpenMP with task mechanism)
 * 
 * This program calculates the sum of the first N terms of the harmonic series:
 * Sum = 1/1 + 1/2 + 1/3 + ... + 1/N
 * where N = 10,000,000
 * 
 * The program implements two computation modes:
 * 1. Sequential mode: Single-threaded computation
 * 2. Parallel mode: Using OpenMP task mechanism for parallel computation
 * 
 * Both modes use reverse summation (from N to 1) to minimize floating-point
 * rounding errors by accumulating smaller values first.
 */

#include <iostream>
#include <iomanip>
#include <chrono>
#include <cmath>

// Include OpenMP only when parallel mode is enabled
#ifdef USE_PARALLEL
#include <omp.h>
#endif

// Default configuration
#ifndef NUM_THREADS
#define NUM_THREADS 4  // Default number of threads
#endif

// Problem size: 10 million terms
const long long N = 10000000;

/**
 * Sequential computation of harmonic series sum
 * 
 * This function computes the sum sequentially using a single thread.
 * It iterates from N down to 1 (reverse order) to minimize floating-point
 * rounding errors. When adding small numbers to large numbers, precision
 * loss can occur. By starting with small values (1/N) and gradually adding
 * larger values, we maintain better numerical precision.
 * 
 * @param n The number of terms to sum
 * @return The computed sum as a double-precision floating-point number
 */
double compute_harmonic_sequential(long long n) {
    double sum = 0.0;
    
    // Iterate in reverse order: from n down to 1
    // This improves numerical accuracy by adding smaller values first
    for (long long i = n; i >= 1; i--) {
        sum += 1.0 / static_cast<double>(i);
    }
    
    return sum;
}

#ifdef USE_PARALLEL
/**
 * Parallel computation of harmonic series sum using OpenMP tasks
 * 
 * This function uses OpenMP's task mechanism to parallelize the computation.
 * The strategy is to divide the range [1, n] into multiple blocks, and create
 * a task for each block. Each task computes a partial sum for its assigned
 * range, and these partial sums are then combined atomically.
 * 
 * Design considerations:
 * - Creating a task for each single addition would have excessive overhead
 * - We divide the work into num_threads blocks to balance parallelism and overhead
 * - Each task computes its local sum and adds it to the global sum atomically
 * - The taskwait directive ensures all tasks complete before returning
 * 
 * Note: Due to the low computational intensity of this problem (one division
 * and one addition per iteration), the parallel version may not achieve
 * significant speedup and could even be slower than sequential due to
 * task creation and synchronization overhead.
 * 
 * @param n The number of terms to sum
 * @param num_threads The number of threads/blocks to use
 * @return The computed sum as a double-precision floating-point number
 */
double compute_harmonic_parallel(long long n, int num_threads) {
    double global_sum = 0.0;
    
    // Set the number of threads for the parallel region
    omp_set_num_threads(num_threads);
    
    // Start parallel region
    #pragma omp parallel
    {
        // Only the master thread creates tasks
        // This is important to avoid redundant task creation
        #pragma omp single
        {
            // Calculate block size: divide the work among threads
            long long block_size = n / num_threads;
            
            // Create tasks for each block
            for (int k = 0; k < num_threads; k++) {
                // Calculate the range for this block
                // Each block processes approximately n/num_threads elements
                long long start = k * block_size + 1;
                long long end = (k == num_threads - 1) ? n : (k + 1) * block_size;
                
                // Create a task for this block
                // Each task is independent and can be executed by any available thread
                #pragma omp task firstprivate(start, end)
                {
                    double local_sum = 0.0;
                    
                    // Compute partial sum for this block in reverse order
                    // Reverse iteration (end to start) maintains numerical accuracy
                    for (long long i = end; i >= start; i--) {
                        local_sum += 1.0 / static_cast<double>(i);
                    }
                    
                    // Atomically add the local sum to the global sum
                    // The atomic directive ensures thread-safe addition
                    // without data races
                    #pragma omp atomic
                    global_sum += local_sum;
                }
            }
            
            // Wait for all tasks to complete before proceeding
            // This ensures global_sum contains the final result
            #pragma omp taskwait
        }
    }
    
    return global_sum;
}
#endif

/**
 * Main function
 * 
 * This function orchestrates the program execution:
 * 1. Displays student information and configuration
 * 2. Calls the appropriate computation function (sequential or parallel)
 * 3. Measures execution time using high-resolution clock
 * 4. Outputs results with 20 decimal places precision
 */
int main() {
    std::cout << "================================================" << std::endl;
    std::cout << "Harmonic Series Summation Program" << std::endl;
    std::cout << "================================================" << std::endl;
    std::cout << "Student ID: 58" << std::endl;
    std::cout << "Variant: 9 (OpenMP with task mechanism)" << std::endl;
    std::cout << "Number of terms (N): " << N << std::endl;
    
    #ifdef USE_PARALLEL
    std::cout << "Mode: Parallel (OpenMP Task)" << std::endl;
    std::cout << "Number of threads: " << NUM_THREADS << std::endl;
    #else
    std::cout << "Mode: Sequential" << std::endl;
    #endif
    
    std::cout << "================================================" << std::endl;
    
    // Record start time using high-resolution steady clock
    // steady_clock is monotonic and not affected by system clock adjustments
    auto start_time = std::chrono::steady_clock::now();
    
    double result;
    
    #ifdef USE_PARALLEL
    // Execute parallel computation
    result = compute_harmonic_parallel(N, NUM_THREADS);
    #else
    // Execute sequential computation
    result = compute_harmonic_sequential(N);
    #endif
    
    // Record end time
    auto end_time = std::chrono::steady_clock::now();
    
    // Calculate elapsed time in seconds
    // We use duration_cast to convert the time difference to a specific unit
    std::chrono::duration<double> elapsed = end_time - start_time;
    
    // Output results
    std::cout << std::endl;
    std::cout << "Computation completed!" << std::endl;
    std::cout << "Execution time: " << elapsed.count() << " seconds" << std::endl;
    
    // Set precision to 20 decimal places as required
    std::cout << std::fixed << std::setprecision(20);
    std::cout << "Result: " << result << std::endl;
    std::cout << "================================================" << std::endl;
    
    return 0;
}
