#include <cuda.h>
#include <cuda_runtime.h>
#include <vector_types.h>
#include <vector>
#include <iostream>
#include <fstream>
#include <string>

__device__ static int parseInteger(const char* input) {
	int result = 0;
	int index = 0;
	while (input[index]) {
		if (
			input[index] == '0' ||
			input[index] == '1' ||
			input[index] == '2' ||
			input[index] == '3' ||
			input[index] == '4' ||
			input[index] == '5' ||
			input[index] == '6' ||
			input[index] == '7' ||
			input[index] == '8' ||
			input[index] == '9'
			) {
			result = result * 10 + input[index];
		}
		index++;
	}

// return result.
	return result;

}

__device__ static int2 findNumbers(const char* string) {
	int2 result;
	result.x = 0;
	result.y = 0;
	return result;
}
__global__ static void calibrate(const size_t length, const char* input[], int* result) {
	if (threadIdx.x < length) {
		const int2 numbers = findNumbers(input[threadIdx.x]);
		result[threadIdx.x] = numbers.x + numbers.y;
	}
}
void one(const size_t part) {
	std::string line;
	std::ifstream input;
	std::vector<std::string> data;
	input.open("input.txt", std::ios::out);
	if (input.is_open()) {
		while (std::getline(input, line)) {
			data.push_back(line);
		}
		input.close();
	}
	const size_t length = data.size();
	const char** deviceData = 0;
	cudaMalloc(&deviceData, sizeof(char*) * data.size());
	cudaMemcpy(deviceData, data.data(), sizeof(char*) * data.size(), cudaMemcpyHostToDevice);
	int* calibrations = 0;
	cudaMalloc(&calibrations, sizeof(int) * data.size());
	const size_t threads = data.size();;
	dim3 grid(1, 1, 1);
	dim3 block(threads, 1, 1);
	size_t shared = 0;
	cudaStream_t stream = 0;
	calibrate << <grid, block, shared, stream >> > (length, deviceData, calibrations);
	cudaFree(deviceData);
}
