/**
 * @file vector_add.cu
 * @brief Vector Addition comparing CUDA GPU vs CPU performance
 * 
 * This program demonstrates the performance difference between GPU-accelerated and CPU-based
 * computation of vector addition, a fundamental operation that computes:
 * c[i] = a[i] + b[i] for all elements i
 * 
 * COMPILATION:
 * ------------
 * 
 * 1. Basic compilation:
 *    nvcc -o vector_add vector_add.cu -std=c++17 -Wno-deprecated-gpu-targets
 *    Execution: ./vector_add
 *
 * 2. Debug build for GDB (CPU debugging):
 *    nvcc -o vector_add vector_add.cu -std=c++17 -g -G -Xcompiler -g -Wno-deprecated-gpu-targets
 *    
 *    Flags explanation:
 *    -g         : Generate host debug information
 *    -G         : Generate device debug information (disables optimizations)
 *    -Xcompiler -g : Pass -g flag to host compiler for CPU code debugging
 *    -Wno-deprecated-gpu-targets : Suppress warnings about deprecated GPU architectures
 *    
 *    Usage: gdb ./vector_add
 *    Common GDB commands:
 *    - break main : Set breakpoint at main function
 *    - run        : Start program execution
 *    - next       : Execute next line
 *    - print var  : Print variable value
 *    - backtrace  : Show call stack
 * 
 * 3. Debug build for CUDA-GDB (GPU debugging):
 *    nvcc -o vector_add vector_add.cu -std=c++17 -g -G -Wno-deprecated-gpu-targets
 *    
 *    Flags explanation:
 *    -g         : Generate host debug information
 *    -G         : Generate device debug information (includes line info, disables optimizations)
 *    
 *    Usage with CUDA-GDB:
 *    1. Launch CUDA-GDB with the executable:
 *       cuda-gdb ./vector_add
 *    
 *    2. Set a breakpoint in the kernel:
 *       (cuda-gdb) break vectorAddGPU
 *    
 *    3. Run the program:
 *       (cuda-gdb) run
 *    
 *    4. Once the breakpoint is hit, you can use CUDA-specific commands:
 *       (cuda-gdb) cuda thread       # Show current CUDA thread
 *       (cuda-gdb) cuda block        # Show current CUDA block
 *       (cuda-gdb) info cuda threads # List all CUDA threads
 *       (cuda-gdb) cuda device       # Show current device
 *    
 *    5. Other useful CUDA-GDB commands:
 *       (cuda-gdb) cuda thread (1,0,0)    # Switch to specific thread
 *       (cuda-gdb) cuda block (x,y,z)     # Switch to specific block
 *       (cuda-gdb) info cuda blocks       # List all CUDA blocks
 *       (cuda-gdb) info cuda devices      # List CUDA devices
 *       (cuda-gdb) set cuda memcheck on   # Enable memory error checking
 * 
 * 4. Debug with memory checking (requires NVIDIA CUDA toolkit):
 *    nvcc -o vector_add vector_add.cu -std=c++17 -g -G -Xcompiler -rdynamic -Wno-deprecated-gpu-targets
 *    
 *    Note: compute-sanitizer requires the Ubuntu-packaged NVIDIA CUDA Toolkit:
 *    sudo apt install -y nvidia-cuda-toolkit
 *    
 *    (Note: Installing just 'cuda-toolkit' package is not enough, you need
 *    the Ubuntu-packaged 'nvidia-cuda-toolkit' which includes cuda-memcheck in PATH)
 *    
 *    Run with cuda-memcheck:
 *    compute-sanitizer ./vector_add                   # Basic memory error checking
 *    compute-sanitizer --tool racecheck ./vector_add  # Race condition detection
 *    compute-sanitizer --tool initcheck ./vector_add  # Uninitialized memory access
 *    compute-sanitizer --leak-check full ./vector_add # Memory leak detection
 *    
 *    Alternative: For basic memory error detection without cuda-memcheck,
 *    you can add the following line before kernel launches:
 *    cudaError_t error = cudaGetLastError();
 *    if(error != cudaSuccess) printf("CUDA Error: %s\n", cudaGetErrorString(error));
 *    
 *    Fixing "ERR_NVGPUCTRPERM" Permission Error:
 *    If you get "ERR_NVGPUCTRPERM" errors when using cuda-memcheck or compute-sanitizer,
 *    the simplest solution is to run the tool with sudo:
 *    
 *    sudo compute-sanitizer ./vector_add
 * 
 * 5. Profiling build:
 *    nvcc -o vector_add vector_add.cu -std=c++17 -lineinfo -Wno-deprecated-gpu-targets
 *    
 *    Note: Do not combine -G and -lineinfo as they conflict (-G includes line info)
 *    
 *    Run with Nsight Systems:
 *    sudo nsys profile -o vector_add_profile ./vector_add
 *    
 *    Run with Nsight Compute:
 *    ncu -o vector_add_metrics ./vector_add
 * 
 * COMMON COMPILATION FLAGS:
 * ------------------------
 * -arch=sm_XX     : Target specific GPU architecture
 * -Xcompiler      : Pass flags to host compiler
 * -Xptxas         : Pass flags to PTX assembler
 * -maxrregcount=N : Limit registers per thread
 * -use_fast_math  : Use faster, less precise math functions
 * --ptxas-options=-v : Show register and memory usage
 * 
 * EXECUTION:
 * ----------
 * ./vector_add
 * 
 * The program automatically generates random parameters:
 * - N: Vector size (1 to 100 million elements)
 * - A_MIN, A_MAX: Range for values in array A
 * - B_MIN, B_MAX: Range for values in array B
 * 
 * OUTPUT:
 * -------
 * The program will display:
 * 1. Randomly generated parameters
 * 2. CUDA kernel execution time
 * 3. CPU execution time  
 * 4. Performance comparison (speedup)
 * 5. First 10 results from both implementations
 * 
 * REQUIREMENTS:
 * -------------
 * - NVIDIA GPU with CUDA support
 * - CUDA Toolkit installed (nvcc compiler)
 * - C++17 compatible compiler
 * - Sufficient GPU memory for large vector sizes
 * 
 * MEMORY REQUIREMENTS:
 * -------------------
 * For N elements, the program requires:
 * - Host memory: 4*N*sizeof(int) bytes (a, b, c_gpu, c_cpu)
 * - Device memory: 3*N*sizeof(int) bytes (d_a, d_b, d_c)
 * 
 * Example: For N=100M, requires ~1.6GB host memory and ~1.2GB GPU memory
 */

