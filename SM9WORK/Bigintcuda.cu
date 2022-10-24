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

__device__ void dev_mov_big_big(CBigInt *d_N, CBigInt d_A)
{
	//CBigInt N;
	int i;
	d_N->m_nLength=d_A.m_nLength;
	for(i=0;i<BI_MAXLEN;i++)
	{
		d_N->m_ulValue[i]=d_A.m_ulValue[i];
	}
	
}

__device__ void dev_cbigintinit(CBigInt *d_A)
{
	int i;
	d_A->m_nLength=1;
	for(i=0;i<BI_MAXLEN;i++)
		d_A->m_ulValue[i]=0;
}

__device__ void dev_add_big_long(CBigInt *Y, CBigInt N, unsigned long A)//
{
	CBigInt X;
	unsigned long long sum;
	dev_cbigintinit(&X);
	dev_mov_big_big(&X,N);// X=N

	sum=X.m_ulValue[0];
	sum+=A;     
	X.m_ulValue[0]=(unsigned long)sum;
	if(sum>0xffffffff)
	{
		unsigned int i=1;
		while(X.m_ulValue[i]==0xffffffff)
		{
			X.m_ulValue[i]=0;
			i++;
		}
		X.m_ulValue[i]++;
		if(N.m_nLength==i)
			N.m_nLength++;
	}
	dev_mov_big_big(Y,X);
}

__device__ void dev_add_big_big(CBigInt *Y, CBigInt N, CBigInt A)
{
	unsigned int i;
	CBigInt X;
	unsigned int carry=0;
	unsigned long long sum=0;
	dev_cbigintinit(&X);
	dev_mov_big_big(&X, N);

	if(X.m_nLength<A.m_nLength)
	{
		X.m_nLength=A.m_nLength;
	}
	for(i=0;i<X.m_nLength;i++)
	{
		sum=A.m_ulValue[i];
		sum=sum+X.m_ulValue[i]+carry;
		X.m_ulValue[i]=(unsigned long)sum;
		carry=(unsigned int)(sum>>32);
	}
	X.m_ulValue[X.m_nLength]=carry;
	X.m_nLength+=carry;	
	dev_mov_big_big(Y,X);
}

__device__ void dev_mul_big_long(CBigInt *Y, CBigInt N, unsigned long A)
{
	CBigInt X;
	unsigned long long mul;
	unsigned long carry=0;
	unsigned int i;
	dev_cbigintinit(&X);
	dev_mov_big_big(&X,N);;
	for(i=0;i<N.m_nLength;i++)
	{
		mul=N.m_ulValue[i];
		mul=mul*A+carry;
		X.m_ulValue[i]=(unsigned int)mul;
		carry=(unsigned int)(mul>>32);
	}
	if(carry)
	{
		X.m_nLength++;
		X.m_ulValue[X.m_nLength-1]=carry;
	}
	i = X.m_nLength-1;
	while(X.m_ulValue[i]==0 && i>0)
	{
		X.m_nLength--;
		i--;
	}
	dev_mov_big_big(Y,X);
}

__device__ void dev_mul_big_big(CBigInt *Y, CBigInt N, CBigInt A)
{
	CBigInt X;
	unsigned long long sum,mul=0,carry=0;
	unsigned int i,j;
	if(A.m_nLength==1)
		dev_mul_big_long(Y,N,A.m_ulValue[0]);
	else
	{
		dev_cbigintinit(&X);
		X.m_nLength=N.m_nLength+A.m_nLength-1;
		for(i=0;i<X.m_nLength;i++)
		{
			sum=carry;
			carry=0;
			for(j=0;j<A.m_nLength;j++)
			{
				if(((i-j)>=0)&&((i-j)<N.m_nLength))
				{
					mul=N.m_ulValue[i-j];
					mul*=A.m_ulValue[j];
					carry+=mul>>32;
					mul=mul&0xffffffff;
					sum+=mul;
				}
			}				
			carry+=sum>>32;
			X.m_ulValue[i]=(unsigned long)sum;
		}
		if(carry)
		{
			X.m_nLength++;
			X.m_ulValue[X.m_nLength-1]=(unsigned long)carry;
		}
		i = X.m_nLength-1;
		while(X.m_ulValue[i]==0 && i>0)
		{
			X.m_nLength--;
			i--;
		}
		dev_mov_big_big(Y,X);
	}
}

__device__ void dev_sub_big_big(CBigInt *Y, CBigInt N, CBigInt A)
{
	CBigInt X;
	unsigned int carry=0;
	unsigned long long num;
	unsigned int i;
	dev_cbigintinit(&X);
	dev_mov_big_big(&X,N);
	if(dev_cmp(&X,&A)<=0)
		dev_mov_big_long(&X,0);
    else
	{

		for(i=0;i<N.m_nLength;i++)
		{
			if((N.m_ulValue[i]>A.m_ulValue[i])||((N.m_ulValue[i]==A.m_ulValue[i])&&(carry==0)))
			{
				X.m_ulValue[i]=N.m_ulValue[i]-carry-A.m_ulValue[i];
				carry=0;
			}
			else
			{
				num=0x100000000+X.m_ulValue[i];
				X.m_ulValue[i]=(unsigned long)(num-carry-A.m_ulValue[i]);
				carry=1;
			}     
		}
		while(X.m_ulValue[X.m_nLength-1]==0)
			X.m_nLength--;
			
	}
	dev_mov_big_big(Y,X);
}


__device__ unsigned long dev_mod_big_long(CBigInt N, unsigned long A)
{
	unsigned long long div;
	unsigned long carry=0;
	int i;
	if(N.m_nLength==1)
		return(N.m_ulValue[0]%A);


	for(i=N.m_nLength-1;i>=0;i--)
	{
		div=N.m_ulValue[i];
		div+=carry*0x100000000;
		carry=(unsigned long)(div%A);
	}
	return carry;
}


__device__ void dev_mod_big_big(CBigInt *Z,CBigInt N, CBigInt A)
{
	CBigInt X,Y;
	unsigned long long div,num;
	//unsigned long carry=0;
	unsigned int i,len;
	dev_cbigintinit(&X);
	dev_cbigintinit(&Y);
	dev_mov_big_big(&X,N);//dev_mov_big_big
	while(dev_cmp(&X,&A)>=0)
	{
		div=X.m_ulValue[X.m_nLength-1];
		num=A.m_ulValue[A.m_nLength-1];
		len=X.m_nLength-A.m_nLength;
		if((div==num)&&(len==0))
		{
			//Mov_Big_Big(&X,Sub_Big_Big(X,A));
			dev_sub_big_big(&X,X,A);//dev_sub_big_big
			break;
		}
		if((div<=num)&&len)
		{
			len--;div=(div<<32)+X.m_ulValue[X.m_nLength-2];
		}
		div=div/(num+1);
		dev_mov_big_long(&Y,div);	//dev_mov_big_long	
		//Mov_Big_Big(&Y,Mul_Big_Big(A,Y));
		dev_mul_big_big(&Y,A,Y); //dev_mul_big_big
		if(len)
		{
			Y.m_nLength+=len;
			for(i=Y.m_nLength-1;i>=len;i--)
				Y.m_ulValue[i]=Y.m_ulValue[i-len];
			for(i=0;i<len;i++)
				Y.m_ulValue[i]=0;
		}
		//Mov_Big_Big(&X,Sub_Big_Big(X,Y));
		dev_sub_big_big(&X,X,Y);
	}
	dev_mov_big_big(Z,X);
}

