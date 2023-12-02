#include <cuda.h>
#include <cuda_runtime.h>
#include <vector_types.h>
#include <vector>
#include <iostream>
#include <fstream>
#include <string>
#include <stdlib.h>

__device__ static int parseInt(const char* string) {
	int result = 0;
	int index = 0;
	while (string[index] >= '0' && string[index] <= '9') {
		result = result * 10 + string[index] - '0';
		index++;
	}
	return result;
}
#define REDMAX 12
#define GREEMMAX 13
#define BLUEMAX 14
__device__ static int game(const char* input) {
	bool success = true;
	int index = 0;
	int amount = 0;
	const int game = parseInt(&input[5]);
	while (input[index] && !(input[index] == ':')) {
		index++;
	}
	index++;
	while (input[index]) {
		if (amount) {
			if (input[index] == 'r') {
				if (amount > REDMAX) {
					success = false;
				}
				amount = 0;
				index += 2;
			}
			if (input[index] == 'g') {
				if (amount > GREEMMAX) {
					success = false;
				}
				amount = 0;
				index += 4;
			}
			if (input[index] == 'b') {
				if (amount > BLUEMAX) {
					success = false;
				}
				amount = 0;
				index += 3;
			}
		}
		else {
			amount = parseInt(&input[index]);
		}
		index++;
	}
	return success ? game : 0;
}
__global__ static void playGames(const size_t length, const size_t* lengths, const char* input, int* results) {
	//if (threadIdx.x < length) {[]
	results[threadIdx.x] = game(&input[lengths[threadIdx.x]]);
//}
}
// This is a very stupid kernel that only computes the correct result *sometimes*. Pls help it get better!!
__global__ static void reduce(const size_t length, const int* games, int* results) {
	results[threadIdx.x] = games[threadIdx.x * 2] + games[threadIdx.x * 2 + 1];
	__syncthreads();
	size_t previous = length;
	for (size_t remaining = length; remaining > 1; remaining = 1 + ((remaining - 1) / 2)) {
		if (remaining > threadIdx.x) {
			results[threadIdx.x] = results[threadIdx.x * 2] + ((threadIdx.x * 2 + 1 < previous) ? results[threadIdx.x * 2 + 1] : 0);
		}
		__syncthreads();
		previous = remaining;
	}
	__syncthreads();
}
void two(const size_t part) {
	std::string line;
	std::ifstream input;
	std::vector<std::string> data;
	input.open("./days/two/input.txt");
	if (input.is_open()) {
		while (std::getline(input, line)) {
			data.push_back(line);
		}
		input.close();
	}
	else {
		std::cout << "file did not open" << std::endl;
	}
	const size_t length = data.size();
	std::string flattened;
	std::vector<size_t> lengths;
	lengths.push_back(0);
	for (std::string const& line : data) {
		flattened += (line + '\0');
		lengths.push_back(flattened.size());
	}
	char* deviceFlattened = 0;
	size_t* deviceLengths = 0;
	cudaMalloc(&deviceFlattened, sizeof(char) * flattened.length());
	cudaMalloc(&deviceLengths, sizeof(size_t) * lengths.size());
	cudaMemcpy(deviceFlattened, flattened.data(), sizeof(char) * flattened.length(), cudaMemcpyHostToDevice);
	cudaMemcpy(deviceLengths, lengths.data(), sizeof(size_t) * lengths.size(), cudaMemcpyHostToDevice);
	int* games;
	cudaMalloc(&games, sizeof(int) * length);
	const dim3 grid(1, 1, 1);
	const dim3 block(length, 1, 1);
	const size_t shared = 0;
	const cudaStream_t stream = 0;
	if (part == 1) {
		playGames << <grid, block, shared, stream >> > (length, deviceLengths, deviceFlattened, games);
		std::cout << "part 1" << std::endl;
	}
	else {
		playGames << <grid, block, shared, stream >> > (length, deviceLengths, deviceFlattened, games);
		std::cout << "part 2" << std::endl;
	}
	int* results;
	cudaMalloc(&results, sizeof(int) * length / 2);
	const dim3 block2(length / 2, 1, 1);
	int* hostCallibrations = (int*)malloc(sizeof(int) * length);
	cudaMemcpy(hostCallibrations, games, sizeof(int) * length, cudaMemcpyDeviceToHost);
	for (size_t i = 0; i < length; i++) {
		std::cout << hostCallibrations[i] << std::endl;
	}
	free(hostCallibrations);
	reduce << <grid, block2, shared, stream >> > (length, games, results);
	cudaFree(games);
	size_t result;
	cudaMemcpy(&result, &results[0], sizeof(int), cudaMemcpyDeviceToHost);
	std::cout << "result: " << result << std::endl;
	cudaFree(results);
	cudaFree(deviceFlattened);
	cudaFree(deviceLengths);
}
