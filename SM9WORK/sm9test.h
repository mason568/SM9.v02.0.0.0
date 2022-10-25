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

void test_BNField12_speedsqure();
void test_BNField4_speedsqure();
void test_BNField2_speedsqure();

void test_CBigIntInit_para();
void test_Cmp_para();
void test_Mov_Big_Big_para();
void test_Mov_Long_Big_para();
void test_Add_Big_Big_para();
void test_Add_Big_Long_para();
void test_Sub_Big_Big_para();
void test_Sub_Big_Long_para();

void test_Mul_Big_Long_para();
void test_Mul_Big_Big_para();
void test_Div_Big_Long_para();
void test_Div_Big_Big_para();
void test_Mod_Big_Big_para();
void test_Mod_Big_Long_para();

void test_Get_para();
void test_Inv_para();
void test_Exp_para();
void test_pairing();

#endif