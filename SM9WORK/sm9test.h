#ifndef _SM9TEST_H_
#define _SM9TEST_H_

#include "Bigintcuda.cuh" 

void test_BNField2();
void test_BNField4();
void test_BNField12();
void test_BNPoint();
void test_BNPoint2();
void test_Paiiring();
void test_Paiiring_Rate();
void test_Hash1();
void test_Hash2();
void test_SM4();
//重写基础运算
void test_CBigIntInit_para();
void test_Cmp_para();
void test_Mov_Big_Big_para();
void test_Mov_Long_Big_para();
void test_Add_Big_Big_para();
void test_Add_Big_Long_para();
void test_Sub_Big_Big_para();

#endif