__device__ void dev_div_big_long(CBigInt *Y, CBigInt N, unsigned long A)
{
	CBigInt X;
	unsigned long long div,mul;
	unsigned long carry=0;
	int i;
	//CBigIntInit(X);
	dev_mov_big_big(&X,N);;
	if(X.m_nLength==1)
	{
		X.m_ulValue[0]=X.m_ulValue[0]/A;
		dev_mov_big_big(Y,X);
	}
	else
	{
		for(i=X.m_nLength-1;i>=0;i--)
		{
			div=carry;
			div=(div<<32)+X.m_ulValue[i];
			X.m_ulValue[i]=(unsigned long)(div/A);
			mul=(div/A)*A;
			carry=(unsigned long)(div-mul);
		}
		if(X.m_ulValue[X.m_nLength-1]==0)
			X.m_nLength--;
		dev_mov_big_big(Y,X);
	}
}

__device__ void dev_div_big_big(CBigInt *M,CBigInt N, CBigInt A)
{
	CBigInt X,Y,Z,T;
	unsigned int i,len;
	unsigned long long num,div;
	if(A.m_nLength==1)
		dev_div_big_long(M,N,A.m_ulValue[0]);
	else
	{
		dev_cbigintinit(&X);
		dev_cbigintinit(&Y);
		dev_cbigintinit(&Z);
		dev_cbigintinit(&T);
		dev_mov_big_big(&Y,N);
		while(dev_cmp(&Y,&A)>=0)
		{        
			div=Y.m_ulValue[Y.m_nLength-1];
			num=A.m_ulValue[A.m_nLength-1];
			len=Y.m_nLength-A.m_nLength;
			if((div==num)&&(len==0))
			{
				//Mov_Big_Big(&X,Add_Big_Long(X,1));
				dev_add_big_long(&X,X,1);//dev_add_big_long
				break;
			}
			if((div<=num)&&len)
			{
				len--;
				div=(div<<32)+Y.m_ulValue[Y.m_nLength-2];
			}
			div=div/(num+1);
			dev_mov_big_long(&Z,div);
			if(len)
			{
				Z.m_nLength+=len;
				for(i=Z.m_nLength-1;i>=len;i--)
					Z.m_ulValue[i]=Z.m_ulValue[i-len];
				for(i=0;i<len;i++)
					Z.m_ulValue[i]=0;
			}
			//Mov_Big_Big(&X,Add_Big_Big(X,Z));
			dev_add_big_big(&X,X,Z);
			//Mov_Big_Big(&Y,Sub_Big_Big(Y,Mul_Big_Big(A,Z)));
			dev_mul_big_big(&T,A,Z);
			dev_sub_big_big(&Y,Y,T);
		}
		dev_mov_big_big(M,X);
	}
}


__device__ char* dev_put(CBigInt *N, unsigned int system)
{
	char* str;	
	char t[17]="0123456789ABCDEF";
	int i, a, len;
	char s[1024] = {"0"};
	char s1[1024] = {"0"};
	CBigInt X;
	str="";
	if((N->m_nLength==1)&&(N->m_ulValue[0]==0))
	{
		str="0";
		return str;
	}

	dev_cbigintinit(&X);
	dev_mov_big_big(&X,*N);;
	for(i = 0; X.m_ulValue[X.m_nLength-1]>0; i ++)
	{
		a=dev_mod_big_long(X,system);
		s[i] = t[a]; 
		//Mov_Big_Big(&X,Div_Big_Long(X,system));
		dev_div_big_long(&X,X,system);
	}
	len = i-1;  
	for( i= 0; i<= len; i++)
		s1[i] = s[len-i];
	str = s1;
	return str;
}
/****************************************************************************************
//构造大数对象并初始化为零 + 其对应的kernal函数
若想返回parasize的数据量请启用 free the device yo 之前的memcpy 并注释替代函数
****************************************************************************************/
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
    //memcpy(A,h_A,parasize*(sizeof(CBigInt)));
    // free the device yo
    cudaFree(h_A);
    cudaFree(dev_A);
}


/****************************************************************************************
大数比较
调用方式：Cmp_para(N,A,num)
返回值：若N<A返回-1；若N=A返回0；若N>A返回1
这个函数目前没有返回一个链表，还是返回一个数
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
    int ret;
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
    //memcpy(N,h_N,parasize*(sizeof(CBigInt)));  
    ret = h_cmp_ret[0];
        // free the device yo
    cudaFree(h_N);
    cudaFree(dev_N);
    cudaFree(h_A);
    cudaFree(dev_A);
    cudaFree(h_cmp_ret);
    cudaFree(d_cmp_ret);
    return ret;
}

/****************************************************************************************
大数赋值
调用方式：assignn_Big_to_Big_para(&N,A,32)  
assign_Long_to_Big_para(&N,A,32)

若想返回parasize的数据量请启用 free the device yo 之前的memcpy 并注释替代函数
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
    /*
    for (int i = 0; i < parasize; i++){
        printf("thread %d move A=%s to N=%s\n",i,Put(A,HEX),Put(h_N[i],HEX));
    }
    */
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
    /*
    for (int i = 0; i < parasize; i++){
        printf("thread %d move A=%ld to N=%s\n",i,A,Put(h_N[i],HEX));
    }
    */
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
    /*
    for (int i = 0; i < parasize; i++){
        printf("thread %d move A=%s to N=%s\n",i,Put(A,HEX),Put(h_N[i],HEX));
    }
    */

    Mov_Big_Big(N,h_N[0]);
    //memcpy(N,h_N,parasize*(sizeof(CBigInt)));
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
若想返回parasize的数据量请启用 free the device yo 之前的memcpy 并注释替代函数
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
    //memcpy(Y,h_YY,parasize*(sizeof(CBigInt)));
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
    //memcpy(Y,h_YY,parasize*(sizeof(CBigInt)));
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
若想返回parasize的数据量请启用 free the device yo 之前的memcpy 并注释替代函数
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
    //memcpy(Y,h_YY,parasize*(sizeof(CBigInt)));
    // free the device yo
    cudaFree(h_N);
    cudaFree(h_A);
    cudaFree(h_YY);
    cudaFree(dev_N);
    cudaFree(dev_A);
    cudaFree(dev_YY);
}


