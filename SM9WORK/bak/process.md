# 2022.10.19
> @zjc c程序cuda程序混合编译，测试原始项目

# 2022.10.20 
> @zjc 开始重写底层运算函数Bigint.c并测试，  
```
void CBigIntInit_para(CBigInt *A,int parasize);
int Cmp_para(CBigInt N,CBigInt A, int parasize);
void Mov_Big_Big_para(CBigInt *N, CBigInt A, int parasize);
void assignn_Big_to_Big_para(CBigInt *N, CBigInt A, int parasize);
```