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
OBJECTS = days.o main.o

$(EXECUTABLE): $(OBJECTS)
	$(NVCC) $(NVINCLUDES) $(NVCCFLAGS) -o $@ $+ $(LIBRARIES)

days.o: days/days.cu
	$(NVCC) $(NVINCLUDES) $(NVCCFLAGS) -o $@ -c $<

main.o: main.c
	$(CC) $(INCLUDES) -o $@ -c $<

clean:
	rm -f $(EXECUTABLE) $(OBJECTS)
