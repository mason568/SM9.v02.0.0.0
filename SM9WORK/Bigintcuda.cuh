#ifndef _BIGINTCUDA_H_  /*防止该头文件被重复引用*/
#define _BIGINTCUDA_H_

#include <bits/types.h>

typedef __uint8_t uint8_t;
typedef __uint16_t uint16_t;
typedef __uint32_t uint32_t;
typedef __uint64_t uint64_t;



#ifdef __cplusplus    //__cplusplus是cpp中自定义的一个宏
extern "C" {          //告诉编译器，这部分代码按C语言的格式进行编译，而不是C++的
#endif
    #include "BigInt.h"
    #include "common.h"
    /**** some declaration or so *****/  
    void CBigIntInit_para(CBigInt *A,int parasize);
    char* Put(CBigInt N, unsigned int system);
    void Mov_Big_Big(CBigInt *N, CBigInt A);


#ifdef __cplusplus
}
#endif

#endif /* __INCvxWorksh */