__global__ void sub_big_long_thread(CBigInt *dev_YY, CBigInt *dev_N,unsigned long *dev_A){
    int idx = threadIdx.x; // this is how you get the thread index
	unsigned long long num;
	int i=1;
	num=0x100000000+dev_YY[idx].m_ulValue[0];

	//Mov_Big_Big(&X,N);   因为N在之前就赋值给每条线程的dev_YY[idx]了，这里就不需要重复赋值了
	if(dev_YY[idx].m_ulValue[0]>=(*dev_A))
	{
		dev_YY[idx].m_ulValue[0]-=(*dev_A);
		
	}
	else if(dev_YY[idx].m_nLength==1)
	{
		//Mov_Big_Long(&dev_YY[idx],0);
        dev_mov_big_long(&dev_YY[idx],0);
		
	}
	else
	{

		dev_YY[idx].m_ulValue[0]=(unsigned long)(num-(*dev_A));    

		while(dev_YY[idx].m_ulValue[i]==0)
		{
			dev_YY[idx].m_ulValue[i]=0xffffffff;
			i++;
		}
		dev_YY[idx].m_ulValue[i]--;
		if(dev_YY[idx].m_ulValue[i]==0)
			dev_YY[idx].m_nLength--;
		
	}
}

void Sub_Big_Long_para(CBigInt *Y, CBigInt N, unsigned long A, int parasize)
{
    CBigInt *h_N, *h_YY, *dev_N,*dev_YY;
    unsigned long *h_A,*dev_A;
    // host alloc and cuda malloc in one time
	CHECK(cudaHostAlloc((void**) &h_N,sizeof(CBigInt),cudaHostAllocDefault));
    CHECK(cudaHostAlloc((void**) &h_A,sizeof(unsigned long),cudaHostAllocDefault));
    CHECK(cudaHostAlloc((void**) &h_YY,parasize*(sizeof(CBigInt)),cudaHostAllocDefault));
    //printf("ok2\n");
    memcpy(h_N,&N,sizeof(CBigInt));
    memcpy(h_A,&A,sizeof(unsigned long));
    //printf("h_N = %s\n",Put(*h_N,HEX));
    //printf("h_A = %s\n",Put(*h_A,HEX));
    //printf("ok3\n");
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
    //printf("ok6\n");
    // launch the kernel
    sub_big_long_thread<<<1,parasize>>>(dev_YY,dev_N,dev_A);

    // copy the result back to the CPU mem
    cudaMemcpy(h_YY, dev_YY, parasize*(sizeof(CBigInt)), cudaMemcpyDeviceToHost);

    for(int i=0;i<parasize;i++){
        printf("h_YY[%d] = %s\n", i,Put(h_YY[i],HEX));
    }
    
    Mov_Big_Big(Y,h_YY[0]);
    //memcpy(Y,h_YY,parasize*(sizeof(CBigInt)));
    // free the device yo
    cudaFree(h_N);
    cudaFree(h_A);
    cudaFree(h_YY);
    cudaFree(dev_N);
    cudaFree(dev_A);
    cudaFree(dev_YY);	
    
    
    
}

/****************************************************************************************
大数相乘
调用形式：Mul_Big_Big(Y,N,A)
返回值：X=N*A
	A	a 0
	N	c d
		0					d*0
		1			c*0 
					d*a
		2	c*a
只有CBigInt *Y 看成是parasize个输入而CBigInt N, unsigned long A看成是一个只是并行parasize次
****************************************************************************************/
__global__ void mul_big_long_thread(CBigInt *dev_YY, CBigInt *dev_N,unsigned long *dev_A){
    int idx = threadIdx.x; // this is how you get the thread index
	unsigned long long mul;
	unsigned long carry=0;
	unsigned int i;
	//CBigIntInit(&X);
	//Mov_Big_Big(&X,N);;
	for(i=0;i<dev_N->m_nLength;i++)
	{
		mul=(unsigned long long)(dev_N->m_ulValue[i]);
		mul=mul*(*dev_A)+carry;
		dev_YY[idx].m_ulValue[i]=(unsigned int)mul;
		carry=(unsigned int)(mul>>32);
	}
	if(carry)
	{
		dev_YY[idx].m_nLength++;
		dev_YY[idx].m_ulValue[dev_YY[idx].m_nLength-1]=carry;
	}
	i = dev_YY[idx].m_nLength-1;
	while(dev_YY[idx].m_ulValue[i]==0 && i>0)
	{
		dev_YY[idx].m_nLength--;
		i--;
	}
	//Mov_Big_Big(Y,X);

}
void Mul_Big_Long_para(CBigInt *YY, CBigInt N, unsigned long A, int parasize)
{
    CBigInt *h_N, *h_YY, *dev_N,*dev_YY;
    unsigned long *h_A,*dev_A;
    // host alloc and cuda malloc in one time
	CHECK(cudaHostAlloc((void**) &h_N,sizeof(CBigInt),cudaHostAllocDefault));
    CHECK(cudaHostAlloc((void**) &h_A,sizeof(unsigned long),cudaHostAllocDefault));
    CHECK(cudaHostAlloc((void**) &h_YY,parasize*(sizeof(CBigInt)),cudaHostAllocDefault));
 
    memcpy(h_N,&N,sizeof(CBigInt));
    memcpy(h_A,&A,sizeof(unsigned long));
    //printf("h_N = %s\n",Put(*h_N,HEX));
    //printf("h_A = %s\n",Put(*h_A,HEX));
  
    CHECK(cudaMalloc((void **)&dev_N,sizeof(CBigInt)));
    CHECK(cudaMalloc((void **)&dev_A,sizeof(unsigned long)));
    CHECK(cudaMalloc((void **)&dev_YY,parasize*(sizeof(CBigInt))));
 
    assignn_Big_to_Big_para(h_YY,N,32);

    // transfer the array to the GPU my dude. Copy's contents of h_in to d_in
    cudaMemcpy(dev_A, h_A, sizeof(unsigned long), cudaMemcpyHostToDevice);
    cudaMemcpy(dev_N, h_N, sizeof(CBigInt), cudaMemcpyHostToDevice);
    cudaMemcpy(dev_YY, h_YY, parasize*(sizeof(CBigInt)), cudaMemcpyHostToDevice);

    // launch the kernel
    mul_big_long_thread<<<1,parasize>>>(dev_YY,dev_N,dev_A);

    // copy the result back to the CPU mem
    cudaMemcpy(h_YY, dev_YY, parasize*(sizeof(CBigInt)), cudaMemcpyDeviceToHost);

    //Mov_Big_Big(Y,h_YY[0]);
    memcpy(YY,h_YY,parasize*(sizeof(CBigInt)));

    
    cudaFree(h_N);
    cudaFree(h_A);
    cudaFree(h_YY);
    cudaFree(dev_N);
    cudaFree(dev_A);
    cudaFree(dev_YY);	
   
	
}

