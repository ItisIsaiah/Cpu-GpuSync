#include <stdio.h>
#include <stdlib.h>
#include <chrono>
#include <time.h>

void init_matrix(int *d, int N)
{

    printf("\n");
    for (int i = 0; i < N; i++)
    {
        d[i] = (rand() % 10);
    }
}

__global__ void mult_matrix(int *a, int *b, int *c)
{

    int global_index = threadIdx.x + blockDim.x * threadIdx.y;
    c[global_index] = a[global_index] + b[global_index];
}

__global__ void kwait(unsigned long long duration){
    unsigned long long start=clock64();
    while(clock64()< start + duration);
}

int main(int argc, char **argv)
{
    FILE *fptr = fopen("results.txt", "w");
    if (fptr == NULL)
    {
        printf("Error opening file my g");
        exit(1);
    }
    fprintf(fptr, "Spin Method: Duration :Size ");

    int N = 50;
    for (int i = 1; i < argc; i++)
    {
        if (strcmp(argv[i], "-size") == 0 && i + 1 < argc)
        {
            N = atoi(argv[i + 1]);
        }
        else if (strcmp(argv[i], "-sync") == 0 && i + 1 < argc) {
            if (strcmp(argv[i + 1], "spin") == 0)
            {
                cudaSetDeviceFlags(cudaDeviceScheduleSpin);
                fprintf(fptr, "spin: \n");
            }
            else if (strcmp(argv[i + 1], "block") == 0)
            {
                cudaSetDeviceFlags(cudaDeviceScheduleBlockingSync);
                fprintf(fptr, "block: \n");
            }
            else
            {
                printf("\n INVALID SYNC");
            }
        }
    }

    for (int i = 10; i <= N; i += 10)
    {

        clock_t start, end;
        double duration;

        int kernelLaunches; // for input later

        srand(time(NULL));

        for (int j = 1; j < argc; j++)
        {

            if (strcmp(argv[j], "-n") == 0 && j+ 1 < argc)
            {
                kernelLaunches = atoi(argv[j + 1]);
            }
           
        }
        size_t bytes = i * i * sizeof(int);
        int *a, *b, *c;

        cudaMallocManaged(&a, bytes);
        cudaMallocManaged(&b, bytes);
        cudaMallocManaged(&c, bytes);

        int threads = 16;
        int blocks = (i + threads - 1) / threads;

        dim3 THREADS(threads, threads);
        dim3 BLOCKS(blocks, blocks);

        init_matrix(a, i);
        init_matrix(b, i);
        const unsigned long long my_duration= 2000000000ULL;
        start = clock();
        for (int j = 0; j <= kernelLaunches; j++)
        {
           // mult_matrix<<<BLOCKS, THREADS>>>(a, b, c);
            kwait<<<1,1>>>(my_duration);
            int rc=cudaDeviceSynchronize();
            printf("Size: %d During Running %d + %d = %d| rc %d \n",i, a[i-1], b[i-1], c[i-1],rc);
        }

        end = clock();

        duration = ((double)(end - start)) / CLOCKS_PER_SEC;
        printf("Total Duration: %f \n", duration);
        fprintf(fptr, "%f :", duration);

        double avgDuration = duration / kernelLaunches;

        printf("Average time for each kernel: %f", avgDuration);
        fprintf(fptr, " %f :", avgDuration);

        printf("Size %d\n", i);
        fprintf(fptr, "%d\n", i);

        printf("\n %d + %d = %d \n", a[i], b[i], c[i]);

        cudaFree(a);
        cudaFree(b);
        cudaFree(c);
    }
}
