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

    
	CHECK(cudaMalloc((void **)&dev_A,parasize*(sizeof(CBigInt))));
    // copy from host memory to pinned memory

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


/****************************************************************************************
大数比较
调用方式：Cmp_para(N,A,num)
返回值：若N<A返回-1；若N=A返回0；若N>A返回1

****************************************************************************************/
__global__ void cmp_thread(CBigInt *dev_N,CBigInt *dev_A, int *d_cmp_res){
    int idx = threadIdx.x; // this is how you get the thread index



	int i;
	if(dev_N[idx].m_nLength>dev_A[idx].m_nLength){
		d_cmp_res[idx] =1;
        return;
    }
	if(dev_N[idx].m_nLength<dev_A[idx].m_nLength){
		d_cmp_res[idx] =-1;
        return;
    }
	for(i=dev_N[idx].m_nLength-1;i>=0;i--)
	{
		if(dev_N[idx].m_ulValue[i]>dev_A[idx].m_ulValue[i]){
            d_cmp_res[idx] =1;
            return;
        }
		if(dev_N[idx].m_ulValue[i]<dev_A[idx].m_ulValue[i]){
            d_cmp_res[idx] =-1;
            return;
        }
	}
    d_cmp_res[idx] = 0;
	return;
}

int Cmp_para(CBigInt N,CBigInt A, int parasize)
{

    CBigInt *h_N, *h_A, *dev_N,*dev_A;
    int *h_cmp_ret, *d_cmp_ret;
    // host alloc and cuda malloc in one time
	CHECK(cudaHostAlloc((void**) &h_N,parasize*(sizeof(CBigInt)),cudaHostAllocDefault));
    CHECK(cudaHostAlloc((void**) &h_A,parasize*(sizeof(CBigInt)),cudaHostAllocDefault));
    for(int i=0;i<parasize;i++){
        Mov_Big_Big(&h_N[i],N);
        Mov_Big_Big(&h_A[i],A);
    }
    CHECK(cudaHostAlloc((void**) &h_cmp_ret,parasize*(sizeof(int)),cudaHostAllocDefault));
    CHECK(cudaMalloc((void **)&dev_N,parasize*(sizeof(CBigInt))));
    CHECK(cudaMalloc((void **)&dev_A,parasize*(sizeof(CBigInt))));
    CHECK(cudaMalloc((void **)&d_cmp_ret,parasize*(sizeof(int))));
    // transfer the array to the GPU my dude. Copy's contents of h_in to d_in
    cudaMemcpy(dev_A, h_A, parasize*(sizeof(CBigInt)), cudaMemcpyHostToDevice);
    cudaMemcpy(dev_N, h_N, parasize*(sizeof(CBigInt)), cudaMemcpyHostToDevice);

    // launch the kernel
    cmp_thread<<<1,parasize>>>(dev_N,dev_A,d_cmp_ret);

    // copy the result back to the CPU mem
    cudaMemcpy(h_cmp_ret, d_cmp_ret, parasize*(sizeof(int)), cudaMemcpyDeviceToHost);
    for(int i=0;i<parasize;i++){
        printf("para %d cmp_ret = %d\n",i, h_cmp_ret[i]);
    }
    return h_cmp_ret[0];
}

/****************************************************************************************
大数赋值
调用方式：assignn_Big_to_Big_para(&N,A,32)  
返回值：多个N,被赋值为同一个A
****************************************************************************************/
__global__ void mov_big_big_thread(CBigInt *dev_N, CBigInt *dev_A){
    int idx = threadIdx.x; // this is how you get the thread index
    dev_N[idx].m_nLength=dev_A[idx].m_nLength;

	for(int i=0;i<BI_MAXLEN;i++)
	{
		dev_N[idx].m_ulValue[i]=dev_A[idx].m_ulValue[i];
	}
}
__global__ void assignn_Big_to_Big_thread(CBigInt *dev_N, CBigInt *dev_A){
    int idx = threadIdx.x; // this is how you get the thread index
    dev_N[idx].m_nLength=dev_A->m_nLength;

	for(int i=0;i<BI_MAXLEN;i++)
	{
		dev_N[idx].m_ulValue[i]=dev_A->m_ulValue[i];
	}
}

