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


# 2022.10.22
> @zjc 将一些基本的运算，直接改写成在__device__ 函数，由GPU进行调用，便于并行如Mod_Big_Big_para这样的函数

> 重写了一些函数,并测试
```
//以下的CBigInt *YY为parasize个
void Mul_Big_Long_para(CBigInt *YY, CBigInt N, unsigned long A, int parasize);
void Mul_Big_Big_para(CBigInt *YY, CBigInt N, CBigInt A, int parasize);
void Div_Big_Long_para(CBigInt *YY, CBigInt N, unsigned long A, int parasize);
void Div_Big_Big_para(CBigInt *MM,CBigInt N, CBigInt A,int parasize);
void Mod_Big_Big_para(CBigInt *ZZ,CBigInt N, CBigInt A, int parasize);
void Mod_Big_Long_para(unsigned long *ZZ, CBigInt N, unsigned long A, int parasize);
```


# 2022.20.23 
## todo:
1. 合并橙子哥的代码，确认接口引用方式，再修改

2. 重新写签名函数的，并行版本，给出第一个优化版本的测试数据

3. 测试双线性对速度，在不同的parasize上实验
## idea
我感觉是完不成了，争取明天后天把上面的todo做完，然后一天做一个讨论会上讲的优化方案？？？？ 
