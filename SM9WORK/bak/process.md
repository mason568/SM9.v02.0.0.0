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

# 2022.10.21
> @zjc 重写底层运算函数Bigint.c并测试， 修改之前有纰漏的地方
```
void assignn_Long_to_Big_para(CBigInt *N, unsigned long A, int parasize);
void Add_Big_Big_para(CBigInt *Y, CBigInt N, CBigInt A, int parasize);
void Add_Big_Long_para(CBigInt *Y, CBigInt N, unsigned long A, int parasize);
void Sub_Big_Big_para(CBigInt *Y, CBigInt N, CBigInt A, int parasize);
void Sub_Big_Long_para(CBigInt *Y, CBigInt N, unsigned long A, int parasize);
```
> 统一了向上的接口规则，返回/修改 parasize个数组，而不是一个元素，  Sub_Big_Long_para 之上的额函数都还没有改，改动的话也要改测试函数的使用。

> 一些简单的函数可以直接放在gpu中做。比如说
```
__device__ int dev_cmp(CBigInt *d_N,CBigInt *d_A);
__device__ void dev_mov_big_long(CBigInt *d_N,unsigned long d_A);
__device__ void dev_mov_big_big(CBigInt *d_N, CBigInt d_A);
__device__ void dev_cbigintinit(CBigInt *d_A);
```
