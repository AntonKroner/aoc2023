#include <vector>
#include <cuda.h>
#include <cuda_runtime.h>

template<typename T> class Vector {
  private:
    __device__ T* elements;
    __device__ size_t length;
  public:
    Vector(T element) {
      this->length = 1;
      cudaMalloc(this.elements, sizeof(T));
      this->elements[0] = element;
    }
    Vector(size_t length, T* elements) {
      this->length = length;
      cudaMalloc(this->elements, sizeof(T) * length);
      cudaMemcpy(this->elements, elements, sizeof(T) * length, cudaMemcpyHostToDevice);
    }
    Vector(std::vector<T> vector) {
      this->length = vector.size();
      cudaMalloc(this->elements, sizeof(T) * this->length);
      cudaMemcpy(
              this->elements,
              vector.data(),
              sizeof(T) * this->length,
              cudaMemcpyHostToDevice
      );
    }
    ~vectorClass() {
      cudaFree(this->elements);
    }
    __host__ size_t push(size_t length, T* elements) {
      T* newElements;
      cudaMalloc(newElements, sizeof(T) * (this->length + length));
      cudaMemcpy(
              newElements,
              this->elements,
              sizeof(T) * this->length,
              cudaMemcpyHostToDevice
      );
      cudaMemcpy(
              &newElements[this->length],
              elements,
              sizeof(T) * length,
              cudaMemcpyHostToDevice
      );
      cudaFree(this->elements);
      this->elements = newElements;
      this->length += length;
    }
    template<typename R> __device__ Vector<R> map(
            R (*mapper)(T),
            size_t thread,
            size_t threads,
            R (&shared)[this->length]
    ) {
      R result[this->length];
      for (size_t i = 0; this->length > i; i++) {
        result[i] = mapper(this->elements[i]);
      }
      return Vector<R>(this->length, result);
    }
};
