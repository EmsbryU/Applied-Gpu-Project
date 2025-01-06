include ../common/make.config

CC := $(CUDA_DIR)/bin/nvcc

INCLUDE := $(CUDA_DIR)/include

SRC = gaussianFinal_Backsub.cu
EXE = gaussian

release: $(SRC)
	$(CC) -lcublas -lcusolver $(SRC) -o $(EXE) -I$(INCLUDE) -L$(CUDA_LIB_DIR) 

clean:
	rm gaussian
