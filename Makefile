CUDA_PATH = /usr/local/cuda

CC = gcc
NVCC = $(CUDA_PATH)/bin/nvcc -ccbin $(CC)

NVCCFLAGS = --threads 0 --std=c++20
NVINCLUDES = -I"$(CUDA_PATH)/include"

CCFLAGS =
LDFLAGS =
INCLUDES = 
LIBRARIES = 

EXECUTABLE = aoc.exe
OBJECTS = main.o days.o one.o two.o three.o

$(EXECUTABLE): $(OBJECTS)
	$(NVCC) $(NVINCLUDES) $(NVCCFLAGS) -o $@ $+ $(LIBRARIES)

days.o: days/days.cu
	$(NVCC) $(NVINCLUDES) $(NVCCFLAGS) -o $@ -c $<

one.o: days/one/one.cu
	$(NVCC) $(NVINCLUDES) $(NVCCFLAGS) -o $@ -c $<

two.o: days/two/two.cu
	$(NVCC) $(NVINCLUDES) $(NVCCFLAGS) -o $@ -c $<

three.o: days/three/three.cu
	$(NVCC) $(NVINCLUDES) $(NVCCFLAGS) -o $@ -c $<
	
main.o: main.c
	$(CC) $(INCLUDES) -o $@ -c $<

clean:
	rm -f $(EXECUTABLE) $(OBJECTS)
