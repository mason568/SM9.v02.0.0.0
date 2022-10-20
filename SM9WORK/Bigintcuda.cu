#include "Bigintcuda.cuh"



//构造大数对象并初始化为零 + 其对应的kernal函数

__global__ void cbiginiinit_thread(CBigInt *d_out){
    int idx = threadIdx.x; // this is how you get the thread index
	d_out[idx].m_nLength=1;
	for(int i=0;i<BI_MAXLEN;i++)
		d_out[idx].m_ulValue[i]=0;
}

void CBigIntInit_para(CBigInt *A,int parasize)
{
    CBigInt *h_A, *dev_A;


    // host alloc and cuda malloc in one time
	CHECK(cudaHostAlloc((void**) &h_A,parasize*(sizeof(CBigInt)),cudaHostAllocDefault));
    //数据从*A 拷贝到 h_A

    // copy from host memory to pinned memory
	CHECK(cudaMalloc((void **)&dev_A,parasize*(sizeof(CBigInt))));

    // transfer the array to the GPU my dude. Copy's contents of h_in to d_in
    //cudaMemcpy(dev_A, h_A, parasize*(sizeof(CBigInt)), cudaMemcpyHostToDevice);

    // launch the kernel
    cbiginiinit_thread<<<1,parasize>>>(dev_A);

    // copy the result back to the CPU mem
    cudaMemcpy(h_A, dev_A, parasize*(sizeof(CBigInt)), cudaMemcpyDeviceToHost);

    // print the result
    
    for (int i = 0; i < parasize; i++){
        printf("para %d = %s\n",i,Put(h_A[i],HEX));
    }

    Mov_Big_Big(A,h_A[0]);

    // free the device yo
    cudaFree(h_A);
    cudaFree(dev_A);
}