#include <iostream>
#include <cstdlib>
#include <cstring>
#include <stdio.h>
#include <random>

using namespace std;

// CUDA error checking macro with better error reporting
#define CUDA_CHECK(call) do { \
    cudaError_t err = call; \
    if (err != cudaSuccess) { \
        printf("CUDA Error at %s:%d\n", __FILE__, __LINE__); \
        printf("Error code: %d\n", err); \
        printf("Error string: %s\n", cudaGetErrorString(err)); \
        printf("Error description: %s\n", cudaGetErrorName(err)); \
        cudaDeviceReset(); \
        exit(EXIT_FAILURE); \
    } \
} while (0)

/**
 * @brief CUDA kernel for performing vector addition
 * 
 * This kernel performs the computation: c[i] = a[i] + b[i] for all elements
 * in parallel on the GPU.
 * 
 * @param a      Input vector a (device memory pointer)
 * @param b      Input vector b (device memory pointer)
 * @param c      Output vector c (device memory pointer)
 * @param n      The number of elements in the vectors
 * 
 * @note __global__ indicates this function runs on the GPU and is callable from CPU
 */
__global__ void vectorAddGPU(const int *a, const int *b, int *c, int n)
{
    // Calculate global thread ID
    int i = blockIdx.x * blockDim.x + threadIdx.x;
   
    // Boundary check
    if (i < n)
    {
        // Perform addition
        c[i] = a[i] + b[i];
    }
}

/**
 * CPU version of vector addition
 */
void vectorAddCPU(const int *a, const int *b, int *c, int n)
{
    for (int i = 0; i < n; i++)
    {
        c[i] = a[i] + b[i];
    }
}

