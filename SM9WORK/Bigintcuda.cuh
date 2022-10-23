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
    int Cmp_para(CBigInt N,CBigInt A, int parasize);
    void Mov_Big_Big_para(CBigInt *N, CBigInt A, int parasize);
    void assignn_Big_to_Big_para(CBigInt *N, CBigInt A, int parasize);
    void assignn_Long_to_Big_para(CBigInt *N, unsigned long A, int parasize);
    void Add_Big_Big_para(CBigInt *Y, CBigInt N, CBigInt A, int parasize);
    void Add_Big_Long_para(CBigInt *Y, CBigInt N, unsigned long A, int parasize);
    void Sub_Big_Big_para(CBigInt *Y, CBigInt N, CBigInt A, int parasize);
    void Sub_Big_Long_para(CBigInt *Y, CBigInt N, unsigned long A, int parasize);
    //以下的CBigInt *YY为parasize个
    void Mul_Big_Long_para(CBigInt *YY, CBigInt N, unsigned long A, int parasize);
    void Mul_Big_Big_para(CBigInt *YY, CBigInt N, CBigInt A, int parasize);
    void Div_Big_Long_para(CBigInt *YY, CBigInt N, unsigned long A, int parasize);
    void Div_Big_Big_para(CBigInt *MM,CBigInt N, CBigInt A,int parasize);
    void Mod_Big_Big_para(CBigInt *ZZ,CBigInt N, CBigInt A, int parasize);
    void Mod_Big_Long_para(unsigned long *ZZ, CBigInt N, unsigned long A, int parasize);

    void Get_para(CBigInt *NN, char* str, unsigned int system, int parasize);
    void Put_para(CBigInt *NN, unsigned int system,int parasize);
    void Inv_para(CBigInt *ZZ, CBigInt N, CBigInt A, int parasize);
    void Exp_para(CBigInt *ZZ, CBigInt N, CBigInt A, CBigInt B, int parasize);

#ifdef __cplusplus
}
#endif

#endif /* __INCvxWorksh */