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
__device__ static inline bool isSymbol(const char character) {
	return character < '.' || character > '9' || character == '/';
}
__device__ static int sumRow(const size_t length, const char* rows) {
	int result = 0;
	int value = 0;
	for (size_t index = 1; (length - 1) > index; index++) {
		if (!value) {
			value = parseInt(&rows[length + index]);
		}
		if (value) {
			if (rows[length + index] >= '0' && rows[length + index] <= '9') {
				if (
					isSymbol(rows[index - 1]) ||
					isSymbol(rows[index]) ||
					isSymbol(rows[index + 1]) ||
					isSymbol(rows[length + index - 1]) ||
					isSymbol(rows[length + index + 1]) ||
					isSymbol(rows[2 * length + index - 1]) ||
					isSymbol(rows[2 * length + index]) ||
					isSymbol(rows[2 * length + index + 1])
					) {
					result += value;
					value = 0;
					while (rows[length + index] >= '0' && rows[length + index] <= '9') {
						index++;
					}
				}
			}
			else if (rows[length + index] == '.') {
				value = 0;
			}
		}
	}
	return result;
}
__global__ static void sumRows(const ulong2 dimensions, const char* rows, int* results) {
	//if (threadIdx.x < length) {[]
	results[threadIdx.x] = sumRow(dimensions.x, &rows[dimensions.x * threadIdx.x]);
//}
}
__device__ static inline bool isNumber(const char character) {
	return character >= '0' && character <= '9';
}
__device__ static int sumRowRatio(const size_t length, const char* rows) {
	int result = 0;
	for (size_t index = 1; (length - 1) > index; index++) {
		if (rows[length + index] == '*') {
			int ratio = 1;
			size_t found = 0;
			if (isNumber(rows[length + index + 1])) {
				found++;
				ratio = ratio * parseInt(&rows[length + index + 1]);
			}
			if (isNumber(rows[length + index - 1])) {
				found++;
				int numberStartIndex = length + index - 1;
				while (isNumber(rows[numberStartIndex - 1])) {
					numberStartIndex--;
				}
				ratio = ratio * parseInt(&rows[numberStartIndex]);
			}
			if (isNumber(rows[index - 1])) {
				found++;
				int numberStartIndex = index - 1;
				while (isNumber(rows[numberStartIndex - 1])) {
					numberStartIndex--;
				}
				ratio = ratio * parseInt(&rows[numberStartIndex]);
			}
			if (isNumber(rows[index]) && !isNumber(rows[index - 1])) {
				found++;
				ratio = ratio * parseInt(&rows[index]);
			}
			if (isNumber(rows[index + 1]) && !isNumber(rows[index])) {
				found++;
				ratio = ratio * parseInt(&rows[index + 1]);
			}
			if (isNumber(rows[2 * length + index - 1])) {
				found++;
				int numberStartIndex = 2 * length + index - 1;
				while (isNumber(rows[numberStartIndex - 1])) {
					numberStartIndex--;
				}
				ratio = ratio * parseInt(&rows[numberStartIndex]);
			}
			if (isNumber(rows[2 * length + index]) && !isNumber(rows[2 * length + index - 1])) {
				found++;
				ratio = ratio * parseInt(&rows[2 * length + index]);
			}
			if (isNumber(rows[2 * length + index + 1]) && !isNumber(rows[2 * length + index])) {
				found++;
				ratio = ratio * parseInt(&rows[2 * length + index + 1]);
			}
			result = found == 2 ? result + ratio : result;
		}
	}
	return result;
}
__global__ static void findGears(const ulong2 dimensions, const char* rows, int* results) {
	//if (threadIdx.x < length) {[]
	results[threadIdx.x] = sumRowRatio(dimensions.x, &rows[dimensions.x * threadIdx.x]);
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
		previous = remaining;
		__syncthreads();
	}
	__syncthreads();
	if (threadIdx.x == 0) {
		results[threadIdx.x] = results[threadIdx.x * 2] + ((threadIdx.x * 2 + 1 < previous) ? results[threadIdx.x * 2 + 1] : 0);
	}
	__syncthreads();
}
void three(const size_t part) {
	std::string line;
	std::ifstream input;
	std::vector<std::string> lines;
	input.open("./days/three/input.txt");
	if (input.is_open()) {
		while (std::getline(input, line)) {
			lines.push_back(line);
		}
		input.close();
	}
	else {
		std::cout << "file did not open" << std::endl;
	}
	const ulong2 dimensions = ulong2(lines.at(0).size() + 2, lines.size() + 2);
	std::string schematic;
	schematic.append(dimensions.x, '.');
	for (std::string const& line : lines) {
		schematic += ('.' + line + '.');
	}
	schematic.append(dimensions.x, '.');
	char* deviceSchematic = 0;
	cudaMalloc(&deviceSchematic, sizeof(char) * (dimensions.x) * (dimensions.y));
	cudaMemcpy(deviceSchematic, schematic.data(), sizeof(char) * (dimensions.x) * (dimensions.y), cudaMemcpyHostToDevice);
	int* rowTotals;
	cudaMalloc(&rowTotals, sizeof(int) * dimensions.y - 2);
	const dim3 grid(1, 1, 1);
	const dim3 block(dimensions.y - 2, 1, 1);
	const size_t shared = 0;
	const cudaStream_t stream = 0;
	if (part == 1) {
		sumRows << <grid, block, shared, stream >> > (dimensions, deviceSchematic, rowTotals);
		std::cout << "part 1" << std::endl;
	}
	else {
		findGears << <grid, block, shared, stream >> > (dimensions, deviceSchematic, rowTotals);
		std::cout << "part 2" << std::endl;
	}
	int* results;
	cudaMalloc(&results, sizeof(int) * dimensions.y / 2);
	const dim3 block2(dimensions.y - 2 / 2, 1, 1);
	int* hostRowTotals = (int*)malloc(sizeof(int) * dimensions.y - 2);
	cudaMemcpy(hostRowTotals, rowTotals, sizeof(int) * dimensions.y - 2, cudaMemcpyDeviceToHost);
	for (size_t i = 0; i < dimensions.y - 2; i++) {
		std::cout << hostRowTotals[i] << std::endl;
	}
	free(hostRowTotals);
	reduce << <grid, block2, shared, stream >> > (dimensions.y - 2, rowTotals, results);
	//int* hostReduceVector = (int*)malloc(sizeof(int) * dimensions.y - 2);
	//cudaMemcpy(hostReduceVector, results, sizeof(int) * dimensions.y - 2, cudaMemcpyDeviceToHost);
	//for (size_t i = 0; i < dimensions.y - 2; i++) {
	//	std::cout << hostReduceVector[i] << std::endl;
	//}
	//free(hostReduceVector);
	cudaFree(rowTotals);
	size_t result;
	cudaMemcpy(&result, &results[0], sizeof(int), cudaMemcpyDeviceToHost);
	std::cout << "result: " << result << std::endl;
	cudaFree(results);
	cudaFree(deviceSchematic);
}
