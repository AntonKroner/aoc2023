#include "days.h"
#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include <cuda.h>
#include <cuda_runtime.h>
#include <vector_types.h>

static void printDeviceInformation(const int device) {
	struct { int version; const char* name; } architectures[] = {
			{0x30, "Kepler"},
			{0x32, "Kepler"},
			{0x35, "Kepler"},
			{0x37, "Kepler"},
			{0x50, "Maxwell"},
			{0x52, "Maxwell"},
			{0x53, "Maxwell"},
			{0x60, "Pascal"},
			{0x61, "Pascal"},
			{0x62, "Pascal"},
			{0x70, "Volta"},
			{0x72, "Xavier"},
			{0x75, "Turing"},
			{0x80, "Ampere"},
			{0x86, "Ampere"},
			{0x87, "Ampere"},
			{0x89, "Ada"},
			{0x90, "Hopper"},
			{-1, "Graphics Device"} };
	int major = 0;
	int minor = 0;
	cudaDeviceGetAttribute(&major, cudaDevAttrComputeCapabilityMajor, device);
	cudaDeviceGetAttribute(&minor, cudaDevAttrComputeCapabilityMinor, device);
	int index = 0;
	const char* result = 0;
	while (architectures[index].version != -1) {
		if (architectures[index].version == ((major << 4) + minor)) {
			result = architectures[index].name;
		}
		index++;
	}
	if (result) {
		printf("GPU Device %d: \"%s\" with compute capability %d.%d\n\n",
			device, result, major, minor);
	}
	else {
		printf(
			"Architecture for version %d.%d is undefined."
			"  Default to use %s\n",
			major, minor, architectures[index - 1].name);
	}
}
__global__ static void kernel(char* input) {
	char element = input[threadIdx.x];
	input[threadIdx.x] =
		((((element << 0) >> 24) - 10) << 24) | ((((element << 8) >> 24) - 10) << 16) |
		((((element << 16) >> 24) - 10) << 8) | ((((element << 24) >> 24) - 10) << 0);
}
extern "C" void test(size_t length, char* input) {
	printDeviceInformation(0);
	const size_t size = sizeof(char) * length;
	char* deviceData;
	cudaMalloc((void**)&deviceData, size);
	cudaMemcpy(deviceData, input, size, cudaMemcpyHostToDevice);
	const size_t threads = length / 4;
	dim3 grid(1, 1, 1);
	dim3 block(threads, 1, 1);
	size_t shared = 0;
	cudaStream_t stream = 0;
	kernel << <grid, block, shared, stream >> > (deviceData);
	cudaMemcpy(input, deviceData, size, cudaMemcpyDeviceToHost);
	cudaFree(deviceData);
}
