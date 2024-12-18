#!/bin/sh

# Default values
DEFAULT_MATRIX_SIZE=16
DEFAULT_RUNS=10
DEFAULT_PROGRAM="impGaussian/gaussian"

# Check for input arguments
if [ "$#" -eq 0 ]; then
    MATRIX_SIZE=$DEFAULT_MATRIX_SIZE
    NUM_RUNS=$DEFAULT_RUNS
    PROGRAM=$DEFAULT_PROGRAM
    echo "No arguments provided. Using defaults: Matrix size: $MATRIX_SIZE, Runs: $NUM_RUNS, Program: $PROGRAM"
elif [ "$#" -eq 1 ]; then
    MATRIX_SIZE=$1
    NUM_RUNS=$DEFAULT_RUNS
    PROGRAM=$DEFAULT_PROGRAM
    echo "Matrix size provided. Using: Matrix size: $MATRIX_SIZE, Runs: $NUM_RUNS, Program: $PROGRAM"
elif [ "$#" -eq 2 ]; then
    MATRIX_SIZE=$1
    NUM_RUNS=$2
    PROGRAM=$DEFAULT_PROGRAM
    echo "Matrix size and runs provided. Using: Matrix size: $MATRIX_SIZE, Runs: $NUM_RUNS, Program: $PROGRAM"
elif [ "$#" -eq 3 ]; then
    MATRIX_SIZE=$1
    NUM_RUNS=$2
    PROGRAM=$3
    echo "Matrix size, runs, and program provided. Using: Matrix size: $MATRIX_SIZE, Runs: $NUM_RUNS, Program: $PROGRAM"
else
    echo "Usage: $0 [matrix_size] [number_of_runs] [program]"
    echo "Matrix size can be 16, 1024, or 4096."
    echo "Number of runs can be 10, 25, or 50."
    echo "Program can be any valid executable."
    exit 1
fi

# Validate matrix size
if [ "$MATRIX_SIZE" != "16" ] && [ "$MATRIX_SIZE" != "1024" ] && [ "$MATRIX_SIZE" != "4096" ]; then
    echo "Invalid matrix size. Only 16, 1024, or 4096 are supported."
    exit 1
fi

# Validate number of runs
if [ "$NUM_RUNS" != "10" ] && [ "$NUM_RUNS" != "25" ] && [ "$NUM_RUNS" != "50" ]; then
    echo "Invalid number of runs. Only 10, 25, or 50 are supported."
    exit 1
fi

DATA_FILE="data/gaussian/matrix${MATRIX_SIZE}.txt"
OUTPUT_FILE="tmp.txt"
TOTAL_TIME_TOTAL=0
TOTAL_TIME_KERNELS=0

echo "Running the program $NUM_RUNS times with $PROGRAM..."

for i in $(seq 1 $NUM_RUNS); do
    echo "Run $i..."
    $PROGRAM -f $DATA_FILE -q > $OUTPUT_FILE
    
    if [ ! -f "$OUTPUT_FILE" ]; then
        echo "Error: Output file $OUTPUT_FILE not found."
        exit 1
    fi

    TIME_TOTAL=$(grep -oP "Time total \(including memory transfers\)\s+\K[\d.]+" "$OUTPUT_FILE")
    TIME_KERNELS=$(grep -oP "Time for CUDA kernels:\s+\K[\d.]+" "$OUTPUT_FILE")

    if [ -z "$TIME_TOTAL" ] || [ -z "$TIME_KERNELS" ]; then
        echo "Error: Failed to extract times from output."
        exit 1
    fi

    TOTAL_TIME_TOTAL=$(echo "$TOTAL_TIME_TOTAL + $TIME_TOTAL" | bc)
    TOTAL_TIME_KERNELS=$(echo "$TOTAL_TIME_KERNELS + $TIME_KERNELS" | bc)
done

rm -f "tmp.txt"

AVG_TIME_TOTAL=$(echo "scale=6; $TOTAL_TIME_TOTAL / $NUM_RUNS" | bc)
AVG_TIME_KERNELS=$(echo "scale=6; $TOTAL_TIME_KERNELS / $NUM_RUNS" | bc)

PARSED_FILE="benchmarks/$(dirname $PROGRAM)_avg_${MATRIX_SIZE}_${NUM_RUNS}.txt"
cat <<EOF > "$PARSED_FILE"
Average Total Time (including memory transfers): $AVG_TIME_TOTAL sec
Average Time for CUDA Kernels: $AVG_TIME_KERNELS sec
EOF

echo "Average Total Time (including memory transfers): $AVG_TIME_TOTAL sec"
echo "Average Time for CUDA Kernels: $AVG_TIME_KERNELS sec"
echo "Parsed information saved to $PARSED_FILE"
