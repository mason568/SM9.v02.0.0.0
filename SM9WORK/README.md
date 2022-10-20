# SM9 software implementation

# 项目依赖
> 在他人写好的库的基础上做优化: https://github.com/Federico2014/SM9

## 头文件包含关系
SM9PKC.h > SM9KA.h > SM9DSA.h > utility.h > BNPairing.h > BNPoint2.h > BNPoint.h > BNField12.h > BNField4.h > BNField2.h > BNField2.h > Params.h > BigInt.h > 

## 编译
```makefile
make
./sm9cuda
```

## 初始（优化前）测试数据
- 测试环境:
    + cpu：Intel(R) Xeon(R) Gold 5220R CPU @ 2.20GHz
    + 内存：131 GB
    + 显卡：NVIDIA Corporation Device 2204

1. 使用标准的BN曲线和参数，参考SM9第五部分

2. 一次pairing时间：412.7 ms

3. 一次R-ate对pairing时间：415.4 ms

4. SM9 数字签名时间：738.8 ms

5. SM9 数字签名验证时间：1327.8 ms

6. SM9 密钥交换协议系统主密钥及加密密钥生成时间：553.0 ms

7. SM9 密钥交换协议时间：3210.0 ms

8. SM9 系统主密钥和用户密钥生成时间：217.0 ms

9. SM9 密钥封装时间：959.3 ms

10. SM9 密钥解封时间：411.7 ms

# 优化一
每次sign都有pairing计算，把计算g = e(P_1,P_pusbs)先计算然后存起来，每次签名只需要从内存中取出来

# 优化二 
底层运算并行





