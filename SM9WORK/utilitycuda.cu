#include "Bigintcuda.cuh"
#include "utilitycuda.cuh"
#include "Params.h"



__global__ void cintbig_substract_modn_thread(CBigInt *dev_X, CBigInt *dev_a,CBigInt *dev_b,CBigInt *dev_BNn){
    int idx = threadIdx.x;    
    
    CBigInt c,div;
	if(dev_cmp(&dev_a[idx],&dev_b[idx])>=0)
	{
		dev_sub_big_big(&c,dev_a[idx],dev_b[idx]);  //
		if(dev_cmp(&c,&(dev_BNn[idx]))>=0 )
	      dev_mod_big_big(&c,c,dev_BNn[idx]);
	}
    else
	{
		//
		dev_sub_big_big(&c,dev_b[idx],dev_a[idx]);		
		dev_div_big_big(&div,c,dev_BNn[idx]);
		dev_add_big_long(&div,div,1);
		dev_mul_big_big(&div,div,dev_BNn[idx]);
		dev_sub_big_big(&c,div,c);
		if(dev_cmp(&c,&(dev_BNn[idx]))==0)
			dev_mov_big_long(&c,0);
	}

	dev_mov_big_big(&(dev_X[idx]),c);

}


void CBigInt_substract_modN_para(CBigInt *XX, CBigInt *aa, CBigInt *bb,CBigInt *BNn,int parasize){
    CBigInt *dev_XX,*dev_aa,*dev_bb,*dev_BNn;
    CHECK(cudaMalloc((void **) &dev_aa,parasize*(sizeof(CBigInt))));
    CHECK(cudaMalloc((void **) &dev_bb,parasize*(sizeof(CBigInt))));
    CHECK(cudaMalloc((void **) &dev_XX,parasize*(sizeof(CBigInt))));
    CHECK(cudaMalloc((void **) &dev_BNn,parasize*(sizeof(CBigInt))));

    // transfer the array to the GPU my dude. Copy's contents of h_in to d_in
    cudaMemcpy(dev_XX, XX, parasize*(sizeof(CBigInt)), cudaMemcpyHostToDevice);
    cudaMemcpy(dev_aa, aa, parasize*(sizeof(CBigInt)), cudaMemcpyHostToDevice);
    cudaMemcpy(dev_bb, bb, parasize*(sizeof(CBigInt)), cudaMemcpyHostToDevice);
    cudaMemcpy(dev_BNn, BNn, parasize*(sizeof(CBigInt)), cudaMemcpyHostToDevice);

    // launch the kernel
    cintbig_substract_modn_thread<<<1,parasize>>>(dev_XX,dev_aa,dev_bb, dev_BNn);

    // copy the result back to the CPU mem
    cudaMemcpy(XX, dev_XX, parasize*(sizeof(CBigInt)), cudaMemcpyDeviceToHost);

    //Mov_Big_Big(Y,h_YY[0]);
    //memcpy(ZZ,h_YY,parasize*(sizeof(CBigInt)));
    //cudaFree(Bnn);
    //cudaFree(h_A);
    //cudaFree(h_YY);
    cudaFree(dev_bb);
    cudaFree(dev_aa);
    cudaFree(dev_XX);
    cudaFree(dev_BNn);
}