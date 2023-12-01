#include <cuda.h>
#include <cuda_runtime.h>
#include <vector_types.h>
#include <vector>
#include <iostream>
#include <fstream>
#include <string>
#include <stdlib.h>
//__device__ static int parseInteger(const char* input) {
//	int result = 0;
//	int index = 0;
//	while (input[index]) {
//		if (input[index] >= '0' || input[index] <= '9') {
//			result = result * 10 + input[index];
//		}
//		index++;
//	}
//	return result;
//}

__device__ static int2 findDigits(const char* input) {
	int2 result = { 0, 0 };
	int digit = 0;
	int index = 0;
	while (input[index]) {
		if (input[index] >= '0' || input[index] <= '9') {
			digit = input[index] - 48;
			if (result.x == 0) { result.x = digit; }
		}
		index++;
	}
	result.y = digit;
	return result;
}
__global__ static void calibrate(const size_t length, const char* input[], int* result) {
	if (threadIdx.x < length) {
		const int2 numbers = findDigits(input[threadIdx.x]);
		result[threadIdx.x] = numbers.x * 10 + numbers.y;
	}
}
void one(const size_t part) {
	std::string line;
	std::ifstream input;
	std::vector<std::string> data;
	std::cout << "aaaa" << std::endl;

	input.open("input.txt");
	if (input.is_open()) {
		std::cout << "file is open" << std::endl;
		while (std::getline(input, line)) {
			data.push_back(line);
			std::cout << line << std::endl;
		}
		input.close();
	}
	else {
		std::cout << "file did not open" << std::endl;

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
	int* results = (int*)malloc(sizeof(int) * data.size());
	cudaMemcpy(results, calibrations, sizeof(int) * data.size(), cudaMemcpyDeviceToHost);
	for (size_t index = 0; data.size() > index; index++) {
		std::cout << results[index] << std::endl;
	}
	free(results);
	cudaFree(deviceData);
}
