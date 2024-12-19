#!/bin/sh

# Default matrix size
DEFAULT_MATRIX_SIZE=16

# Check for input argument, default to 16 if not provided
if [ "$#" -eq 0 ]; then
    MATRIX_SIZE=$DEFAULT_MATRIX_SIZE
    echo "No matrix size provided. Using default: $MATRIX_SIZE"
else
    MATRIX_SIZE=$1
fi

# Validate input argument
if [ "$MATRIX_SIZE" != "4" ] &&"$MATRIX_SIZE" != "16" ] && [ "$MATRIX_SIZE" != "4096" ] && [ "$MATRIX_SIZE" != "1024" ]; then
    echo "Invalid matrix size. Only 4, 16, 1024, 4096 are supported."
    exit 1
fi

# Define variables for paths and filenames
CUDA_DIR="cuda/gaussian"
IMP_DIR="impGaussian"
DATA_FILE="data/gaussian/matrix${MATRIX_SIZE}.txt"
RESULTS_DIR="results"
OLD_RESULT_FILE="$RESULTS_DIR/oldMat${MATRIX_SIZE}Results.txt"
IMP_RESULT_FILE="$RESULTS_DIR/impMat${MATRIX_SIZE}Results.txt"

# Ensure results directory exists
mkdir -p $RESULTS_DIR

# Function to handle errors
handle_error() {
    echo "Error encountered: $1"
    exit 1
}

# Build CUDA Gaussian
echo "Building CUDA Gaussian..."
cd $CUDA_DIR || handle_error "Failed to change directory to $CUDA_DIR"
make || handle_error "Build failed in $CUDA_DIR"
cd - > /dev/null || handle_error "Failed to return to the base directory"

# Build Improved Gaussian
echo "Building Improved Gaussian..."
cd $IMP_DIR || handle_error "Failed to change directory to $IMP_DIR"
make || handle_error "Build failed in $IMP_DIR"
cd - > /dev/null || handle_error "Failed to return to the base directory"

# Run CUDA Gaussian
echo "Running CUDA Gaussian with matrix size $MATRIX_SIZE..."
$CUDA_DIR/gaussian -f $DATA_FILE -v > $OLD_RESULT_FILE || handle_error "Execution failed for CUDA Gaussian"

# Run Improved Gaussian
echo "Running Improved Gaussian with matrix size $MATRIX_SIZE..."
$IMP_DIR/gaussian -f $DATA_FILE -v > $IMP_RESULT_FILE || handle_error "Execution failed for Improved Gaussian"

# Compare results
echo "Comparing results for matrix size $MATRIX_SIZE..."
diff $OLD_RESULT_FILE $IMP_RESULT_FILE || echo "Differences found between results."

echo "Script completed successfully for matrix size $MATRIX_SIZE."