__global__ void mul_big_big_thread(CBigInt *dev_YY, CBigInt *dev_N,CBigInt *dev_A){
    int idx = threadIdx.x; // this is how you get the thread index
	CBigInt X;
	unsigned long long sum,mul=0,carry=0;
	unsigned int i,j;
	if(dev_A->m_nLength==1)
		dev_mov_big_long(&X,dev_A->m_ulValue[0]);
	else
	{
		dev_cbigintinit(&X);
		X.m_nLength=dev_N->m_nLength+dev_A->m_nLength-1;
		for(i=0;i<X.m_nLength;i++)
		{
			sum=carry;
			carry=0;
			for(j=0;j<dev_A->m_nLength;j++)
			{
				if(((i-j)>=0)&&((i-j)<dev_N->m_nLength))
				{
					mul=dev_N->m_ulValue[i-j];
					mul*=dev_A->m_ulValue[j];
					carry+=mul>>32;
					mul=mul&0xffffffff;
					sum+=mul;
				}
			}				
			carry+=sum>>32;
			X.m_ulValue[i]=(unsigned long)sum;
		}
		if(carry)
		{
			X.m_nLength++;
			X.m_ulValue[X.m_nLength-1]=(unsigned long)carry;
		}
		i = X.m_nLength-1;
		while(X.m_ulValue[i]==0 && i>0)
		{
			X.m_nLength--;
			i--;
		}
		dev_mov_big_big(&dev_YY[idx],X);
	}

}

void Mul_Big_Big_para(CBigInt *YY, CBigInt N, CBigInt A, int parasize)
{
    CBigInt *h_N, *h_A, *h_YY, *dev_N, *dev_A, *dev_YY;
    // host alloc and cuda malloc in one time
	CHECK(cudaHostAlloc((void**) &h_N,sizeof(CBigInt),cudaHostAllocDefault));
    CHECK(cudaHostAlloc((void**) &h_A,sizeof(CBigInt),cudaHostAllocDefault));
    CHECK(cudaHostAlloc((void**) &h_YY,parasize*(sizeof(CBigInt)),cudaHostAllocDefault));
 
    memcpy(h_N,&N,sizeof(CBigInt));
    memcpy(h_A,&A,sizeof(CBigInt));
    //printf("h_N = %s\n",Put(*h_N,HEX));
    //printf("h_A = %s\n",Put(*h_A,HEX));
  
    CHECK(cudaMalloc((void **)&dev_N,sizeof(CBigInt)));
    CHECK(cudaMalloc((void **)&dev_A,sizeof(CBigInt)));
    CHECK(cudaMalloc((void **)&dev_YY,parasize*(sizeof(CBigInt))));
 
    //assignn_Big_to_Big_para(h_YY,N,32);

    // transfer the array to the GPU my dude. Copy's contents of h_in to d_in
    cudaMemcpy(dev_A, h_A, sizeof(CBigInt), cudaMemcpyHostToDevice);
    cudaMemcpy(dev_N, h_N, sizeof(CBigInt), cudaMemcpyHostToDevice);
    //cudaMemcpy(dev_YY, h_YY, parasize*(sizeof(CBigInt)), cudaMemcpyHostToDevice);

    // launch the kernel
    mul_big_big_thread<<<1,parasize>>>(dev_YY,dev_N,dev_A);

    // copy the result back to the CPU mem
    cudaMemcpy(h_YY, dev_YY, parasize*(sizeof(CBigInt)), cudaMemcpyDeviceToHost);

    //Mov_Big_Big(Y,h_YY[0]);
    memcpy(YY,h_YY,parasize*(sizeof(CBigInt)));
    /*
    for(int i=0;i<parasize;i++){
        printf("thread work out YY[%d] = %s\n",i,Put(YY[i],HEX));
    }
    */
    
    cudaFree(h_N);
    cudaFree(h_A);
    cudaFree(h_YY);
    cudaFree(dev_N);
    cudaFree(dev_A);
    cudaFree(dev_YY);	

}


/****************************************************************************************
大数相除
调用形式：Div_Big_Big_para(P,N,A)
返回值：P=N/A
****************************************************************************************/
__global__ void div_big_long_thread(CBigInt *dev_YY, CBigInt *dev_N,unsigned long *dev_A){
    int idx = threadIdx.x; 
    //CBigInt X;
	unsigned long long div,mul;
	unsigned long carry=0;
	int i;
	//CBigIntInit(X);
	//Mov_Big_Big(&X,N);;
	if(dev_YY[idx].m_nLength==1)
	{
		dev_YY[idx].m_ulValue[0]=dev_YY[idx].m_ulValue[0]/(*dev_A);
		//Mov_Big_Big(Y,dev_YY[idx]);
	}
	else
	{
		for(i=dev_YY[idx].m_nLength-1;i>=0;i--)
		{
			div=carry;
			div=(div<<32)+dev_YY[idx].m_ulValue[i];
			dev_YY[idx].m_ulValue[i]=(unsigned long)(div/(*dev_A));
			mul=(div/(*dev_A))*(*dev_A);
			carry=(unsigned long)(div-mul);
		}
		if(dev_YY[idx].m_ulValue[dev_YY[idx].m_nLength-1]==0)
			dev_YY[idx].m_nLength--;
		//Mov_Big_Big(Y,X);
	}

}

void Div_Big_Long_para(CBigInt *YY, CBigInt N, unsigned long A, int parasize)
{
	CBigInt *h_N, *h_YY, *dev_N,*dev_YY;
    unsigned long *h_A,*dev_A;
    // host alloc and cuda malloc in one time
	CHECK(cudaHostAlloc((void**) &h_N,sizeof(CBigInt),cudaHostAllocDefault));
    CHECK(cudaHostAlloc((void**) &h_A,sizeof(unsigned long),cudaHostAllocDefault));
    CHECK(cudaHostAlloc((void**) &h_YY,parasize*(sizeof(CBigInt)),cudaHostAllocDefault));
 
    memcpy(h_N,&N,sizeof(CBigInt));
    memcpy(h_A,&A,sizeof(unsigned long));
    //printf("h_N = %s\n",Put(*h_N,HEX));
    //printf("h_A = %s\n",Put(*h_A,HEX));
  
    CHECK(cudaMalloc((void **)&dev_N,sizeof(CBigInt)));
    CHECK(cudaMalloc((void **)&dev_A,sizeof(unsigned long)));
    CHECK(cudaMalloc((void **)&dev_YY,parasize*(sizeof(CBigInt))));
 
    assignn_Big_to_Big_para(h_YY,N,32);

    // transfer the array to the GPU my dude. Copy's contents of h_in to d_in
    cudaMemcpy(dev_A, h_A, sizeof(unsigned long), cudaMemcpyHostToDevice);
    cudaMemcpy(dev_N, h_N, sizeof(CBigInt), cudaMemcpyHostToDevice);
    cudaMemcpy(dev_YY, h_YY, parasize*(sizeof(CBigInt)), cudaMemcpyHostToDevice);

    // launch the kernel
    div_big_long_thread<<<1,parasize>>>(dev_YY,dev_N,dev_A);

    // copy the result back to the CPU mem
    cudaMemcpy(h_YY, dev_YY, parasize*(sizeof(CBigInt)), cudaMemcpyDeviceToHost);

    //Mov_Big_Big(Y,h_YY[0]);
    memcpy(YY,h_YY,parasize*(sizeof(CBigInt)));

    
    cudaFree(h_N);
    cudaFree(h_A);
    cudaFree(h_YY);
    cudaFree(dev_N);
    cudaFree(dev_A);
    cudaFree(dev_YY);
    

}

