
#include <stdio.h>
#include <time.h>
#include <sys/time.h>
#include "square063.cuh"
//#include "Bigintcuda.cuh"

#include "sm9test.h"
#include "SM9PKC.h"

int main(){
	//printf("this is test!\n");

    //CBigInt X;
    //CBigIntInit(&X);
    //CBigIntInit_para(&X,32);
    //printf("init X = %s\n",Put(X,HEX));

    /*
    //SM9基础测试
    unsigned int aa= 0x12345678123456780;
    printf(" %x \n",aa);
    getchar();
    CBigInt a;
    
    Get(&a,"1234567890abceeeeeeee",HEX);
    for(int i=a.m_nLength-1;i>=0;i--)
    {
        printf("%x ",a.m_ulValue[i]);
    }
    printf("\n");
    printf("a = %s\n",Put(a,HEX));
    getchar();
    printf("注：从左到右分别为从高位到低位！\n");
    */
    
	/*
	SM9Params_init(&BN);//一定要有，否则会出现总线错误

	
    test_BNField2();
    test_BNField4();
    test_BNField12();
    test_BNPoint();
    test_BNPoint2();
    test_Paiiring();
    test_Paiiring_Rate();
    test_Hash1();
    test_Hash2();
	test_SM4();
	DSA_Demo();  //签名demo
	KA_Demo();   //密钥交换demo
	KEM_demo();  //加解密demo
    
    printf("GPU test ...\r");
    squaretest();
    printf("GPU test over!\r");
    */

    
    
    
    /*      重写函数的测试      */  
    //test_CBigIntInit_para();
    //test_Cmp_para();
    //test_Mov_Big_Big_para();
    //test_Mov_Long_Big_para();
    //test_Add_Big_Big_para();
    //test_Add_Big_Long_para();
    //test_Sub_Big_Big_para();
    //test_Sub_Big_Long_para();
    //test_Mul_Big_Long_para();
    //test_Mul_Big_Big_para();
    //test_Div_Big_Long_para();
    //test_Div_Big_Big_para();
    //test_Mod_Big_Big_para();
    //test_Mod_Big_Long_para();
    //test_Get_para();
    //test_Get_para();
    //test_Inv_para();
    //test_Exp_para();
    SM9Params_init(&BN);//一定要有，否则会出现总线错误
    //test_BNField2();
    //test_BNField12();
    //test_BNField12_speedsqure();
    //test_BNField4_speedsqure();
    //test_BNField2_speedsqure();

    parallel_DSA_Demo();
    //DSA_Demo();  //签名demo
    //test_pairing();

    return 0;
} 


