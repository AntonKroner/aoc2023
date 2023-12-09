CUDA_PATH = /usr/local/cuda
NVCC = $(CUDA_PATH)/bin/nvcc -ccbin g++ -Werror all-warnings
NVCCFLAGS = --threads 0 --std=c++20
NVLDFLAGS = -dlink
NVINCLUDES = -I"$(CUDA_PATH)/include"

CC = gcc-13 -Wall -Wpedantic
CCFLAGS = --std=c2x
LDFLAGS = 
INCLUDES = 
LIBRARIES = -L"$(CUDA_PATH)/lib64" -lcudadevrt -lcudart -lstdc++

#OBJDIR := objdir
#OBJS := $(addprefix $(OBJDIR)/,
EXECUTABLE = aoc.exe
CUDAOBJECTS = one.o two.o three.o day4.o days.o devicelink.o
OBJECTS = main.o

$(EXECUTABLE): $(OBJECTS) $(CUDAOBJECTS)
	$(CC) $(LDFLAGS) $(CCFLAGS) -o $@ $+ $(LIBRARIES)

devicelink.o: $(CUDAOBJECTS)
	$(NVCC) $(NVLDFLAGS) $(NVCCFLAGS) $(NVINCLUDES) -o $@ $+

days.o: days/days.cu
	$(NVCC) $(NVCCFLAGS) $(NVINCLUDES) -dc $< -o $@

one.o: days/one/one.cu
	$(NVCC) $(NVCCFLAGS) $(NVINCLUDES) -dc $< -o $@ 

two.o: days/two/two.cu
	$(NVCC) $(NVCCFLAGS) $(NVINCLUDES) -dc $< -o $@ 

three.o: days/three/three.cu
	$(NVCC) $(NVCCFLAGS) $(NVINCLUDES) -dc $< -o $@ 

day4.o: days/4/day4.cu
	$(NVCC) $(NVCCFLAGS) $(NVINCLUDES) -dc $< -o $@ 
	
main.o: main.c
	$(CC) $(CCFLAGS) $(INCLUDES) -o $@ -c $<

clean:
	rm -f $(EXECUTABLE) $(OBJECTS) $(CUDAOBJECTS)

# for loop example for later
#NUMBERS = 1 2 3 4
#doit:
#	$(foreach var,$(NUMBERS),./a.out $(var);)