__global__ void div_big_big_thread(CBigInt *dev_YY, CBigInt *dev_N,CBigInt *dev_A){
    int idx = threadIdx.x;        
    CBigInt X,Y,Z,T;
    unsigned int i,len;
    unsigned long long num,div;
    dev_cbigintinit(&X);
    dev_cbigintinit(&Y);
    dev_cbigintinit(&Z);
    dev_cbigintinit(&T); //dev_cbigintinit
    dev_mov_big_big(&Y,*dev_N); //dev_mov_big_big
    while(dev_cmp(&Y,dev_A)>=0)
    {        
        div=Y.m_ulValue[Y.m_nLength-1];
        num=dev_A->m_ulValue[dev_A->m_nLength-1];
        len=Y.m_nLength-dev_A->m_nLength;
        if((div==num)&&(len==0))
        {
            //Mov_Big_Big(&X,Add_Big_Long(X,1));
            dev_add_big_long(&X,X,1); //dev_add_big_long
            break;
        }
        if((div<=num)&&len)
        {
            len--;
            div=(div<<32)+Y.m_ulValue[Y.m_nLength-2];
        }
        div=div/(num+1);
        dev_mov_big_long(&Z,div); //dev_mov_big_long
        if(len)
        {
            Z.m_nLength+=len;
            for(i=Z.m_nLength-1;i>=len;i--)
                Z.m_ulValue[i]=Z.m_ulValue[i-len];
            for(i=0;i<len;i++)
                Z.m_ulValue[i]=0;
        }
        //Mov_Big_Big(&X,Add_Big_Big(X,Z));
        dev_add_big_big(&X,X,Z); //dev_add_big_big
        //Mov_Big_Big(&Y,Sub_Big_Big(Y,Mul_Big_Big(A,Z)));
        dev_mul_big_big(&T,*dev_A,Z);
        dev_sub_big_big(&Y,Y,T);
    }
    dev_mov_big_big(&(dev_YY[idx]),X);

}


void Div_Big_Big_para(CBigInt *MM,CBigInt N, CBigInt A,int parasize)
{
	if(A.m_nLength==1)
		Div_Big_Long_para(MM,N,A.m_ulValue[0],parasize);
	else
	{
        //emmm 直接把下面的函数放入到kernal岂不是很蠢吗 不管了 先这样做着
        CBigInt *h_N, *h_YY, *dev_N,*dev_YY;
        CBigInt *h_A,*dev_A;
        // host alloc and cuda malloc in one time
        CHECK(cudaHostAlloc((void**) &h_N,sizeof(CBigInt),cudaHostAllocDefault));
        CHECK(cudaHostAlloc((void**) &h_A,sizeof(CBigInt),cudaHostAllocDefault));
        CHECK(cudaHostAlloc((void**) &h_YY,parasize*(sizeof(CBigInt)),cudaHostAllocDefault));
    
        memcpy(h_N,&N,sizeof(CBigInt));
        memcpy(h_A,&A,sizeof(CBigInt));
        //printf("h_N = %s\n",Put(*h_N,HEX));
        //printf("h_A = %s\n",Put(*h_A,HEX));
    
        CHECK(cudaMalloc((void **)&dev_N,sizeof(CBigInt)));
        CHECK(cudaMalloc((void **)&dev_A,sizeof(CBigInt)));
        CHECK(cudaMalloc((void **)&dev_YY,parasize*(sizeof(CBigInt))));
    
        assignn_Big_to_Big_para(h_YY,N,32);

        // transfer the array to the GPU my dude. Copy's contents of h_in to d_in
        cudaMemcpy(dev_A, h_A, sizeof(CBigInt), cudaMemcpyHostToDevice);
        cudaMemcpy(dev_N, h_N, sizeof(CBigInt), cudaMemcpyHostToDevice);
        cudaMemcpy(dev_YY, h_YY, parasize*(sizeof(CBigInt)), cudaMemcpyHostToDevice);

        // launch the kernel
        div_big_big_thread<<<1,parasize>>>(dev_YY,dev_N,dev_A);

        // copy the result back to the CPU mem
        cudaMemcpy(h_YY, dev_YY, parasize*(sizeof(CBigInt)), cudaMemcpyDeviceToHost);

        //Mov_Big_Big(Y,h_YY[0]);
        memcpy(MM,h_YY,parasize*(sizeof(CBigInt)));

        
        cudaFree(h_N);
        cudaFree(h_A);
        cudaFree(h_YY);
        cudaFree(dev_N);
        cudaFree(dev_A);
        cudaFree(dev_YY);

        
	}
}


/****************************************************************************************
大数求模
调用形式：Mod_Big_Big_para(Z,N,A,num)
返回值：Z=N%A
****************************************************************************************/
__global__ void mod_big_big_thread(CBigInt *dev_YY, CBigInt *dev_N,CBigInt *dev_A){
    int idx = threadIdx.x;    
    CBigInt X,Y;
	unsigned long long div,num;
	//unsigned long carry=0;
	unsigned int i,len;
	dev_cbigintinit(&X);
	dev_cbigintinit(&Y);
	dev_mov_big_big(&X,*dev_N);
	while(dev_cmp(&X,dev_A)>=0)
	{
		div=X.m_ulValue[X.m_nLength-1];
		num=dev_A->m_ulValue[dev_A->m_nLength-1];
		len=X.m_nLength-dev_A->m_nLength;
		if((div==num)&&(len==0))
		{
			//Mov_Big_Big(&X,Sub_Big_Big(X,A));
			dev_sub_big_big(&X,X,*dev_A);
			break;
		}
		if((div<=num)&&len)
		{
			len--;div=(div<<32)+X.m_ulValue[X.m_nLength-2];
		}
		div=div/(num+1);
		dev_mov_big_long(&Y,div);		
		//Mov_Big_Big(&Y,Mul_Big_Big(A,Y));
		dev_mul_big_big(&Y,*dev_A,Y);
		if(len)
		{
			Y.m_nLength+=len;
			for(i=Y.m_nLength-1;i>=len;i--)
				Y.m_ulValue[i]=Y.m_ulValue[i-len];
			for(i=0;i<len;i++)
				Y.m_ulValue[i]=0;
		}
		//Mov_Big_Big(&X,Sub_Big_Big(X,Y));
		dev_sub_big_big(&X,X,Y);
	}
	dev_mov_big_big(&(dev_YY[idx]),X);

}

