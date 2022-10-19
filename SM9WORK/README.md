# SM9
C code implementation of  Chinese SM9 standard

# 头文件包含关系
SM9PKC.h > SM9KA.h > SM9DSA.h > utility.h > BNPairing.h > BNPoint2.h > BNPoint.h > BNField12.h > BNField4.h > BNField2.h > BNField2.h > Params.h > BigInt.h > 



$(BIN):$(OBJS)
	$(CC)  $(INCLUDE_PATH)  -o $(BIN)  $(OBJS)  -lm $(LDFLAGS)
$(TARGET1):$(TARGET1).cu
	$(NVCC) $(LDFLAGS2) $(ARCHFLAG) -o $(TARGET1) $(TARGET1).cu $(LIB_TARGET) 

#

	$(CC) $(CFLAG) $(INCLUDE_PATH) -c $(SRC)
	
	$(NVCC) $(LDFLAGS2) $(ARCHFLAG)  square063.cu -o square063.o
	gcc -shared -o libtest.so *.o -L/usr/local/cuda/lib64 -lcuda -lcudart -lcublas -lcurand -lcudnn -nostartfiles
	gcc -c sm9cudatest.c
	gcc -o sm9cudatest sm9cudatest.c libtest.so -L/usr/local/cuda/lib64 -lcuda -lcudart -lcublas -lcurand -lcudnn

