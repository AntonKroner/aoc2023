#include <cuda.h>
#include <cuda_runtime.h>
#include <vector_types.h>
#include <vector>
#include <iostream>
#include <fstream>
#include <string>
#include <stdlib.h>
#include <algorithm>

__host__ __device__ static inline bool isNumber(const char character) {
	return character >= '0' && character <= '9';
}
__device__ static size_t findDestination(
	const size_t length,
	const size_t sources[],
	const size_t destinations[],
	const size_t ranges[],
	const size_t input
) {
	size_t result = 0;
	for (size_t i = 0; length > i; i++) {
		if (input > sources[i] && sources[i] + ranges[i] > input) {
			result = destinations[i] - sources[i] + input;
			break;
		}
	}
	return result ? result : input;
}
__global__ static void findLocations(
	const size_t* seeds,
	const size_t length,
	const size_t* lengths,
	const size_t* sources,
	const size_t* destinations,
	const size_t* ranges,
	size_t* locations
) {
	size_t result = seeds[threadIdx.x];
	for (size_t i = 0; (length - 1) > i; i++) {
		result = findDestination(lengths[i + 1] - lengths[i], &sources[lengths[i]], &destinations[lengths[i]], &ranges[lengths[i]], result);
	}
	locations[threadIdx.x] = result;
}
std::vector<std::string> splitString(const std::string& string, char delimiter) {
	std::vector<std::string> result;
	size_t start = 0;
	size_t end = string.find(delimiter);
	while (end != std::string::npos) {
		std::string token = string.substr(start, end - start);
		if (!token.empty()) {
			result.push_back(token);
		}
		start = end + 1;
		end = string.find(delimiter, start);
	}
	std::string lastToken = string.substr(start);
	if (!lastToken.empty()) {
		result.push_back(lastToken);
	}
	return result;
}
void day05(const size_t part) {
	std::string line;
	std::ifstream input;
	std::vector<std::string> lines;
	input.open("./days/05/input.txt");
	if (input.is_open()) {
		while (std::getline(input, line)) {
			lines.push_back(line);
		}
		input.close();
	}
	else {
		std::cout << "file did not open" << std::endl;
	}
	std::vector<size_t> seeds;
	std::vector<size_t> lengths;
	std::vector<size_t> sources;
	std::vector<size_t> ranges;
	std::vector<size_t> destinations;
	size_t length = 0;
	for (std::string const& line : lines) {
		if (line.starts_with("seeds: ")) {
			for (std::string const& e : splitString(line.substr(6), ' ')) {
				seeds.push_back(stoul(e));
			}
		}
		else if (line.length() > 1) {
			if (isNumber(line.at(0))) {
				const std::vector<std::string> numbers = splitString(line, ' ');
				destinations.push_back(stoul(numbers.at(0)));
				sources.push_back(stoul(numbers.at(1)));
				ranges.push_back(stoul(numbers.at(2)));
				length++;
			}
		}
		else {
			lengths.push_back(length);
		}
	}
	lengths.push_back(length);
	size_t* deviceSeeds;
	cudaMalloc(&deviceSeeds, sizeof(size_t) * seeds.size());
	cudaMemcpy(deviceSeeds, seeds.data(), sizeof(size_t) * seeds.size(), cudaMemcpyHostToDevice);
	size_t* deviceLengths;
	cudaMalloc(&deviceLengths, sizeof(size_t) * lengths.size());
	cudaMemcpy(deviceLengths, lengths.data(), sizeof(size_t) * lengths.size(), cudaMemcpyHostToDevice);
	size_t* deviceSources;
	cudaMalloc(&deviceSources, sizeof(size_t) * sources.size());
	cudaMemcpy(deviceSources, sources.data(), sizeof(size_t) * sources.size(), cudaMemcpyHostToDevice);
	size_t* deviceRanges;
	cudaMalloc(&deviceRanges, sizeof(size_t) * ranges.size());
	cudaMemcpy(deviceRanges, ranges.data(), sizeof(size_t) * ranges.size(), cudaMemcpyHostToDevice);
	size_t* deviceDestinations;
	cudaMalloc(&deviceDestinations, sizeof(size_t) * destinations.size());
	cudaMemcpy(deviceDestinations, destinations.data(), sizeof(size_t) * destinations.size(), cudaMemcpyHostToDevice);
	size_t* deviceLocations;
	cudaMalloc(&deviceLocations, sizeof(size_t) * seeds.size());
	const dim3 grid(1, 1, 1);
	const dim3 block(seeds.size(), 1, 1);
	const size_t shared = 0;
	const cudaStream_t stream = 0;
	if (part == 1) {
		findLocations << <grid, block, shared, stream >> > (
			deviceSeeds,
			lengths.size(),
			deviceLengths,
			deviceSources,
			deviceDestinations,
			deviceRanges,
			deviceLocations
			);
		std::cout << "part 1" << std::endl;
	}
	else {
		findLocations << <grid, block, shared, stream >> > (
			deviceSeeds,
			lengths.size(),
			deviceLengths,
			deviceSources,
			deviceDestinations,
			deviceRanges,
			deviceLocations
			);
		std::cout << "part 2" << std::endl;
	}
	size_t* locations = (size_t*)malloc(sizeof(size_t) * seeds.size());
	cudaMemcpy(locations, deviceLocations, sizeof(size_t) * seeds.size(), cudaMemcpyDeviceToHost);
	size_t result = locations[0];
	for (size_t i = 0; seeds.size() > i; i++) {
		if (result > locations[i]) result = locations[i];
		std::cout << locations[i] << std::endl;
	}
	std::cout << "Result: " << result << std::endl;
	free(locations);
	cudaFree(deviceSeeds);
	cudaFree(deviceLengths);
	cudaFree(deviceSources);
	cudaFree(deviceDestinations);
	cudaFree(deviceRanges);
	cudaFree(deviceLocations);
}