void Mod_Big_Big_para(CBigInt *ZZ,CBigInt N, CBigInt A, int parasize)
{
    CBigInt *h_N, *h_YY, *dev_N,*dev_YY;
    CBigInt *h_A,*dev_A;
    // host alloc and cuda malloc in one time
    CHECK(cudaHostAlloc((void**) &h_N,sizeof(CBigInt),cudaHostAllocDefault));
    CHECK(cudaHostAlloc((void**) &h_A,sizeof(CBigInt),cudaHostAllocDefault));
    CHECK(cudaHostAlloc((void**) &h_YY,parasize*(sizeof(CBigInt)),cudaHostAllocDefault));

    memcpy(h_N,&N,sizeof(CBigInt));
    memcpy(h_A,&A,sizeof(CBigInt));
    //printf("h_N = %s\n",Put(*h_N,HEX));
    //printf("h_A = %s\n",Put(*h_A,HEX));

    CHECK(cudaMalloc((void **)&dev_N,sizeof(CBigInt)));
    CHECK(cudaMalloc((void **)&dev_A,sizeof(CBigInt)));
    CHECK(cudaMalloc((void **)&dev_YY,parasize*(sizeof(CBigInt))));

    //assignn_Big_to_Big_para(h_YY,N,32);

    // transfer the array to the GPU my dude. Copy's contents of h_in to d_in
    cudaMemcpy(dev_A, h_A, sizeof(CBigInt), cudaMemcpyHostToDevice);
    cudaMemcpy(dev_N, h_N, sizeof(CBigInt), cudaMemcpyHostToDevice);
    //cudaMemcpy(dev_YY, h_YY, parasize*(sizeof(CBigInt)), cudaMemcpyHostToDevice);

    // launch the kernel
    mod_big_big_thread<<<1,parasize>>>(dev_YY,dev_N,dev_A);

    // copy the result back to the CPU mem
    cudaMemcpy(h_YY, dev_YY, parasize*(sizeof(CBigInt)), cudaMemcpyDeviceToHost);

    //Mov_Big_Big(Y,h_YY[0]);
    memcpy(ZZ,h_YY,parasize*(sizeof(CBigInt)));

    
    cudaFree(h_N);
    cudaFree(h_A);
    cudaFree(h_YY);
    cudaFree(dev_N);
    cudaFree(dev_A);
    cudaFree(dev_YY);

}
__global__ void mod_big_big_thread(unsigned long *ZZ, CBigInt *N, unsigned long *A){
    int idx = threadIdx.x;   
	unsigned long long div;
	unsigned long carry=0;
	int i;
	if(N->m_nLength==1){
        ZZ[idx] = N->m_ulValue[0]%(*A);
        return;
    }
		

	for(i=N->m_nLength-1;i>=0;i--)
	{
		div=N->m_ulValue[i];
		div+=carry*0x100000000;
		carry=(unsigned long)(div%(*A));
	}
    ZZ[idx] = carry;
	return;
}

void Mod_Big_Long_para(unsigned long *ZZ, CBigInt N, unsigned long A,int parasize)
{
	CBigInt *h_N, *dev_N;
    unsigned long *h_A,*dev_A,*h_ZZ,*dev_ZZ;
    // host alloc and cuda malloc in one time
	CHECK(cudaHostAlloc((void**) &h_N,sizeof(CBigInt),cudaHostAllocDefault));
    CHECK(cudaHostAlloc((void**) &h_A,sizeof(unsigned long),cudaHostAllocDefault));
    CHECK(cudaHostAlloc((void**) &h_ZZ,parasize*(sizeof(unsigned long)),cudaHostAllocDefault));
 
    memcpy(h_N,&N,sizeof(CBigInt));
    memcpy(h_A,&A,sizeof(unsigned long));
    //printf("h_N = %s\n",Put(*h_N,HEX));
    //printf("h_A = %s\n",Put(*h_A,HEX));
  
    CHECK(cudaMalloc((void **)&dev_N,sizeof(CBigInt)));
    CHECK(cudaMalloc((void **)&dev_A,sizeof(unsigned long)));
    CHECK(cudaMalloc((void **)&dev_ZZ,parasize*(sizeof(unsigned long))));

    // transfer the array to the GPU my dude. Copy's contents of h_in to d_in
    cudaMemcpy(dev_A, h_A, sizeof(unsigned long), cudaMemcpyHostToDevice);
    cudaMemcpy(dev_N, h_N, sizeof(CBigInt), cudaMemcpyHostToDevice);
    //cudaMemcpy(dev_ZZ, h_ZZ, parasize*(sizeof(CBigInt)), cudaMemcpyHostToDevice);

    // launch the kernel
    mod_big_big_thread<<<1,parasize>>>(dev_ZZ,dev_N,dev_A);

    // copy the result back to the CPU mem
    cudaMemcpy(h_ZZ, dev_ZZ, parasize*(sizeof(unsigned long)), cudaMemcpyDeviceToHost);

    //Mov_Big_Big(Y,h_YY[0]);
    memcpy(ZZ,h_ZZ,parasize*(sizeof(unsigned long)));

    
    cudaFree(h_N);
    cudaFree(h_A);
    cudaFree(h_ZZ);
    cudaFree(dev_N);
    cudaFree(dev_A);
    cudaFree(dev_ZZ);
}


/****************************************************************************************
从字符串按10进制或16进制格式输入到 N个 大数
调用格式：Get(N,str,sys)
返回值：N被赋值为相应大数
sys暂时只能为10或16
****************************************************************************************/
__global__ void get_para_thread(CBigInt *dev_NN, char* dev_str, unsigned int dev_system, int str_len){
    int idx = threadIdx.x;   
    int i;
	int k;
	dev_cbigintinit(&(dev_NN[idx]));

	
	dev_mov_big_long(&(dev_NN[idx]),0);

	for(i = 0; i < str_len; i++)
	{
		dev_mul_big_long(&(dev_NN[idx]),dev_NN[idx],(unsigned long)dev_system);
		if((dev_str[i]>='0')&&(dev_str[i]<='9'))
			k=dev_str[i]-48;
		else 
			if((dev_str[i]>='A')&&(dev_str[i]<='F'))
				k=dev_str[i]-55;
		else 
			if((dev_str[i]>='a')&&(dev_str[i]<='f'))
				k=dev_str[i]-87;
		else k=0;

		dev_add_big_long(&(dev_NN[idx]),dev_NN[idx],k);

	}


}
void Get_para(CBigInt *NN, char* str, unsigned int system, int parasize)
{
    
    CBigInt *h_NN, *dev_NN;
    char *h_str,*dev_str;
    int h_len = strlen(str);
    
    // host alloc and cuda malloc in one time
	CHECK(cudaHostAlloc((void**) &h_NN,parasize*sizeof(CBigInt),cudaHostAllocDefault));
    CHECK(cudaHostAlloc((void**) &h_str,1024,cudaHostAllocDefault));

    strcpy(h_str,str);

  
    CHECK(cudaMalloc((void **)&dev_NN,parasize*sizeof(CBigInt)));
    CHECK(cudaMalloc((void **)&dev_str,1024));

    // transfer the array to the GPU my dude. Copy's contents of h_in to d_in
    cudaMemcpy(dev_str, h_str, 1024, cudaMemcpyHostToDevice);


    // launch the kernel
    get_para_thread<<<1,parasize>>>(dev_NN,dev_str,system,h_len);

    // copy the result back to the CPU mem
    cudaMemcpy(h_NN, dev_NN, parasize*(sizeof(CBigInt)), cudaMemcpyDeviceToHost);

    memcpy(NN,h_NN,parasize*(sizeof(CBigInt)));
    
    cudaFree(h_NN);
    cudaFree(h_str);
    cudaFree(dev_NN);
    cudaFree(dev_str);
	
}