int main() {
    // Seed the random number generator
    std::random_device rd;
    std::mt19937 gen(rd());
    
    // Generate random size between 1 and 100 million
    std::uniform_int_distribution<> dis_N(1, 100000000);
    std::uniform_int_distribution<> dis_A_range(1, 100);
    std::uniform_int_distribution<> dis_B_range(1, 100);
    
    int N = dis_N(gen);
    int A_MIN = dis_A_range(gen);
    int A_MAX = A_MIN + dis_A_range(gen);
    int B_MIN = dis_B_range(gen);
    int B_MAX = B_MIN + dis_B_range(gen);
    
    std::cout << "Randomly generated parameters:\n";
    std::cout << "N: " << N << " (size in millions: " << N/1000000.0 << "M)" << std::endl;
    std::cout << "A range: " << A_MIN << " to " << A_MAX << std::endl;
    std::cout << "B range: " << B_MIN << " to " << B_MAX << std::endl;
    std::cout << "-----------------------------\n";
    
    // Allocate host memory
    int *a = new int[N];
    int *b = new int[N];
    int *c_gpu = new int[N];
    int *c_cpu = new int[N];
    
    // Initialize arrays with random values
    std::uniform_int_distribution<> dis_A(A_MIN, A_MAX);
    std::uniform_int_distribution<> dis_B(B_MIN, B_MAX);
    
    for (int i = 0; i < N; i++) {
        a[i] = dis_A(gen);
        b[i] = dis_B(gen);
    }
    
    // Check for CUDA device
    int deviceCount = 0;
    CUDA_CHECK(cudaGetDeviceCount(&deviceCount));
    if (deviceCount == 0) {
        printf("ERROR: No CUDA-capable devices found!\n");
        return 1;
    }
    
    // Set and display device properties
    int device = 0;
    CUDA_CHECK(cudaSetDevice(device));
    
    cudaDeviceProp prop;
    CUDA_CHECK(cudaGetDeviceProperties(&prop, device));
    printf("Using GPU: %s\n", prop.name);
    printf("Compute capability: %d.%d\n", prop.major, prop.minor);
    
    // Reset device to clear any previous errors
    CUDA_CHECK(cudaDeviceReset());
    CUDA_CHECK(cudaSetDevice(device));
    
    printf("-----------------------------\n");
    
    int sizeInBytes = N * sizeof(int);
    
    // Check for available GPU memory
    size_t free_byte, total_byte;
    CUDA_CHECK(cudaMemGetInfo(&free_byte, &total_byte));
    
    printf("GPU Memory Info:\n");
    printf("Total GPU memory: %.2f MB\n", total_byte / (1024.0 * 1024.0));
    printf("Free GPU memory: %.2f MB\n", free_byte / (1024.0 * 1024.0));
    printf("Required GPU memory: %.2f MB\n", (3 * sizeInBytes) / (1024.0 * 1024.0));
    printf("-----------------------------\n");
    
    // Check if we have enough memory
    if (3 * sizeInBytes > free_byte) {
        printf("ERROR: Not enough GPU memory! Need %.2f MB but only %.2f MB available\n",
               (3 * sizeInBytes) / (1024.0 * 1024.0), free_byte / (1024.0 * 1024.0));
        // Adjust N to fit available memory
        int max_elements = (free_byte * 0.8) / (3 * sizeof(int)); // Use 80% of available memory
        printf("Adjusting N from %d to %d to fit in available GPU memory\n", N, max_elements);
        N = max_elements;
        sizeInBytes = N * sizeof(int);
        
        // Reallocate host memory with new size
        delete[] a;
        delete[] b;
        delete[] c_gpu;
        delete[] c_cpu;
        
        a = new int[N];
        b = new int[N];
        c_gpu = new int[N];
        c_cpu = new int[N];
        
        // Re-initialize arrays with new size
        for (int i = 0; i < N; i++) {
            a[i] = dis_A(gen);
            b[i] = dis_B(gen);
        }
    }
    
    // Allocate GPU memory
    int *d_a = nullptr, *d_b = nullptr, *d_c = nullptr;
    
    printf("Attempting to allocate GPU memory...\n");
    
    CUDA_CHECK(cudaMalloc((void**)&d_a, sizeInBytes));
    CUDA_CHECK(cudaMalloc((void**)&d_b, sizeInBytes));
    CUDA_CHECK(cudaMalloc((void**)&d_c, sizeInBytes));
    
    printf("Successfully allocated all GPU memory\n");
    printf("-----------------------------\n");
    
    // Copy data to GPU
    CUDA_CHECK(cudaMemcpy(d_a, a, sizeInBytes, cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaMemcpy(d_b, b, sizeInBytes, cudaMemcpyHostToDevice));
    
    // Create CUDA events for timing
    cudaEvent_t start_gpu, stop_gpu, start_cpu, stop_cpu;
    CUDA_CHECK(cudaEventCreate(&start_gpu));
    CUDA_CHECK(cudaEventCreate(&stop_gpu));
    CUDA_CHECK(cudaEventCreate(&start_cpu));
    CUDA_CHECK(cudaEventCreate(&stop_cpu));
    
    // Set up kernel launch parameters
    int blockSize = 256;
    int numBlocks = (N + blockSize - 1) / blockSize;
    
    // Run and time GPU kernel
    CUDA_CHECK(cudaEventRecord(start_gpu));
    vectorAddGPU<<<numBlocks, blockSize>>>(d_a, d_b, d_c, N);
    CUDA_CHECK(cudaEventRecord(stop_gpu));
    CUDA_CHECK(cudaEventSynchronize(stop_gpu));
    
    float milliseconds_gpu = 0;
    CUDA_CHECK(cudaEventElapsedTime(&milliseconds_gpu, start_gpu, stop_gpu));
    printf("GPU elapsed time is %.3f milliseconds (%.3f seconds).\n", 
           milliseconds_gpu, milliseconds_gpu / 1000.0);
    
    // Copy result back to host
    CUDA_CHECK(cudaMemcpy(c_gpu, d_c, sizeInBytes, cudaMemcpyDeviceToHost));
    
    // Run and time CPU version
    CUDA_CHECK(cudaEventRecord(start_cpu));
    vectorAddCPU(a, b, c_cpu, N);
    CUDA_CHECK(cudaEventRecord(stop_cpu));
    CUDA_CHECK(cudaEventSynchronize(stop_cpu));
    
    float milliseconds_cpu = 0;
    CUDA_CHECK(cudaEventElapsedTime(&milliseconds_cpu, start_cpu, stop_cpu));
    printf("CPU elapsed time is %.3f milliseconds (%.3f seconds).\n", 
           milliseconds_cpu, milliseconds_cpu / 1000.0);
    
    // Verify correctness
    printf("\nVerifying correctness (comparing CPU and GPU results):\n");
    bool correct = true;
    for (int i = 0; i < N; ++i) {
        if (c_gpu[i] != c_cpu[i]) {
            printf("Mismatch at index %d: GPU=%d, CPU=%d\n", i, c_gpu[i], c_cpu[i]);
            correct = false;
            break;
        }
    }
    
    if (correct) {
        printf("Results match! All computations are correct.\n");
    }
    
    // Performance comparison
    float speedup = milliseconds_cpu / milliseconds_gpu;
    printf("\nPerformance comparison:\n");
    printf("GPU vs CPU speedup: %.2fx\n", speedup);
    
    // Print first 10 results
    printf("\nFirst 10 results (A + B = GPU | CPU):\n");
    for (int i = 0; i < 10 && i < N; i++) {
        printf("%d + %d = %d | %d\n", a[i], b[i], c_gpu[i], c_cpu[i]);
    }
    
    // Clean up CUDA events
    CUDA_CHECK(cudaEventDestroy(start_gpu));
    CUDA_CHECK(cudaEventDestroy(stop_gpu));
    CUDA_CHECK(cudaEventDestroy(start_cpu));
    CUDA_CHECK(cudaEventDestroy(stop_cpu));
    
    // Free GPU memory
    CUDA_CHECK(cudaFree(d_a));
    CUDA_CHECK(cudaFree(d_b));
    CUDA_CHECK(cudaFree(d_c));
    
    // Free host memory
    delete[] a;
    delete[] b;
    delete[] c_gpu;
    delete[] c_cpu;
    
    // Synchronize device
    CUDA_CHECK(cudaDeviceSynchronize());
    
    return 0;
}
