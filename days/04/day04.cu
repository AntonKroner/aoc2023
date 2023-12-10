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
__device__ static inline bool isNumber(const char character) {
	return character >= '0' && character <= '9';
}
__device__ static int findRowMatches(const char* row) {
	size_t i = 0;
	while (row[i] && row[i] != ':') {
		i++;
	}
	const size_t winnersLength = 10;
	size_t winners[winnersLength];
	size_t w = 0;
	while (row[i] && row[i] != '|') {
		if (isNumber(row[i])) {
			winners[w++] = parseInt(&row[i]);
			while (row[i] && isNumber(row[i])) {
				i++;
			}
		}
		i++;
	}
	const size_t numbersLength = 25;
	size_t numbers[numbersLength];
	size_t n = 0;
	while (row[i] && numbersLength > n) {
		if (isNumber(row[i])) {
			numbers[n++] = parseInt(&row[i]);
			while (row[i] && isNumber(row[i])) {
				i++;
			}
		}
		i++;
	}
	size_t matches = 0;
	for (size_t i = 0; numbersLength > i; i++) {
		for (size_t j = 0; winnersLength > j; j++) {
			if (numbers[i] == winners[j]) {
				matches++;
			}
		}
	}
	return matches ? 1 << (matches - 1) : 0;
}
__global__ static void matchCards(const size_t length, const size_t* lengths, const char* input, size_t* results) {
	//if (threadIdx.x < length) {[]
	const size_t result = findRowMatches(&input[lengths[threadIdx.x]]);
	results[threadIdx.x] = result ? 1 << (result - 1) : 0;
//}
}

//__global__ static void matchCards2(const size_t length, const size_t* lengths, const char* input, size_t* results) {
//	//if (threadIdx.x < length) {[]
//	size_t additional = results[threadIdx.x] = findRowMatches(&input[lengths[threadIdx.x]]);
//	__syncthreads();
//	for (size_t i = threadIdx.x; (threadIdx.x + results[threadIdx.x]) > i && length > i; i++) {
//		size_t matches = results[i];
//		while (matches) {
//			additional += matches;
//			matches--;
//		}
//	}
////}
//}
// This is a very stupid kernel that only computes the correct result *sometimes*. Pls help it get better!!
__global__ static void reduce(const size_t length, const size_t* input, size_t* results) {
	size_t previous = length;
	results[threadIdx.x] = input[threadIdx.x * 2] + ((threadIdx.x * 2 + 1 < previous) ? input[threadIdx.x * 2 + 1] : 0);
	__syncthreads();
	for (size_t remaining = length; remaining > 1; remaining = 1 + ((remaining - 1) / 2)) {
		if (remaining > threadIdx.x) {
			results[threadIdx.x] = results[threadIdx.x * 2] + ((threadIdx.x * 2 + 1 < previous) ? results[threadIdx.x * 2 + 1] : 0);
		}
		previous = remaining;
		__syncthreads();
	}
	__syncthreads();
	if (threadIdx.x == 0) {
		results[threadIdx.x] = results[threadIdx.x * 2] + ((threadIdx.x * 2 + 1 < previous) ? results[threadIdx.x * 2 + 1] : 0);
	}
	__syncthreads();
}
void day04(const size_t part) {
	std::string line;
	std::ifstream input;
	std::vector<std::string> lines;
	input.open("./days/4/input.txt");
	if (input.is_open()) {
		while (std::getline(input, line)) {
			lines.push_back(line);
		}
		input.close();
	}
	else {
		std::cout << "file did not open" << std::endl;
	}
	const size_t length = lines.size();
	std::string flattened;
	std::vector<size_t> lengths;
	lengths.push_back(0);
	for (std::string const& line : lines) {
		flattened += (line + '\0');
		lengths.push_back(flattened.size());
	}
	char* deviceFlattened = 0;
	size_t* deviceLengths = 0;
	cudaMalloc(&deviceFlattened, sizeof(char) * flattened.length());
	cudaMalloc(&deviceLengths, sizeof(size_t) * lengths.size());
	cudaMemcpy(deviceFlattened, flattened.data(), sizeof(char) * flattened.length(), cudaMemcpyHostToDevice);
	cudaMemcpy(deviceLengths, lengths.data(), sizeof(size_t) * lengths.size(), cudaMemcpyHostToDevice);
	size_t* matches;
	cudaMalloc(&matches, sizeof(size_t) * length);
	const dim3 grid(1, 1, 1);
	const dim3 block(length, 1, 1);
	const size_t shared = 0;
	const cudaStream_t stream = 0;
	if (part == 1) {
		matchCards << <grid, block, shared, stream >> > (length, deviceLengths, deviceFlattened, matches);
		std::cout << "part 1" << std::endl;
	}
	else {
		matchCards << <grid, block, shared, stream >> > (length, deviceLengths, deviceFlattened, matches);
		std::cout << "part 2" << std::endl;
	}
	size_t* results;
	cudaMalloc(&results, sizeof(size_t) * 1 + ((length - 1) / 2));
	const dim3 block2(1 + ((length - 1) / 2), 1, 1);
	size_t* hostMatches = (size_t*)malloc(sizeof(size_t) * length);
	cudaMemcpy(hostMatches, matches, sizeof(size_t) * length, cudaMemcpyDeviceToHost);
	for (size_t i = 0; i < length; i++) {
		std::cout << hostMatches[i] << std::endl;
	}
	free(hostMatches);
	reduce << <grid, block2, shared, stream >> > (length, matches, results);
	cudaFree(matches);
	size_t result;
	cudaMemcpy(&result, &results[0], sizeof(int), cudaMemcpyDeviceToHost);
	std::cout << "result: " << result << std::endl;
	cudaFree(results);
	cudaFree(deviceFlattened);
	cudaFree(deviceLengths);
}