/****************************************************************************************
将大数按10进制或16进制格式输出为字符串
调用格式：Put_para(N,str,sys,num)
返回值：无，直接GPU打印多个大数为16或者10进制字符串 
sys暂时只能为10或16
****************************************************************************************/
__global__ void put_para_thread(CBigInt *dev_NN, unsigned int dev_system){
    int idx = threadIdx.x;
    printf("dev_NN[%d] CBigInt = %s\n",idx,dev_put(&(dev_NN[idx]),dev_system));
}

void Put_para(CBigInt *NN, unsigned int system,int parasize)
{
    CBigInt *dev_NN;

    // host alloc and cuda malloc in one time
    CHECK(cudaMalloc((void **)&dev_NN,parasize*sizeof(CBigInt)));


    // transfer the array to the GPU my dude. Copy's contents of h_in to d_in
    cudaMemcpy(dev_NN, NN, parasize*sizeof(CBigInt), cudaMemcpyHostToDevice);

    // launch the kernel
    put_para_thread<<<1,parasize>>>(dev_NN,system);
    // copy the result back to the CPU mem
    cudaFree(dev_NN);
	
}


/****************************************************************************************
求不定方程ax-by=1的最小整数解
调用方式：Inv_para(N,A,num)
返回值：Z,满足：NZ mod A=1
****************************************************************************************/
__global__ void inv_para_thread(CBigInt *dev_NN, CBigInt *dev_N, CBigInt *dev_A){
    int idx = threadIdx.x;
	CBigInt M,E,X,Y,I,J;
	int x,y;	
	dev_cbigintinit(&M);
	dev_cbigintinit(&E);
	dev_cbigintinit(&X);
	dev_cbigintinit(&Y);
	dev_cbigintinit(&I);
	dev_cbigintinit(&J);
	if(dev_cmp(dev_N,dev_A)>=0)//dev_cmp
		dev_mod_big_big(dev_N,*dev_N,*dev_A);//dev_mod_big_big
	dev_mov_big_big(&M,*dev_A);
	dev_mov_big_big(&E,*dev_N);
	dev_mov_big_long(&X,0); //dev_mov_big_long
	dev_mov_big_long(&Y,1);
	x=y=1;
    //printf("Para Test Cbitint  dev_A\n");
    //printf("Para Test Cbitint  dev_A= %s\n",dev_put(dev_A,HEX)); //Put(YY[12],HEX)
	while((E.m_nLength!=1)||(E.m_ulValue[0]!=0))
	{
		//Mov_Big_Big(&I,Div_Big_Big(M,E));
		dev_div_big_big(&I,M,E); //dev_div_big_big
		//Mov_Big_Big(&J,Mod_Big_Big(M,E));
		dev_mod_big_big(&J,M,E);//dev_mod_big_big
		dev_mov_big_big(&M,E);
		dev_mov_big_big(&E,J);
		dev_mov_big_big(&J,Y);
		//Mov_Big_Big(&Y,Mul_Big_Big(Y,I));
		dev_mul_big_big(&Y,Y,I); //dev_mul_big_big
		if(x==y)
		{
			if(dev_cmp(&X,&Y)>=0)
				dev_sub_big_big(&Y,X,Y); // Mov_Big_Big(&Y,Sub_Big_Big(X,Y));
			else
			{
				//Mov_Big_Big(&Y,Sub_Big_Big(Y,X));
				dev_sub_big_big(&Y,Y,X);
				y=0;
			}
		}
		else
		{
			//Mov_Big_Big(&Y,Add_Big_Big(X,Y));
			dev_add_big_big(&Y,X,Y);
			x=1-x;
			y=1-y;
		}
		dev_mov_big_big(&X,J);
	}
	if(x==0)
		dev_sub_big_big(&X,*dev_A,X);  // Mov_Big_Big(&X,Sub_Big_Big(A,X));
	if(dev_cmp(&X,dev_A)>= 0)
	    dev_mod_big_big(&X,X,*dev_A);
	dev_mov_big_big(&(dev_NN[idx]),X); //dev_mov_big_big
}

void Inv_para(CBigInt *ZZ, CBigInt N, CBigInt A, int parasize)
{
    CBigInt *h_N, *dev_N,*dev_ZZ;
    CBigInt *h_A,*dev_A;
    // host alloc and cuda malloc in one time
    CHECK(cudaHostAlloc((void**) &h_N,sizeof(CBigInt),cudaHostAllocDefault));
    CHECK(cudaHostAlloc((void**) &h_A,sizeof(CBigInt),cudaHostAllocDefault));
    //CHECK(cudaHostAlloc((void**) &h_ZZ,parasize*(sizeof(CBigInt)),cudaHostAllocDefault));

    memcpy(h_N,&N,sizeof(CBigInt));
    memcpy(h_A,&A,sizeof(CBigInt));
    //printf("h_N = %s\n",Put(*h_N,HEX));
    //printf("h_A = %s\n",Put(*h_A,HEX));

    CHECK(cudaMalloc((void **)&dev_N,sizeof(CBigInt)));
    CHECK(cudaMalloc((void **)&dev_A,sizeof(CBigInt)));
    CHECK(cudaMalloc((void **)&dev_ZZ,parasize*(sizeof(CBigInt))));

    //assignn_Big_to_Big_para(h_YY,N,32);

    // transfer the array to the GPU my dude. Copy's contents of h_in to d_in
    cudaMemcpy(dev_A, h_A, sizeof(CBigInt), cudaMemcpyHostToDevice);
    cudaMemcpy(dev_N, h_N, sizeof(CBigInt), cudaMemcpyHostToDevice);
    //cudaMemcpy(dev_ZZ, h_ZZ, parasize*(sizeof(CBigInt)), cudaMemcpyHostToDevice);

    // launch the kernel
    inv_para_thread<<<1,parasize>>>(dev_ZZ,dev_N,dev_A);

    // copy the result back to the CPU mem
    cudaMemcpy(ZZ, dev_ZZ, parasize*(sizeof(CBigInt)), cudaMemcpyDeviceToHost);

    //Mov_Big_Big(Y,h_YY[0]);
    //memcpy(ZZ,h_YY,parasize*(sizeof(CBigInt)));

    
    cudaFree(h_N);
    cudaFree(h_A);
    //cudaFree(h_YY);
    cudaFree(dev_N);
    cudaFree(dev_A);
    cudaFree(dev_ZZ);


}

