#include <stdlib.h>
#include <cuda.h>
#include <cuda_runtime.h>
#include <vector_types.h>
#include <string>

class String {
  private:
    __device__ char* characters;
    __device__ size_t length;
    String(std::string string) {
      const size_t length = string.size();
      cudaMalloc(&characters, sizeof(char) * length);
      cudaMemcpy(
              this->characters,
              string.data(),
              sizeof(char) * length,
              cudaMemcpyHostToDevice
      );
      cudaMemcpy(&(this->length), &length, sizeof(size_t), cudaMemcpyHostToDevice);
    }
  public:
    __device__ __inline_hint__ size_t length() {
      return this->length;
    }
    __host__ std::string toHost() {
      size_t length = 0;
      cudaMemcpy(&(length), &(this->length), sizeof(size_t), cudaMemcpyDeviceToHost);
      char* characters = (char*)malloc(sizeof(char) * length);
      cudaMemcpy(
              characters,
              this->characters,
              sizeof(char) * length,
              cudaMemcpyDeviceToHost
      );
      std::string result = std::string(characters, length);
      free(characters);
      return result;
    }

    __host__ static String open(std::string string) {
      return String(string);
    }
};
