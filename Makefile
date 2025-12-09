# Makefile for Harmonic Series Summation Program
# Student ID: 58
# Variant: 9 (OpenMP with task mechanism)

# ============================================================================
# Compiler Configuration
# ============================================================================

# C++ compiler (g++ for GCC, clang++ for Clang)
CXX = g++

# Base compilation flags:
# -std=c++11  : Use C++11 standard (required for chrono library)
# -Wall       : Enable all common warnings
# -Wextra     : Enable extra warnings
# -O2         : Optimization level 2 (good balance between speed and compilation time)
CXXFLAGS = -std=c++11 -Wall -Wextra -O2

# OpenMP flag (enables OpenMP support)
OPENMP_FLAG = -fopenmp

# ============================================================================
# Configuration Variables
# ============================================================================

# Default number of threads for parallel execution
# Can be overridden: make parallel NUM_THREADS=8
NUM_THREADS ?= 4

# ============================================================================
# Target Definitions
# ============================================================================

# Source file
SRC = harmonic_sum.cpp

# Output executables
SEQ_TARGET = harmonic_seq
PAR_TARGET = harmonic_par

# ============================================================================
# Build Rules
# ============================================================================

# Default target: build both sequential and parallel versions
.PHONY: all
all: sequential parallel
	@echo ""
	@echo "================================================"
	@echo "Build completed successfully!"
	@echo "Sequential executable: $(SEQ_TARGET)"
	@echo "Parallel executable: $(PAR_TARGET)"
	@echo "================================================"

# Build sequential version
# This version does not use OpenMP and runs in a single thread
.PHONY: sequential
sequential: $(SEQ_TARGET)

$(SEQ_TARGET): $(SRC)
	@echo "Building sequential version..."
	$(CXX) $(CXXFLAGS) $(SRC) -o $(SEQ_TARGET)
	@echo "Sequential build complete: $(SEQ_TARGET)"

# Build parallel version
# This version uses OpenMP task mechanism for parallel computation
# The NUM_THREADS macro is passed to the source code via -D flag
.PHONY: parallel
parallel: $(PAR_TARGET)

$(PAR_TARGET): $(SRC)
	@echo "Building parallel version with $(NUM_THREADS) threads..."
	$(CXX) $(CXXFLAGS) $(OPENMP_FLAG) -DUSE_PARALLEL -DNUM_THREADS=$(NUM_THREADS) $(SRC) -o $(PAR_TARGET)
	@echo "Parallel build complete: $(PAR_TARGET)"

# ============================================================================
# Execution Rules
# ============================================================================

# Run sequential version
.PHONY: run-seq
run-seq: sequential
	@echo ""
	@echo "Running sequential version..."
	@echo ""
	./$(SEQ_TARGET)

# Run parallel version
.PHONY: run-par
run-par: parallel
	@echo ""
	@echo "Running parallel version..."
	@echo ""
	./$(PAR_TARGET)

# Run both versions for comparison
.PHONY: run-all
run-all: run-seq run-par
	@echo ""
	@echo "Both versions executed successfully!"

# ============================================================================
# Testing and Benchmarking Rules
# ============================================================================

# Run sequential version multiple times for benchmarking
.PHONY: benchmark-seq
benchmark-seq: sequential
	@echo "Running sequential version 3 times for benchmarking..."
	@for i in 1 2 3; do \
		echo ""; \
		echo "Run $$i:"; \
		./$(SEQ_TARGET); \
	done

# Run parallel version multiple times for benchmarking
.PHONY: benchmark-par
benchmark-par: parallel
	@echo "Running parallel version 3 times for benchmarking..."
	@for i in 1 2 3; do \
		echo ""; \
		echo "Run $$i:"; \
		./$(PAR_TARGET); \
	done

# Compare performance of sequential vs parallel
.PHONY: benchmark
benchmark: benchmark-seq benchmark-par

# ============================================================================
# Utility Rules
# ============================================================================

# Clean build artifacts
.PHONY: clean
clean:
	@echo "Cleaning build artifacts..."
	rm -f $(SEQ_TARGET) $(PAR_TARGET)
	@echo "Clean complete!"

# Display help information
.PHONY: help
help:
	@echo "================================================"
	@echo "Harmonic Series Summation - Makefile Help"
	@echo "================================================"
	@echo ""
	@echo "Available targets:"
	@echo "  make all              - Build both sequential and parallel versions (default)"
	@echo "  make sequential       - Build only sequential version"
	@echo "  make parallel         - Build only parallel version"
	@echo "  make run-seq          - Build and run sequential version"
	@echo "  make run-par          - Build and run parallel version"
	@echo "  make run-all          - Build and run both versions"
	@echo "  make benchmark-seq    - Run sequential version 3 times"
	@echo "  make benchmark-par    - Run parallel version 3 times"
	@echo "  make benchmark        - Benchmark both versions"
	@echo "  make clean            - Remove build artifacts"
	@echo "  make help             - Display this help message"
	@echo ""
	@echo "Configuration options:"
	@echo "  NUM_THREADS=N         - Set number of threads (default: 4)"
	@echo "                          Example: make parallel NUM_THREADS=8"
	@echo ""
	@echo "Examples:"
	@echo "  make                  - Build both versions"
	@echo "  make parallel NUM_THREADS=8"
	@echo "  make run-all"
	@echo "  make benchmark"
	@echo "================================================"

# ============================================================================
# Debug Rules (optional)
# ============================================================================

# Build with debug symbols and no optimization (for debugging with gdb)
.PHONY: debug-seq
debug-seq: CXXFLAGS = -std=c++11 -Wall -Wextra -g -O0
debug-seq: $(SRC)
	@echo "Building sequential version with debug symbols..."
	$(CXX) $(CXXFLAGS) $(SRC) -o $(SEQ_TARGET)_debug
	@echo "Debug build complete: $(SEQ_TARGET)_debug"

.PHONY: debug-par
debug-par: CXXFLAGS = -std=c++11 -Wall -Wextra -g -O0
debug-par: $(SRC)
	@echo "Building parallel version with debug symbols..."
	$(CXX) $(CXXFLAGS) $(OPENMP_FLAG) -DUSE_PARALLEL -DNUM_THREADS=$(NUM_THREADS) $(SRC) -o $(PAR_TARGET)_debug
	@echo "Debug build complete: $(PAR_TARGET)_debug"
