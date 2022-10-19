///////////////////////////////////////////////////////////////////////////
// Example code from the Udacity tutorial on CUDA                        //
// Link to the video here: https://www.youtube.com/watch?v=GiGE3QjwknQ   //
// TO COMPILE: $ nvcc -o square square.cu                                //
///////////////////////////////////////////////////////////////////////////

//
// NOTES:
//  * Device: is the term of the GPU
//  * Host: is the term of the CPU
//  * kernels are the only things run in parallel on the GPU
//  * everything in the main is run on CPU
//  * memory transfers between Host (CPU) and Device (GPU) should be minimal
//  * kernels all run at the same time
//  * threads can know their Id's with threadIdx.x, blocks are similar
//

#include <stdio.h>
#include "gputimer.h"
#include "square063.cuh"

// kernel to be run on the TX2
__global__ void square(float *d_out, float *d_in){
  int idx = threadIdx.x; // this is how you get the thread index
  float f = d_in[idx];
  d_out[idx] = f*f;
}



// kernel to be run on the GTX 3090

// main is here. this is the CPU code. 

void squaretest(){

  // the size of the array, which is really the thread count per block
  const int ARRAY_SIZE = 1024; // max thread count per block on the TX2
  // total bytes in the array
  const int ARRAY_BYTES = ARRAY_SIZE * sizeof(float);

  // generate the input array on the host for the device my dude
  float h_in[ARRAY_SIZE];
  for (int i = 0; i < ARRAY_SIZE; i++){
    h_in[i] = float(i);
  }
  float h_out[ARRAY_SIZE]; // make the other array too my guy
  
  // make the pointers that point to the mem locations on the GPU m'lady
  float *d_in;
  float *d_out;

  //allocate the memory on the GPU my man
  cudaMalloc((void **) &d_in, ARRAY_BYTES);
  cudaMalloc((void **) &d_out, ARRAY_BYTES);

  // transfer the array to the GPU my dude. Copy's contents of h_in to d_in
  cudaMemcpy(d_in, h_in, ARRAY_BYTES, cudaMemcpyHostToDevice);

  // launch the kernel
  square<<<1,ARRAY_SIZE>>>(d_out,d_in);

  // copy the result back to the CPU mem
  cudaMemcpy(h_out, d_out, ARRAY_BYTES, cudaMemcpyDeviceToHost);

  // print the result
  for (int i = 0; i < ARRAY_SIZE; i++){
    printf("%f", h_out[i]);
    printf(((i % 4) != 3) ? "\t" : "\n");
  }
  // free the device yo
  cudaFree(d_in);
  cudaFree(d_out);
}

