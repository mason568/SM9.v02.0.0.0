#include "Bigintcuda.cuh"

__device__ int dev_cmp(CBigInt *d_N,CBigInt *d_A)
{
	int i;
	if(d_N->m_nLength>d_A->m_nLength)
		return 1;
	if(d_N->m_nLength<d_A->m_nLength)
		return -1;
	for(i=d_N->m_nLength-1;i>=0;i--)
	{
		if(d_N->m_ulValue[i]>d_A->m_ulValue[i])
			return 1;
		if(d_N->m_ulValue[i]<d_A->m_ulValue[i])
			return -1;
	}
	return 0;
}

__device__ void dev_mov_big_long(CBigInt *d_N,unsigned long d_A){
    int i;
	if(d_A>0xffffffff)
	{
		d_N->m_nLength=2;
		d_N->m_ulValue[1]=(unsigned long)((unsigned long long)d_A>>32);
		d_N->m_ulValue[0]=(unsigned long)d_A;
	}
	else
	{
		d_N->m_nLength=1;
		d_N->m_ulValue[0]=(unsigned long)d_A;
	}
	for(i=d_N->m_nLength;i<BI_MAXLEN;i++)
	{
		d_N->m_ulValue[i]=0;
	}
}

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
assign_Long_to_Big_para(&N,A,32)
返回值：多个N,被赋值为同一个A
但是嘛，由于cpu和gpu之间数据交换也需要时间，开销不好说，暂时写了，但可以不用
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
__global__ void assignn_Long_to_Big_thread(CBigInt *dev_N, unsigned long *dev_A){
    int idx = threadIdx.x; // this is how you get the thread index
	int i;
	if(*dev_A > (unsigned long)0xffffffff)
	{
		dev_N[idx].m_nLength=2;
		dev_N[idx].m_ulValue[1]=(unsigned long)((unsigned long long)*dev_A>>32);
		dev_N[idx].m_ulValue[0]=(unsigned long)*dev_A;
	}
	else
	{
		dev_N[idx].m_nLength=1;
		dev_N[idx].m_ulValue[0]=(unsigned long)*dev_A;
	}
	for(i=dev_N[idx].m_nLength;i<BI_MAXLEN;i++)
	{
		dev_N[idx].m_ulValue[i]=0;
	}
}
//一个Big为parasize个Big赋值  A ->  parasize*N
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
    memcpy(N,h_N,parasize*(sizeof(CBigInt)));
    //Mov_Big_Big(N,h_N[0]);
   
    // free the device yo
    cudaFree(h_N);
    cudaFree(dev_N);
    cudaFree(h_A);
    cudaFree(dev_A);

}
//一个unsigned long为parasize个Big赋值
void assignn_Long_to_Big_para(CBigInt *N, unsigned long A, int parasize)
{
    CBigInt *h_N, *dev_N;
    unsigned long *h_A,*dev_A;
    // host alloc and cuda malloc in one time
	CHECK(cudaHostAlloc((void**) &h_N,parasize*(sizeof(CBigInt)),cudaHostAllocDefault));
    //CHECK(cudaHostAlloc((void**) &h_A,sizeof(int),cudaHostAllocDefault));
    CHECK(cudaHostAlloc((void**) &h_A,sizeof(unsigned long),cudaHostAllocDefault));
    //Mov_Big_Long(h_A,A);
    memcpy(h_A,&A,sizeof(unsigned long));
    
    CHECK(cudaMalloc((void **)&dev_N,parasize*(sizeof(CBigInt))));
    //CHECK(cudaMalloc((void **)&dev_A,parasize*(sizeof(CBigInt))));
	CHECK(cudaMalloc((void **)&dev_A,sizeof(unsigned long)));
    // copy from host memory to pinned memory
    
    // transfer the array to the GPU my dude. Copy's contents of h_in to d_in
    cudaMemcpy(dev_A, h_A, sizeof(unsigned long), cudaMemcpyHostToDevice);

    // launch the kernel
    assignn_Long_to_Big_thread<<<1,parasize>>>(dev_N,dev_A);
    
    // copy the result back to the CPU mem
    cudaMemcpy(h_N, dev_N, parasize*(sizeof(CBigInt)), cudaMemcpyDeviceToHost);
   
    // print the result
    
    for (int i = 0; i < parasize; i++){
        printf("thread %d move A=%ld to N=%s\n",i,A,Put(h_N[i],HEX));
    }
    memcpy(N,h_N,parasize*(sizeof(CBigInt)));
    //Mov_Big_Big(N,h_N[0]);
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


/****************************************************************************************
大数相加
调用形式：Add_Big_Big_para(Y,N,A,num)  Add_Big_Long_para(Y,N,A,num)
返回值：Y=N+A
****************************************************************************************/
__global__ void add_big_big_thread(CBigInt *dev_YY, CBigInt *dev_N,CBigInt *dev_A){
    int idx = threadIdx.x; // this is how you get the thread index
    //直接在dev_YY[idx]上操作
    unsigned int i;
	//CBigInt X;
	unsigned int carry=0;
	unsigned long long sum=0;
	//CBigIntInit(&X);
	//Mov_Big_Big(&(dev_YY[idx]), *dev_N);
	if(dev_YY[idx].m_nLength<dev_A->m_nLength)
	{
		dev_YY[idx].m_nLength=dev_A->m_nLength;
	}
	for(i=0;i<dev_YY[idx].m_nLength;i++)
	{
		sum=dev_A->m_ulValue[i];
		sum=sum+dev_YY[idx].m_ulValue[i]+carry;
		dev_YY[idx].m_ulValue[i]=(unsigned long)sum;
		carry=(unsigned int)(sum>>32);
	}
	dev_YY[idx].m_ulValue[dev_YY[idx].m_nLength]=carry;
	dev_YY[idx].m_nLength+=carry;	
}


void Add_Big_Big_para(CBigInt *Y, CBigInt N, CBigInt A, int parasize)
{
    CBigInt *h_N, *h_A, *h_YY, *dev_N,*dev_A,*dev_YY;
    
    // host alloc and cuda malloc in one time
	CHECK(cudaHostAlloc((void**) &h_N,sizeof(CBigInt),cudaHostAllocDefault));
    CHECK(cudaHostAlloc((void**) &h_A,sizeof(CBigInt),cudaHostAllocDefault));
    CHECK(cudaHostAlloc((void**) &h_YY,parasize*(sizeof(CBigInt)),cudaHostAllocDefault));
    memcpy(h_N,&N,sizeof(CBigInt));
    memcpy(h_A,&A,sizeof(CBigInt));
    CHECK(cudaMalloc((void **)&dev_N,sizeof(CBigInt)));
    CHECK(cudaMalloc((void **)&dev_A,sizeof(CBigInt)));
    CHECK(cudaMalloc((void **)&dev_YY,parasize*(sizeof(CBigInt))));
    assignn_Big_to_Big_para(h_YY,N,32);
    // transfer the array to the GPU my dude. Copy's contents of h_in to d_in
    cudaMemcpy(dev_A, h_A, sizeof(CBigInt), cudaMemcpyHostToDevice);
    cudaMemcpy(dev_N, h_N, sizeof(CBigInt), cudaMemcpyHostToDevice);
    cudaMemcpy(dev_YY, h_YY, parasize*(sizeof(CBigInt)), cudaMemcpyHostToDevice);
    // launch the kernel
    add_big_big_thread<<<1,parasize>>>(dev_YY,dev_N,dev_A);

    // copy the result back to the CPU mem
    cudaMemcpy(h_YY, dev_YY, parasize*(sizeof(CBigInt)), cudaMemcpyDeviceToHost);
    for(int i=0;i<parasize;i++){
        printf("h_YY[%d] = %s\n", i,Put(h_YY[i],HEX));
    }
    

    Mov_Big_Big(Y,h_YY[0]);
    // free the device yo
    cudaFree(h_N);
    cudaFree(h_A);
    cudaFree(h_YY);
    cudaFree(dev_N);
    cudaFree(dev_A);
    cudaFree(dev_YY);
}


__global__ void add_big_long_thread(CBigInt *dev_YY, CBigInt *dev_N,unsigned long *dev_A){
    int idx = threadIdx.x; // this is how you get the thread index
    //直接在dev_YY[idx]上操作
	unsigned long sum;
	sum=dev_YY[idx].m_ulValue[0];
	sum+=(unsigned long)*dev_A;     
	dev_YY[idx].m_ulValue[0]=sum;
	if(sum>(unsigned long)0xffffffff)
	{
		unsigned int i=1;
		while(dev_YY[idx].m_ulValue[i]==0xffffffff)
		{
			dev_YY[idx].m_ulValue[i]=0;
			i++;
		}
		dev_YY[idx].m_ulValue[i]++;
		if(dev_N->m_nLength==i)
			dev_N->m_nLength++;
	}
	
}


void Add_Big_Long_para(CBigInt *Y, CBigInt N, unsigned long A, int parasize)
{
	CBigInt *h_N, *h_YY, *dev_N,*dev_YY;
    unsigned long *h_A, *dev_A;
    // host alloc and cuda malloc in one time
	CHECK(cudaHostAlloc((void**) &h_N,sizeof(CBigInt),cudaHostAllocDefault));
    CHECK(cudaHostAlloc((void**) &h_A,sizeof(unsigned long),cudaHostAllocDefault));
    CHECK(cudaHostAlloc((void**) &h_YY,parasize*(sizeof(CBigInt)),cudaHostAllocDefault));
    memcpy(h_N,&N,sizeof(CBigInt));
    memcpy(h_A,&A,sizeof(unsigned long));
    CHECK(cudaMalloc((void **)&dev_N,sizeof(CBigInt)));
    CHECK(cudaMalloc((void **)&dev_A,sizeof(unsigned long)));
    CHECK(cudaMalloc((void **)&dev_YY,parasize*(sizeof(CBigInt))));
    //printf("ok4\n");
    assignn_Big_to_Big_para(h_YY,N,32);
    //printf("ok5\n");
    // transfer the array to the GPU my dude. Copy's contents of h_in to d_in
    cudaMemcpy(dev_A, h_A, sizeof(unsigned long), cudaMemcpyHostToDevice);
    cudaMemcpy(dev_N, h_N, sizeof(CBigInt), cudaMemcpyHostToDevice);
    cudaMemcpy(dev_YY, h_YY, parasize*(sizeof(CBigInt)), cudaMemcpyHostToDevice);
    for(int i=0;i<parasize;i++){
        printf("h_YY[%d] = %s\n", i,Put(h_YY[i],HEX));
    }
    printf("ok6\n");
    // launch the kernel
    add_big_long_thread<<<1,parasize>>>(dev_YY,dev_N,dev_A);
    // copy the result back to the CPU mem
    cudaMemcpy(h_YY, dev_YY, parasize*(sizeof(CBigInt)), cudaMemcpyDeviceToHost);
    for(int i=0;i<parasize;i++){
        printf("h_YY[%d] = %s\n", i,Put(h_YY[i],HEX));
    }
    Mov_Big_Big(Y,h_YY[0]);
    // free the device yo
    cudaFree(h_N);
    cudaFree(h_A);
    cudaFree(h_YY);
    cudaFree(dev_N);
    cudaFree(dev_A);
    cudaFree(dev_YY);
    
}


/****************************************************************************************
大数相减
调用形式：Sub_Big_Big_para(Y,N,A,num) Sub_Big_Long_para(Y,N,A,num)
返回值：Y=N-A
****************************************************************************************/
__global__ void sub_big_big_thread(CBigInt *dev_YY, CBigInt *dev_N,CBigInt *dev_A){
    int idx = threadIdx.x; // this is how you get the thread index

	unsigned int carry=0;
	unsigned long long num;
	unsigned int i;

	if(dev_cmp(&(dev_YY[idx]),dev_A)<=0)
		dev_mov_big_long(&dev_YY[idx],0);
    else
	{
		for(i=0;i<dev_N->m_nLength;i++)
		{
			if((dev_N->m_ulValue[i]>dev_YY[idx].m_ulValue[i])||((dev_N->m_ulValue[i]==dev_YY[idx].m_ulValue[i])&&(carry==0)))
			{
				dev_YY[idx].m_ulValue[i]=dev_N->m_ulValue[i]-carry-dev_A->m_ulValue[i];
				carry=0;
			}
			else
			{
				num=0x100000000+dev_YY[idx].m_ulValue[i];
				dev_YY[idx].m_ulValue[i]=(unsigned long)(num-carry-dev_YY[idx].m_ulValue[i]);
				carry=1;
			}     
		}
		while(dev_YY[idx].m_ulValue[dev_YY[idx].m_nLength-1]==0)
			dev_YY[idx].m_nLength--;
			
	}	
}

void Sub_Big_Big_para(CBigInt *Y, CBigInt N, CBigInt A, int parasize)
{
    CBigInt *h_N, *h_A, *h_YY, *dev_N,*dev_A,*dev_YY;
    
    // host alloc and cuda malloc in one time
	CHECK(cudaHostAlloc((void**) &h_N,sizeof(CBigInt),cudaHostAllocDefault));
    CHECK(cudaHostAlloc((void**) &h_A,sizeof(CBigInt),cudaHostAllocDefault));
    CHECK(cudaHostAlloc((void**) &h_YY,parasize*(sizeof(CBigInt)),cudaHostAllocDefault));
    //printf("ok2\n");
    memcpy(h_N,&N,sizeof(CBigInt));
    memcpy(h_A,&A,sizeof(CBigInt));
    //printf("h_N = %s\n",Put(*h_N,HEX));
    //printf("h_A = %s\n",Put(*h_A,HEX));
    //printf("ok3\n");
    CHECK(cudaMalloc((void **)&dev_N,sizeof(CBigInt)));
    CHECK(cudaMalloc((void **)&dev_A,sizeof(CBigInt)));
    CHECK(cudaMalloc((void **)&dev_YY,parasize*(sizeof(CBigInt))));
    //printf("ok4\n");
    assignn_Big_to_Big_para(h_YY,N,32);
    //printf("ok5\n");
    // transfer the array to the GPU my dude. Copy's contents of h_in to d_in
    cudaMemcpy(dev_A, h_A, sizeof(CBigInt), cudaMemcpyHostToDevice);
    cudaMemcpy(dev_N, h_N, sizeof(CBigInt), cudaMemcpyHostToDevice);
    cudaMemcpy(dev_YY, h_YY, parasize*(sizeof(CBigInt)), cudaMemcpyHostToDevice);
    printf("ok6\n");
    // launch the kernel
    sub_big_big_thread<<<1,parasize>>>(dev_YY,dev_N,dev_A);

    // copy the result back to the CPU mem
    cudaMemcpy(h_YY, dev_YY, parasize*(sizeof(CBigInt)), cudaMemcpyDeviceToHost);

    for(int i=0;i<parasize;i++){
        printf("h_YY[%d] = %s\n", i,Put(h_YY[i],HEX));
    }

    Mov_Big_Big(Y,h_YY[0]);
    // free the device yo
    cudaFree(h_N);
    cudaFree(h_A);
    cudaFree(h_YY);
    cudaFree(dev_N);
    cudaFree(dev_A);
    cudaFree(dev_YY);
}