/****************************************************************************************
求乘方的模
调用方式：Exp_para(N,A,B,num)
返回值：Z=N^A MOD B
****************************************************************************************/
__global__ void exp_para_thread(CBigInt *dev_NN, CBigInt *dev_N, CBigInt *dev_A,  CBigInt *dev_B){
    int idx = threadIdx.x;
    CBigInt X,Y,M;
	int i,j,k;
	unsigned int n;
	unsigned long num;
	k=dev_A->m_nLength*32-32;
	num=dev_A->m_ulValue[dev_A->m_nLength-1];
	while(num)
	{
		num=num>>1;
		k++;
	}
	dev_cbigintinit(&X);
	dev_cbigintinit(&Y);
	dev_cbigintinit(&M);
	dev_mov_big_big(&X,*dev_N);
	for(i=k-2;i>=0;i--)
	{
		//Mov_Big_Big(&Y,Mul_Big_Long(X,X.m_ulValue[X.m_nLength-1]));
		dev_mul_big_long(&Y,X,X.m_ulValue[X.m_nLength-1]); //dev_mul_big_long
		//Mov_Big_Big(&Y,Mod_Big_Big(Y,B));
		dev_mod_big_big(&Y,Y,*dev_B); //dev_mod_big_big
		for(n=1;n<X.m_nLength;n++)
		{          
			for(j=Y.m_nLength;j>0;j--)
				Y.m_ulValue[j]=Y.m_ulValue[j-1];
			Y.m_ulValue[0]=0;
			Y.m_nLength++;
			//Mov_Big_Big(&Y,Add_Big_Big(Y,Mul_Big_Long(X,X.m_ulValue[X.m_nLength-n-1])));
			dev_mul_big_long(&Y,X,X.m_ulValue[X.m_nLength-n-1]);
			//Mov_Big_Big(&Y,Mod_Big_Big(Y,B));
			dev_mod_big_big(&Y,Y,*dev_B);
		}
		dev_mov_big_big(&X,Y);
		if((dev_A->m_ulValue[i>>5]>>(i&31))&1)
		{
			//Mov_Big_Big(&Y,Mul_Big_Long(N,X.m_ulValue[X.m_nLength-1]));
			dev_mul_big_long(&Y,*dev_N,X.m_ulValue[X.m_nLength-1]);
			//Mov_Big_Big(&Y,Mod_Big_Big(Y,B));
			dev_mod_big_big(&Y,Y,*dev_B);
			for(n=1;n<X.m_nLength;n++)
			{          
				for(j=Y.m_nLength;j>0;j--)
					Y.m_ulValue[j]=Y.m_ulValue[j-1];
				Y.m_ulValue[0]=0;
				Y.m_nLength++;
				//Mov_Big_Big(&Y,Add_Big_Big(Y,Mul_Big_Long(N,X.m_ulValue[X.m_nLength-n-1])));
				dev_mul_big_long(&M,*dev_N,X.m_ulValue[X.m_nLength-n-1]);
				dev_add_big_big(&Y,Y,M);
				//Mov_Big_Big(&Y,Mod_Big_Big(Y,B));
				dev_mod_big_big(&Y,Y,*dev_B);
			}
			dev_mov_big_big(&X,Y);
		}
	}
	dev_mov_big_big(&(dev_NN[idx]),X);

}

void Exp_para(CBigInt *ZZ, CBigInt N, CBigInt A, CBigInt B, int parasize)
{

    CBigInt *h_N, *dev_N,*dev_ZZ,*h_A,*dev_A,*h_B,*dev_B;;
    // host alloc and cuda malloc in one time
    CHECK(cudaHostAlloc((void**) &h_N,sizeof(CBigInt),cudaHostAllocDefault));
    CHECK(cudaHostAlloc((void**) &h_A,sizeof(CBigInt),cudaHostAllocDefault));
    CHECK(cudaHostAlloc((void**) &h_B,sizeof(CBigInt),cudaHostAllocDefault));
    //CHECK(cudaHostAlloc((void**) &h_ZZ,parasize*(sizeof(CBigInt)),cudaHostAllocDefault));

    memcpy(h_N,&N,sizeof(CBigInt));
    memcpy(h_A,&A,sizeof(CBigInt));
    memcpy(h_B,&B,sizeof(CBigInt));
    //printf("h_N = %s\n",Put(*h_N,HEX));
    //printf("h_A = %s\n",Put(*h_A,HEX));

    CHECK(cudaMalloc((void **)&dev_N,sizeof(CBigInt)));
    CHECK(cudaMalloc((void **)&dev_A,sizeof(CBigInt)));
    CHECK(cudaMalloc((void **)&dev_B,sizeof(CBigInt)));
    CHECK(cudaMalloc((void **)&dev_ZZ,parasize*(sizeof(CBigInt))));

    //assignn_Big_to_Big_para(h_YY,N,32);

    // transfer the array to the GPU my dude. Copy's contents of h_in to d_in
    cudaMemcpy(dev_A, h_A, sizeof(CBigInt), cudaMemcpyHostToDevice);
    cudaMemcpy(dev_N, h_N, sizeof(CBigInt), cudaMemcpyHostToDevice);
    cudaMemcpy(dev_B, h_B, sizeof(CBigInt), cudaMemcpyHostToDevice);
    //cudaMemcpy(dev_ZZ, h_ZZ, parasize*(sizeof(CBigInt)), cudaMemcpyHostToDevice);

    // launch the kernel
    exp_para_thread<<<1,parasize>>>(dev_ZZ,dev_N,dev_A,dev_B);

    // copy the result back to the CPU mem
    cudaMemcpy(ZZ, dev_ZZ, parasize*(sizeof(CBigInt)), cudaMemcpyDeviceToHost);

    //Mov_Big_Big(Y,h_YY[0]);
    //memcpy(ZZ,h_YY,parasize*(sizeof(CBigInt)));

    
    cudaFree(h_N);
    cudaFree(h_A);
    cudaFree(h_B);
    //cudaFree(h_YY);
    cudaFree(dev_N);
    cudaFree(dev_B);
    cudaFree(dev_A);
    cudaFree(dev_ZZ);

}