void assignn_Big_to_Big_para(CBigInt *N, CBigInt A, int parasize)
{
    CBigInt *h_N, *dev_N;
    CBigInt *h_A,*dev_A;
    // host alloc and cuda malloc in one time
	CHECK(cudaHostAlloc((void**) &h_N,parasize*(sizeof(CBigInt)),cudaHostAllocDefault));
    //CHECK(cudaHostAlloc((void**) &h_A,sizeof(int),cudaHostAllocDefault));
    CHECK(cudaHostAlloc((void**) &h_A,sizeof(CBigInt),cudaHostAllocDefault));
    Mov_Big_Big(h_A,A);
    CHECK(cudaMalloc((void **)&dev_N,parasize*(sizeof(CBigInt))));
    //CHECK(cudaMalloc((void **)&dev_A,parasize*(sizeof(CBigInt))));
	CHECK(cudaMalloc((void **)&dev_A,sizeof(CBigInt)));
    // copy from host memory to pinned memory
    
    // transfer the array to the GPU my dude. Copy's contents of h_in to d_in
    cudaMemcpy(dev_A, h_A, sizeof(CBigInt), cudaMemcpyHostToDevice);

    // launch the kernel
    assignn_Big_to_Big_thread<<<1,parasize>>>(dev_N,dev_A);
    
    // copy the result back to the CPU mem
    cudaMemcpy(h_N, dev_N, parasize*(sizeof(CBigInt)), cudaMemcpyDeviceToHost);
   
    // print the result
    
    for (int i = 0; i < parasize; i++){
        printf("thread %d move A=%s to N=%s\n",i,Put(A,HEX),Put(h_N[i],HEX));
    }

    Mov_Big_Big(N,h_N[0]);
   
    // free the device yo
    cudaFree(h_N);
    cudaFree(dev_N);
    cudaFree(h_A);
    cudaFree(dev_A);

}


void Mov_Big_Big_para(CBigInt *N, CBigInt A, int parasize)
{
    CBigInt *h_N, *dev_N, *h_AA, *dev_AA;
    //CBigInt h_A,dev_A;
    // host alloc and cuda malloc in one time
	CHECK(cudaHostAlloc((void**) &h_N,parasize*(sizeof(CBigInt)),cudaHostAllocDefault));
    CHECK(cudaHostAlloc((void**) &h_AA,parasize*(sizeof(CBigInt)),cudaHostAllocDefault));
    for(int i=0;i<parasize;i++){
        Mov_Big_Big(&h_AA[i],A);
    }
    //CHECK(cudaHostAlloc((void**) &h_A,sizeof(CBigInt),cudaHostAllocDefault));

    CHECK(cudaMalloc((void **)&dev_N,parasize*(sizeof(CBigInt))));
    CHECK(cudaMalloc((void **)&dev_AA,parasize*(sizeof(CBigInt))));
	//CHECK(cudaMalloc((void **)&dev_A,sizeof(CBigInt)));
    // copy from host memory to pinned memory
    
    // transfer the array to the GPU my dude. Copy's contents of h_in to d_in
    cudaMemcpy(dev_AA, h_AA, parasize*(sizeof(CBigInt)), cudaMemcpyHostToDevice);

    // launch the kernel
    mov_big_big_thread<<<1,parasize>>>(dev_N,dev_AA);
   
    // copy the result back to the CPU mem
    cudaMemcpy(h_N, dev_AA, parasize*(sizeof(CBigInt)), cudaMemcpyDeviceToHost);
    
    // print the result
    
    for (int i = 0; i < parasize; i++){
        printf("thread %d move A=%s to N=%s\n",i,Put(A,HEX),Put(h_N[i],HEX));
    }

    Mov_Big_Big(N,h_N[0]);
    
    // free the device yo
    cudaFree(h_N);
    cudaFree(dev_N);
    cudaFree(h_AA);
    cudaFree(dev_AA);

}


