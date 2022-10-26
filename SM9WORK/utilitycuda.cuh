#ifndef _UTILITYCUDA_H_  /*防止该头文件被重复引用*/
#define _UTILITYCUDA_H_

//#include <bits/types.h>
//#include "BNPairing.h"


#ifdef __cplusplus    //__cplusplus是cpp中自定义的一个宏
extern "C" {          //告诉编译器，这部分代码按C语言的格式进行编译，而不是C++的
#endif
    #include "common.h"
    #include "BigInt.h"
    __global__ void cintbig_substract_modn_thread(CBigInt *dev_YY, CBigInt *dev_N,CBigInt *dev_A);
    /**** some declaration or so *****/  
    void CBigInt_substract_modN_para(CBigInt *XX, CBigInt *aa, CBigInt *bb,int parasize);
#ifdef __cplusplus
}
#endif

#endif /* __INCvxWorksh */