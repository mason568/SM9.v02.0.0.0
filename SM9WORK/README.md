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
正确性：现在，假设所有的参数都是一样的，比如说签名，用同样的曲线，一样的随机数，一样的ida... 那么最底层的运算会保持一致性，即所有线程干同样的事情，数据也一样

问题：有很多函数虽然披着并行的壳，但它实际返回的参数只有数组的第一个元素


# 优化三 
修改2 4 12 扩域上的平方运算
## 平方优化结果
1. 直接修改单个层次的运算

```
test_BNField12_speedsquare 1000 times test: Begin! 
microsecond: 561741 us
microsecond: 470745 us
speed up 1 to 1.193302
Test passed!
test_BNField12_speedsqure test: over! 
test_BNField4_speedsquare 1000 times test: Begin! 
microsecond: 67406 us
microsecond: 71497 us
speed up 1 to 0.942781
Test passed!
test_BNField4_speedsquare test: over! 
test_BNField2_speedsquare 1000 times test: Begin! 
microsecond: 16800 us
microsecond: 16405 us
speed up 1 to 1.024078
BNField2 test: b1 ^2 != b1*b1    
test_BNField2_speedsquare test: over! 
```

2. 各乘均修改后的结果
```
test_BNField12_speedsquare 1000 times test: Begin! 
microsecond: 562487 us
microsecond: 473135 us
speed up 1 to 1.188851
Test passed!
test_BNField12_speedsquare test: over! 
test_BNField4_speedsquare 1000 times test: Begin! 
microsecond: 66886 us
microsecond: 71112 us
speed up 1 to 0.940573
Test passed!
test_BNField4_speedsquare test: over! 
test_BNField2_speedsquare 1000 times test: Begin! 
microsecond: 16734 us
microsecond: 16456 us
speed up 1 to 1.016894
Test passed!
test_BNField2_speedsquare test: over! 
```

3. BNField2_speedsquare 好像有问题，虽然单个测试没问题，但是把他放到F4_square() 让 调用F12_square() 中会出错 ,所以等于最后修改BNField12_speedsqure 和  BNField4_speedsqure ，除非bug解决，否则不动 NField2_square
- 10000次效果变小
``` 
test_BNField12_speedsquare 10000 times test: Begin! 
BNField2 test: TN1 == TN2        
BNField2 test: TN1 == SN1        
BNField2 test: TN2 == SN1        
microsecond: 4771111 us
microsecond: 4746067 us
speed up 1 to 1.005277
test_BNField12_speedsqure test: over! 
test_BNField4_speedsquare 10000 times test: Begin! 
microsecond: 652855 us
microsecond: 702711 us
speed up 1 to 0.929052
Test passed!
test_BNField4_speedsquare test: over! 
test_BNField2_speedsquare 10000 times test: Begin! 
microsecond: 165521 us
microsecond: 164100 us
speed up 1 to 1.008659
Test passed!
test_BNField2_speedsquare test: over! 
```



