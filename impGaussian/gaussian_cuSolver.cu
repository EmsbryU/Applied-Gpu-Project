#include <iostream>
#include <fstream>
#include <vector>
#include <cublas_v2.h>
#include <cusolverDn.h>
#include <cuda_runtime.h>
#include <sys/time.h>

double cpuSecond() {
  struct timeval tp;
  gettimeofday(&tp, NULL);
  return ((double)tp.tv_sec + (double)tp.tv_usec*1.e-6);
}

#define CHECK_CUDA(call) \
    { \
        const cudaError_t error = call; \
        if (error != cudaSuccess) { \
            std::cerr << "Error: " << __FILE__ << ", line " << __LINE__ << ": " << cudaGetErrorString(error) << std::endl; \
            exit(1); \
        } \
    }

#define CHECK_CUSOLVER(call) \
    { \
        const cusolverStatus_t status = call; \
        if (status != CUSOLVER_STATUS_SUCCESS) { \
            std::cerr << "CUSOLVER error at line " << __LINE__ << std::endl; \
            exit(1); \
        } \
    }

void convertToColumnMajor(const std::vector<double> &rowMajor, std::vector<double> &colMajor, int n) {
    colMajor.resize(n * n);
    for (int i = 0; i < n; ++i) {
        for (int j = 0; j < n; ++j) {
            colMajor[j * n + i] = rowMajor[i * n + j];
        }
    }
}

void readMatrix(const std::string &filename, int &n, std::vector<double> &A, std::vector<double> &b, std::vector<double> &r) {
    std::ifstream infile(filename);
    if (!infile.is_open()) {
        std::cerr << "Failed to open file: " << filename << std::endl;
        exit(1);
    }

    infile >> n;

    A.resize(n * n);
    b.resize(n);
    r.resize(n);

    for (int i = 0; i < n; ++i) {
        for (int j = 0; j < n; ++j) {
            infile >> A[i * n + j];
        }
    }

    infile.ignore(std::numeric_limits<std::streamsize>::max(), '\n'); // Skip empty line

    for (int i = 0; i < n; ++i) {
        infile >> b[i];
    }
    infile.ignore(std::numeric_limits<std::streamsize>::max(), '\n'); // Skip empty line
    for (int i = 0; i < n; ++i) {
        infile >> r[i];
    }
    std::cout << std::endl;

    infile.close();
}

void solveGaussianElimination(int n, const std::vector<double> &A, const std::vector<double> &b, std::vector<double> &x) {
    double *d_A, *d_b;
    int *d_info;
    int *d_ipiv;
    cusolverDnHandle_t cusolverH;
    cudaStream_t stream;

    // Convert matrix to column-major order
    std::vector<double> A_colMajor;
    convertToColumnMajor(A, A_colMajor, n);
    double before = cpuSecond();

    CHECK_CUDA(cudaMalloc((void **)&d_A, n * n * sizeof(double)));
    CHECK_CUDA(cudaMalloc((void **)&d_b, n * sizeof(double)));
    CHECK_CUDA(cudaMalloc((void **)&d_info, sizeof(int)));
    CHECK_CUDA(cudaMalloc((void **)&d_ipiv, n * sizeof(int)));

    CHECK_CUDA(cudaMemcpy(d_A, A_colMajor.data(), n * n * sizeof(double), cudaMemcpyHostToDevice));
    CHECK_CUDA(cudaMemcpy(d_b, b.data(), n * sizeof(double), cudaMemcpyHostToDevice));

    CHECK_CUSOLVER(cusolverDnCreate(&cusolverH));
    CHECK_CUDA(cudaStreamCreate(&stream));
    CHECK_CUSOLVER(cusolverDnSetStream(cusolverH, stream));

    int workspace_size;
    double *d_workspace;

    CHECK_CUSOLVER(cusolverDnDgetrf_bufferSize(cusolverH, n, n, d_A, n, &workspace_size));
    CHECK_CUDA(cudaMalloc((void **)&d_workspace, workspace_size * sizeof(double)));

    // LU Factorization
    CHECK_CUSOLVER(cusolverDnDgetrf(cusolverH, n, n, d_A, n, d_workspace, d_ipiv, d_info));

    // Check if the matrix is singular
    int info_host;
    CHECK_CUDA(cudaMemcpy(&info_host, d_info, sizeof(int), cudaMemcpyDeviceToHost));
    if (info_host != 0) {
        std::cerr << "LU factorization failed, matrix is singular at U(" << info_host << "," << info_host << ")" << std::endl;
        cudaFree(d_A);
        cudaFree(d_b);
        cudaFree(d_info);
        cudaFree(d_ipiv);
        cudaFree(d_workspace);
        cusolverDnDestroy(cusolverH);
        cudaStreamDestroy(stream);
        exit(1);
    }

    // Solve the linear system
    CHECK_CUSOLVER(cusolverDnDgetrs(cusolverH, CUBLAS_OP_N, n, 1, d_A, n, d_ipiv, d_b, n, d_info));

    // Copy the result back to the host
    x.resize(n);
    CHECK_CUDA(cudaMemcpy(x.data(), d_b, n * sizeof(double), cudaMemcpyDeviceToHost));

    // Cleanup
    cudaFree(d_A);
    cudaFree(d_b);
    cudaFree(d_info);
    cudaFree(d_ipiv);
    cudaFree(d_workspace);
    cusolverDnDestroy(cusolverH);
    cudaStreamDestroy(stream);
    std::cout << "Time taken: " << cpuSecond() - before << " seconds" << std::endl;
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        std::cerr << "Usage: " << argv[0] << " <matrix_file>" << std::endl;
        return 1;
    }

    int n;
    std::vector<double> A, b, x, r;
    readMatrix(argv[1], n, A, b, r);

    

    solveGaussianElimination(n, A, b, x);
    
    double largestError = -1;
    for (int i = 0; i < n; ++i) {
        double error = std::abs(x[i] - r[i]);
        if (error > largestError) {
            largestError = error;
        }
    }

    std::cout << "Largest error was " << largestError << std::endl;

    return 0;
}
