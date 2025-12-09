# Makefile for Harmonic Series Summation Program
# Author: Fan Zhanhong
# Student ID: 58

CXX = g++
CXXFLAGS = -std=c++11 -Wall -O2
OPENMP_FLAG = -fopenmp
NUM_THREADS ?= 4

SRC = harmonic_sum.cpp
SEQ_TARGET = harmonic_seq
PAR_TARGET = harmonic_par

# Build both versions
all: $(SEQ_TARGET) $(PAR_TARGET)

# Build sequential version
$(SEQ_TARGET): $(SRC)
	$(CXX) $(CXXFLAGS) $(SRC) -o $(SEQ_TARGET)

# Build parallel version
$(PAR_TARGET): $(SRC)
	$(CXX) $(CXXFLAGS) $(OPENMP_FLAG) -DUSE_PARALLEL -DNUM_THREADS=$(NUM_THREADS) $(SRC) -o $(PAR_TARGET)

# Run sequential version
run-seq: $(SEQ_TARGET)
	./$(SEQ_TARGET)

# Run parallel version
run-par: $(PAR_TARGET)
	./$(PAR_TARGET)

# Run both versions
run-all: run-seq run-par

# Clean build artifacts
clean:
	rm -f $(SEQ_TARGET) $(PAR_TARGET)

.PHONY: all run-seq run-par run-all clean
