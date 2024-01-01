#include <cuda.h>
#include <cuda_runtime.h>
#include <vector_types.h>
#include <vector>
#include <iostream>
#include <fstream>
#include <string>
#include <stdlib.h>

__device__ static int2 findDigits(const char* input) {
  int2 result = make_int2(0, 0);
  int digit = 0;
  int index = 0;
  while (input[index]) {
    if (input[index] >= '0' && input[index] <= '9') {
      digit = input[index] - 48;
      if (result.x == 0) {
        result.x = digit;
      }
    }
    index++;
  }
  result.y = digit;
  return result;
}
__global__ static void calibrate1(
        const size_t length,
        const size_t* lengths,
        const char* input,
        int* results
) {
  //if (threadIdx.x < length) {[]
  const int2 values = findDigits(&input[lengths[threadIdx.x]]);
  results[threadIdx.x] = values.x * 10 + values.y;
  //}
}
__device__ int2 static findDigits2(const char* input) {
  int2 result = make_int2(0, 0);
  int digit = 0;
  int index = 0;
  const size_t length = 5;
  char buffer[length] = { '0', '0', '0', '0', '0' };
  while (input[index]) {
    if (input[index] >= '0' && input[index] <= '9') {
      digit = input[index] - 48;
      if (result.x == 0) {
        result.x = digit;
      }
    }
    for (size_t i = 0; i < (length - 1); i++) {
      buffer[i] = buffer[i + 1];
    }
    buffer[4] = input[index];
    if (buffer[2] == 'o' && buffer[3] == 'n' && buffer[4] == 'e') {
      digit = 1;
      if (result.x == 0) {
        result.x = digit;
      }
    }
    else if (buffer[2] == 't' && buffer[3] == 'w' && buffer[4] == 'o') {
      digit = 2;
      if (result.x == 0) {
        result.x = digit;
      }
    }
    else if (buffer[0] == 't' && buffer[1] == 'h' && buffer[2] == 'r' && buffer[3] == 'e' && buffer[4] == 'e') {
      digit = 3;
      if (result.x == 0) {
        result.x = digit;
      }
    }
    else if (buffer[1] == 'f' && buffer[2] == 'o' && buffer[3] == 'u' && buffer[4] == 'r') {
      digit = 4;
      if (result.x == 0) {
        result.x = digit;
      }
    }
    else if (buffer[1] == 'f' && buffer[2] == 'i' && buffer[3] == 'v' && buffer[4] == 'e') {
      digit = 5;
      if (result.x == 0) {
        result.x = digit;
      }
    }
    else if (buffer[2] == 's' && buffer[3] == 'i' && buffer[4] == 'x') {
      digit = 6;
      if (result.x == 0) {
        result.x = digit;
      }
    }
    else if (buffer[0] == 's' && buffer[1] == 'e' && buffer[2] == 'v' && buffer[3] == 'e' && buffer[4] == 'n') {
      digit = 7;
      if (result.x == 0) {
        result.x = digit;
      }
    }
    else if (buffer[0] == 'e' && buffer[1] == 'i' && buffer[2] == 'g' && buffer[3] == 'h' && buffer[4] == 't') {
      digit = 8;
      if (result.x == 0) {
        result.x = digit;
      }
    }
    else if (buffer[1] == 'n' && buffer[2] == 'i' && buffer[3] == 'n' && buffer[4] == 'e') {
      digit = 9;
      if (result.x == 0) {
        result.x = digit;
      }
    }
    index++;
  }
  result.y = digit;
  return result;
}
__global__ static void calibrate2(
        const size_t length,
        const size_t* lengths,
        const char* input,
        int* results
) {
  //if (threadIdx.x < length) {[]
  const int2 values = findDigits2(&input[lengths[threadIdx.x]]);
  results[threadIdx.x] = values.x * 10 + values.y;
  //}
}
// This is a very stupid kernel that only computes the correct result *sometimes*. Pls help it get better!!
__global__ static void reduce(const size_t length, const int* calibrations, int* results) {
  results[threadIdx.x] =
          calibrations[threadIdx.x * 2] + calibrations[threadIdx.x * 2 + 1];
  __syncthreads();
  size_t previous = length;
  for (size_t remaining = length; remaining > 1; remaining = 1 + ((remaining - 1) / 2)) {
    if (remaining > threadIdx.x) {
      results[threadIdx.x] =
              results[threadIdx.x * 2]
              + ((threadIdx.x * 2 + 1 < previous) ? results[threadIdx.x * 2 + 1] : 0);
    }
    __syncthreads();
    previous = remaining;
  }
  __syncthreads();
}
void one(const size_t part) {
  std::string line;
  std::ifstream input;
  std::vector<std::string> data;
  input.open("./days/one/input.txt");
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
  for (const std::string& line: data) {
    flattened += (line + '\0');
    lengths.push_back(flattened.size());
  }
  char* deviceFlattened = 0;
  size_t* deviceLengths = 0;
  cudaMalloc(&deviceFlattened, sizeof(char) * flattened.length());
  cudaMalloc(&deviceLengths, sizeof(size_t) * lengths.size());
  cudaMemcpy(
          deviceFlattened,
          flattened.data(),
          sizeof(char) * flattened.length(),
          cudaMemcpyHostToDevice
  );
  cudaMemcpy(
          deviceLengths,
          lengths.data(),
          sizeof(size_t) * lengths.size(),
          cudaMemcpyHostToDevice
  );
  int* calibrations;
  cudaMalloc(&calibrations, sizeof(int) * length);
  const dim3 grid(1, 1, 1);
  const dim3 block(length, 1, 1);
  const size_t shared = 0;
  const cudaStream_t stream = 0;
  if (part == 1) {
    calibrate1<<<grid, block, shared, stream>>>(
            length,
            deviceLengths,
            deviceFlattened,
            calibrations
    );
    std::cout << "part 1" << std::endl;
  }
  else {
    calibrate2<<<grid, block, shared, stream>>>(
            length,
            deviceLengths,
            deviceFlattened,
            calibrations
    );
    std::cout << "part 2" << std::endl;
  }
  int* results;
  cudaMalloc(&results, sizeof(int) * length / 2);
  const dim3 block2(length / 2, 1, 1);
  int* hostCallibrations = (int*)malloc(sizeof(int) * length);
  cudaMemcpy(hostCallibrations, calibrations, sizeof(int) * length, cudaMemcpyDeviceToHost);
  for (size_t i = 0; i < length; i++) {
    std::cout << hostCallibrations[i] << std::endl;
  }
  free(hostCallibrations);
  reduce<<<grid, block2, shared, stream>>>(length, calibrations, results);
  cudaFree(calibrations);
  size_t result;
  cudaMemcpy(&result, &results[0], sizeof(int), cudaMemcpyDeviceToHost);
  std::cout << "result: " << result << std::endl;
  cudaFree(results);
  cudaFree(deviceFlattened);
  cudaFree(deviceLengths);
}
