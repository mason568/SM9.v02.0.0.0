#include "SM9DSA.h"
#include "Bigintcuda.cuh"
#include "utilitycuda.cuh"
//为g=e(P1,P_pubs)赋值
void geP1Ppubs_assign(struct SM9DSAParams *signpre, BNPoint2 P_pub, BNPoint P1){
    BNField12 g;
    Pairing_opt(&g,P_pub,P1);
    F12_construct(&signpre->geP1Ppubs,g.re,g.im,g.sq);
}

#if 0
void DSA_Demo()
{
	CBigInt a,b,c,d,e,f,ks,h,h2;
	BNField2 b1,b2;
	BNPoint2 P2,P_pub_s;
	BNPoint P1,dsA,S;
	BYTE id[]="Alice";
	BYTE M[] = "Chinese IBS standard";
	int sign;
	clock_t start,finish;
	double time1,time2,time3;

    //printf("begin!!! \n");
    //char *str1 = "93DE051D62BF718FF5ED0704487D01D6E1E4086909DC3280E8C4E4817C66DDDD";
    //printf("this is a test for string ggg: %s \n",str1);

	Get(&a,"93DE051D62BF718FF5ED0704487D01D6E1E4086909DC3280E8C4E4817C66DDDD",HEX);
	Get(&b,"21FE8DDA4F21E607631065125C395BBC1C1C00CBFA6024350C464CD70A3EA616",HEX);
	Get(&c,"85AEF3D078640C98597B6027B441A01FF1DD2C190F5E93C454806C11D8806141",HEX);
	Get(&d,"3722755292130B08D2AAB97FD34EC120EE265948D19C17ABF9B7213BAF82D65B",HEX);
	Get(&e,"17509B092E845C1266BA0D262CBEE6ED0736A96FA347C8BD856DC76B84EBEB96",HEX);
	Get(&f,"A7CF28D519BE3DA65F3170153D278FF247EFBA98A71A08116215BBA5C999A7C7",HEX);

    //printf("eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee = %s\n",Put(a,HEX));
     //getchar();
    P_construct_xy(&P1,a,b);
	F2_construct(&b1,d,c);
	F2_construct(&b2,f,e);    
    P2_construct_xy(&P2,b1,b2);
    
	
	//密钥生成阶段
	Get(&ks,"0130E78459D78545CB54C587E02CF480CE0B66340F319F348A1D5B1F2DC5F4",HEX);
	P2_multiply(&P_pub_s,P2,ks);
	P2_normorlize(&P_pub_s,P_pub_s);
	start = clock();
	
	DSA_Keygen(&dsA,ks,id,P1);
	finish = clock();
	
	time1 = (double)(finish-start);
	P_normorlize(&dsA,dsA);

    //g预计算阶段
    geP1Ppubs_assign(&SIGNPRE,P1,P_pub_s);


    //数字签名阶段
	start = clock();
	int count = 10; //一共需要处理的数量
    const int num=10;//一次性处理的数量  count为num的整数倍


    struct timeval tv1,tv2;
	long time_begin,time_end;
    gettimeofday(&tv1,NULL);//获取开始时间
    printf("sign 10 time:\n");
    printf("second: %d\n", tv1.tv_sec);  //秒
    printf("millisecond: %d\n", tv1.tv_sec*1000 + tv1.tv_usec/1000);  //毫秒
    printf("microsecond: %d\n", tv1.tv_sec*1000000 + tv1.tv_usec); //微秒

	/*
	//sequential
    while(count){

        DSA_Sign(&h, &S, M, P1, P_pub_s, dsA);
        //res = SM9_Verify(msg, 20, &sign, &pk, NULL);
        count--;
    }*/
    
    //parallel
    /*
	CBigInt *para_h[num];
	BNPoint *para_S[num];
	BNPoint para_dsA[num];
	for(int i=0;i<num;i++)
	{
		para_h[i]=&h;
		para_S[i]= &S;
		para_dsA[i]=dsA;
	}
    */
	for(int i=0;i<(count/num);i++)
	{
        DSA_Sign(&h, &S, M, P1, P_pub_s,dsA);	
	}
    

	gettimeofday(&tv2,NULL);//获取程序结束的时刻，两个时刻作差即可获得运行时间
    printf("second: %d s\n",tv2.tv_sec - tv1.tv_sec);  //秒
    printf("millisecond: %d ms\n", tv2.tv_sec*1000 + tv2.tv_usec/1000 - (tv1.tv_sec*1000 + tv1.tv_usec/1000));  //毫秒
    printf("microsecond: %d us\n", tv2.tv_sec*1000000 + tv2.tv_usec - (tv1.tv_sec*1000000 + tv1.tv_usec)); //微秒


	finish = clock();
	time2 = (double)(finish-start);
	//数字签名验证阶段
	start = clock();
	sign = DSA_Verify(&h2, h, S, M, id, P1, P2, P_pub_s);
	finish = clock();	
	time3 = (double)(finish-start);
	printf("\n********************************************\n");
	printf("*********SM9 数字签名算法实例演示*********** \n");
	printf("********************************************\n");
	printf("***********************\n");
	printf("****1、密钥生成阶段****\n");
	printf("***********************\n");
	printf("G1生成元P1 = \n");
	P_toString(P1,HEX);
	printf("G2生成元P2 = \n");
	P2_toString(P2,HEX);
	printf("签名主私钥ks = %s\n",Put(ks,HEX));
	printf("签名主公钥 P_pub_s = [ks]P2 = \n");
	P2_toString(P_pub_s,HEX);
	printf("实体A的标识IDA: %s\n",id);
	printf("签名私钥dsA = \n");
	P_toString(dsA,HEX);
	printf("\n***********************\n");
	printf("****2、数字签名阶段****\n");
	printf("***********************\n");
	printf("待签名的消息M: %s\n",M);
	printf("消息M的签名为（h,S）: \n");
	printf("h = %s\n",Put(h,HEX));
	printf("S = \n");
	P_toString(S,HEX);
	printf("\n***************************\n");
	printf("****3、数字签名验证阶段****\n");
	printf("***************************\n");
	printf("h2 = %s\n",Put(h2,HEX));
	if(sign)
		printf("h2 = h, 签名验证能过！\n");
	else
		printf("h2 != h, 签名验证失败！\n");

	printf("\nSM9 数字签名密钥生成时间：%f ms\n",time1);
	printf("SM9 数字签名时间：%f ms\n",time2);
	printf("SM9 数字签名验证时间：%f ms\n",time3);
}
#endif

void DSA_Demo()
{
	CBigInt a,b,c,d,e,f,ks,h,h2;
	BNField2 b1,b2;
	BNPoint2 P2,P_pub_s;
	BNPoint P1,dsA,S;

	BYTE id[]="Alice";
	BYTE M[] = "Chinese IBS standard";
	int sign;
	clock_t start,finish;
	double time1,time2,time3;

	Get(&a,"93DE051D62BF718FF5ED0704487D01D6E1E4086909DC3280E8C4E4817C66DDDD",HEX);
	Get(&b,"21FE8DDA4F21E607631065125C395BBC1C1C00CBFA6024350C464CD70A3EA616",HEX);
	Get(&c,"85AEF3D078640C98597B6027B441A01FF1DD2C190F5E93C454806C11D8806141",HEX);
	Get(&d,"3722755292130B08D2AAB97FD34EC120EE265948D19C17ABF9B7213BAF82D65B",HEX);
	Get(&e,"17509B092E845C1266BA0D262CBEE6ED0736A96FA347C8BD856DC76B84EBEB96",HEX);
	Get(&f,"A7CF28D519BE3DA65F3170153D278FF247EFBA98A71A08116215BBA5C999A7C7",HEX);

    P_construct_xy(&P1,a,b);
	F2_construct(&b1,d,c);
	F2_construct(&b2,f,e);    
    P2_construct_xy(&P2,b1,b2);
    
	printf("File: %s Func:%s Line: %d\n",__FILE__ ,__func__,__LINE__); 
	//密钥生成阶段
	Get(&ks,"0130E78459D78545CB54C587E02CF480CE0B66340F319F348A1D5B1F2DC5F4",HEX);
	P2_multiply(&P_pub_s,P2,ks);
	P2_normorlize(&P_pub_s,P_pub_s);
    
	start = clock();
	DSA_Keygen(&dsA,ks,id,P1);
	finish = clock();
    
	time1 = (double)(finish-start);
	P_normorlize(&dsA,dsA);
    //g预计算阶段
    
    geP1Ppubs_assign(&SIGNPRE,P_pub_s,P1);

    //数字签名阶段
    
	start = clock();
    int count = 10; //一共需要处理的数量
    const int num=10;//一次性处理的数量  count为num的整数倍


    struct timeval tv1,tv2;
	long time_begin,time_end;
    gettimeofday(&tv1,NULL);//获取开始时间
    printf("sign 1 time:\n");
    printf("second: %d\n", tv1.tv_sec);  //秒
    printf("millisecond: %d\n", tv1.tv_sec*1000 + tv1.tv_usec/1000);  //毫秒
    printf("microsecond: %d\n", tv1.tv_sec*1000000 + tv1.tv_usec); //微秒
    for(int i=0;i<count/num;i++)
	{
        DSA_Sign(&h, &S, M, P1, P_pub_s, dsA);	
	}


	//DSA_Sign(&h, &S, M, P1, P_pub_s, dsA);
    gettimeofday(&tv2,NULL);//获取程序结束的时刻，两个时刻作差即可获得运行时间
    printf("second: %d s\n",tv2.tv_sec - tv1.tv_sec);  //秒
    printf("millisecond: %d ms\n", tv2.tv_sec*1000 + tv2.tv_usec/1000 - (tv1.tv_sec*1000 + tv1.tv_usec/1000));  //毫秒
    printf("microsecond: %d us\n", tv2.tv_sec*1000000 + tv2.tv_usec - (tv1.tv_sec*1000000 + tv1.tv_usec)); //微秒
	finish = clock();
    
	time2 = (double)(finish-start);
	//数字签名验证阶段
    
	start = clock();
    
	sign = DSA_Verify(&h2, h, S, M, id, P1, P2, P_pub_s);
	finish = clock();
     	
	time3 = (double)(finish-start);
	printf("\n********************************************\n");
	printf("*********SM9 数字签名算法实例演示*********** \n");
	printf("********************************************\n");
	printf("***********************\n");
	printf("****1、密钥生成阶段****\n");
	printf("***********************\n");
	printf("G1生成元P1 = \n");
	P_toString(P1,HEX);
	printf("G2生成元P2 = \n");
	P2_toString(P2,HEX);
	printf("签名主私钥ks = %s\n",Put(ks,HEX));
	printf("签名主公钥 P_pub_s = [ks]P2 = \n");
	P2_toString(P_pub_s,HEX);
	printf("实体A的标识IDA: %s\n",id);
	printf("签名私钥dsA = \n");
	P_toString(dsA,HEX);
	printf("\n***********************\n");
	printf("****2、数字签名阶段****\n");
	printf("***********************\n");
	printf("待签名的消息M: %s\n",M);
	printf("消息M的签名为（h,S）: \n");
	printf("h = %s\n",Put(h,HEX));
	printf("S = \n");
	P_toString(S,HEX);
	printf("\n***************************\n");
	printf("****3、数字签名验证阶段****\n");
	printf("***************************\n");
	printf("h2 = %s\n",Put(h2,HEX));
	if(sign)
		printf("h2 = h, 签名验证能过！\n");
	else
		printf("h2 != h, 签名验证失败！\n");

	printf("\nSM9 数字签名密钥生成时间：%f ms\n",time1);
	printf("SM9 数字签名时间：%f ms\n",time2);
	printf("SM9 数字签名验证时间：%f ms\n",time3);
}

/*
   dsA:生成的么钥
   ks:主私钥
   ID:身份ID字符串
   P1：群G1的生成元

*/
void parallel_DSA_Demo()  //实际并行测试函数
{
	CBigInt a,b,c,d,e,f,ks,h,h2;
	BNField2 b1,b2;
	BNPoint2 P2,P_pub_s;
	BNPoint P1,dsA,S;

	BYTE id[]="Alice";
	BYTE M[] = "Chinese IBS standard";
	int sign;
	clock_t start,finish;
	double time1,time2,time3;

	Get(&a,"93DE051D62BF718FF5ED0704487D01D6E1E4086909DC3280E8C4E4817C66DDDD",HEX);
	Get(&b,"21FE8DDA4F21E607631065125C395BBC1C1C00CBFA6024350C464CD70A3EA616",HEX);
	Get(&c,"85AEF3D078640C98597B6027B441A01FF1DD2C190F5E93C454806C11D8806141",HEX);
	Get(&d,"3722755292130B08D2AAB97FD34EC120EE265948D19C17ABF9B7213BAF82D65B",HEX);
	Get(&e,"17509B092E845C1266BA0D262CBEE6ED0736A96FA347C8BD856DC76B84EBEB96",HEX);
	Get(&f,"A7CF28D519BE3DA65F3170153D278FF247EFBA98A71A08116215BBA5C999A7C7",HEX);

    P_construct_xy(&P1,a,b);
	F2_construct(&b1,d,c);
	F2_construct(&b2,f,e);    
    P2_construct_xy(&P2,b1,b2);
    
	//密钥生成阶段
	Get(&ks,"0130E78459D78545CB54C587E02CF480CE0B66340F319F348A1D5B1F2DC5F4",HEX);
	P2_multiply(&P_pub_s,P2,ks);
	P2_normorlize(&P_pub_s,P_pub_s);
    
	start = clock();
	DSA_Keygen(&dsA,ks,id,P1);
	finish = clock();
    
	time1 = (double)(finish-start);
	P_normorlize(&dsA,dsA);
    //g预计算阶段
    
    geP1Ppubs_assign(&SIGNPRE,P_pub_s,P1);

    //数字签名阶段
    
	start = clock();
    int count = 32; //一共需要处理的数量
    const int num=32;//一次性处理的数量  count为num的整数倍


    struct timeval tv1,tv2;
	long time_begin,time_end;
    gettimeofday(&tv1,NULL);//获取开始时间
    printf("sign %d time... \n", num);
    //printf("second: %d\n", tv1.tv_sec);  //秒
    printf("签名%d次用时: %d\n", num, tv1.tv_sec*1000 + tv1.tv_usec/1000);  //毫秒
    //printf("microsecond: %d\n", tv1.tv_sec*1000000 + tv1.tv_usec); //微秒
	CBigInt *para_h =  (CBigInt *)malloc(num*sizeof(CBigInt));
	BNPoint *para_S = (BNPoint *)malloc(num *sizeof(BNPoint));
    
    parallel_DSA_Sign_v2(para_h, para_S, M, P1, P_pub_s,dsA,num);	

    gettimeofday(&tv2,NULL);//获取程序结束的时刻，两个时刻作差即可获得运行时间
    //printf("second: %d s\n",tv2.tv_sec - tv1.tv_sec);  //秒
    printf("验签%d次用时: %d\n", num, tv2.tv_sec*1000 + tv2.tv_usec/1000 - (tv1.tv_sec*1000 + tv1.tv_usec/1000));  //毫秒
    //printf("microsecond: %d us\n", tv2.tv_sec*1000000 + tv2.tv_usec - (tv1.tv_sec*1000000 + tv1.tv_usec)); //微秒
	finish = clock();
    
	time2 = (double)(finish-start);
	//数字签名验证阶段
    start = clock();
    CBigInt *para_h2 =  (CBigInt *)malloc(num*sizeof(CBigInt));
	printf("verify %d time... \n", num);
    gettimeofday(&tv1,NULL);//获取开始时间
	sign = parallel_DSA_Verify(para_h2, para_h, para_S, M, id, P1, P2, P_pub_s,num);
    gettimeofday(&tv2,NULL);//获取程序结束的时刻，两个时刻作差即可获得运行时间
    printf("millisecond: %d ms\n", tv2.tv_sec*1000 + tv2.tv_usec/1000 - (tv1.tv_sec*1000 + tv1.tv_usec/1000));  //毫秒
	finish = clock();
     	
	time3 = (double)(finish-start);
	printf("\n********************************************\n");
	printf("*********SM9 数字签名算法实例演示*********** \n");
	printf("********************************************\n");
	printf("***********************\n");
	printf("****1、密钥生成阶段****\n");
	printf("***********************\n");
	printf("G1生成元P1 = \n");
	P_toString(P1,HEX);
	printf("G2生成元P2 = \n");
	P2_toString(P2,HEX);
	printf("签名主私钥ks = %s\n",Put(ks,HEX));
	printf("签名主公钥 P_pub_s = [ks]P2 = \n");
	P2_toString(P_pub_s,HEX);
	printf("实体A的标识IDA: %s\n",id);
	printf("签名私钥dsA = \n");
	P_toString(dsA,HEX);
	printf("\n***********************\n");
	printf("****2、数字签名阶段****\n");
	printf("***********************\n");
	printf("待签名的消息M: %s\n",M);
	printf("消息M的签名为（h,S）: \n");
	printf("h = %s\n",Put(para_h[0],HEX));
	printf("S = \n");
	P_toString(para_S[0],HEX);
	printf("\n***************************\n");
	printf("****3、数字签名验证阶段****\n");
	printf("***************************\n");
	printf("h2 = %s\n",Put(para_h2[0],HEX));
	if(sign)
		printf("h2 = h, 签名验证能过！\n");
	else
		printf("h2 != h, 签名验证失败！\n");

	printf("\nSM9 数字签名密钥生成时间：%f ms\n",time1);
	printf("SM9 数字签名时间：%f ms\n",time2);
	printf("SM9 数字签名验证时间：%f ms\n",time3);
    free(para_h);
    free(para_S);
    //free(para_h2); //容易引起报错 bug待解决
}

/*
* 签名函数parallel版本
*
*/
void parallel_DSA_Sign_v2(CBigInt *hh, BNPoint *SS, BYTE *M, BNPoint P1, BNPoint2 P_pub, BNPoint dsA, const int num)
{
	BNField12 g[num],w[num];
	CBigInt r[num],l[num];
	unsigned int len1,len2;
	BYTE *msg;
    //printf("File: %s Func:%s Line: %d\n",__FILE__ ,__func__,__LINE__); 
    //F12_assign(&g,SIGNPRE.geP1Ppubs);//可以并行
    BNField12 WW;
	for(int i=0;i<num;i++)
	{
		//Pairing_opt(&g[i],P_pub,P1);
		F12_assign(&(g[i]),SIGNPRE.geP1Ppubs);
		Get(&r[i],"033C8616B06704813203DFD00965022ED15975C662337AED648835DC4B1CBE",HEX);
		F12_exp(&w[i],g[i],r[i]);
	}
    F12_exp(&WW,g[0],r[0]);
    

    //printf("File: %s Func:%s Line: %d\n",__FILE__ ,__func__,__LINE__); 
	//F12_exp 中BNField12*变量&w[i]在使用数组的时候，定义para_w
    //F12_exp(&w[i],g[i],r[i]);

    int nNUM = num;
    len1 = strlen((const char*)M);;
    len2 = len1+384;
    msg = (BYTE*)malloc(len2);//
    memcpy(msg,M,len1);
    F12toByte(&msg[len1],WW);
    for(int i=0;i<32;i++){

        Hash_2(&(hh[i]), msg, len2, BN.n);
        //printf("original hh[%d] = %s\n",i , Put(hh[i],HEX));
    }
    
	//Hash_2(&(hh[2]), msg, len2, BN.n);
    //printf("File: %s Func:%s Line: %d\n",__FILE__ ,__func__,__LINE__); 
    //printf("original hh = %s\n", Put(hh[0],HEX));
    
    //Put_para((CBigInt *)hh,HEX,nNUM);
    

    //printf("File: %s Func:%s Line: %d\n",__FILE__ ,__func__,__LINE__); 
    
    CBigInt para_l[32];

	//先测试一下这个函数
	//printf("File: %s Func:%s Line: %d\n",__FILE__ ,__func__,__LINE__); 
    for(int i=0;i<num;i++){
        CBigInt_substract_modN(&(para_l[i]),r[i],hh[i]);//可以并行
        //printf("original hh[%d] = %s\n",i , Put(para_l[i],HEX));
    }
	
	//printf("File: %s Func:%s Line: %d\n",__FILE__ ,__func__,__LINE__); 

	for(int i=0;i<num;i++)
	{
		
		//CBigInt_substract_modN(&l[i],r[i],*h[i]);//测试parallel_CBigInt_substract_modN的时候将这一行注释掉
		//printf("here=%d \n",i);
		P_multiply(&(SS[i]),dsA,para_l[i]);//可以
		//printf("end=%d \n",i);
		P_normorlize(&(SS[i]),SS[i]);//可以
		//printf("end=%d \n",i);
		//free(msg[i]);
		//printf("end=%d \n",i);
	}
    //printf("File: %s Func:%s Line: %d\n",__FILE__ ,__func__,__LINE__); 
    free(msg);
}

void DSA_Keygen(BNPoint *dsA,CBigInt ks, BYTE *ID,BNPoint P1)
{
	int len;
	BYTE *msg;
	BYTE hid = 0x01;
	CBigInt t1,t2;
	len = strlen((const char*)ID);
	len +=1;
	msg = (BYTE*)malloc(len);
	memcpy(msg,ID,len-1);
	msg[len-1] = hid;
	Hash_1(&t1, msg, len, BN.n);
	Add_Big_Big(&t1,t1,ks);
	while(Cmp(t1,BN.ZERO)==0)
	{
		//ks = rand();
		Hash_1(&t1, msg, len, BN.n);
	    Add_Big_Big(&t1,t1,ks);
	}
	Inv(&t2,t1,BN.n);
	Mul_Big_Big(&t2,t2,ks);
	if(Cmp(t2,BN.n)>=0)
		Mod_Big_Big(&t2,t2,BN.n);
	P_multiply(dsA,P1,t2);
	free(msg);
}
/*
 h,S:生成的数字签名
 M：待签名的明文信息
 P1：公共参数
 P_pub:公钥
 dsA:签名私钥
*/
void DSA_Sign(CBigInt *h, BNPoint *S, BYTE *M, BNPoint P1, BNPoint2 P_pub, BNPoint dsA)
{
	BNField12 g,w;
	CBigInt r,l;
	unsigned int len1,len2;
	BYTE *msg;
	Pairing_opt(&g,P_pub,P1);
    //F12_assign(&g,SIGNPRE.geP1Ppubs);//可以并行
	Get(&r,"033C8616B06704813203DFD00965022ED15975C662337AED648835DC4B1CBE",HEX);  //r=rand();
	//printf("r = %s\n",Put(r,HEX));
	F12_exp(&w,g,r);
	//F12_toString(g,HEX);
	//F12_toString(w,HEX);
	len1 = strlen((const char*)M);
	len2 = len1 + 384;  // 一个12次扩域元素需要 32*12 = 384 个字节
	msg = (BYTE*)malloc(len2);
	memcpy(msg,M,len1);
	F12toByte(&msg[len1],w);
	Hash_2(h, msg, len2, BN.n);
	CBigInt_substract_modN(&l,r,*h);
	P_multiply(S,dsA,l);
	P_normorlize(S,*S);
	free(msg);
    
}

int DSA_Verify(CBigInt *h2, CBigInt h, BNPoint S, BYTE *M, BYTE *ID,BNPoint P1, BNPoint2 P2, BNPoint2 P_pub)
{
	BNField12 g,t,u,w;
	BYTE *msg1,*msg2;
	BYTE hid = 0x01;
	int len1,len2;
	CBigInt h1;
	BNPoint2 P;

	if( Cmp(h,BN.n)>=0 || Cmp(h,BN.ONE)<=0)
		return 0;
	Pairing_opt(&g,P_pub,P1);
	F12_exp(&t,g,h);
	len1 = strlen((const char*)ID);
	len1 +=1;
	msg1 = (BYTE*)malloc(len1);
	memcpy(msg1,ID,len1-1);
	msg1[len1-1] = hid;
	Hash_1(&h1, msg1, len1, BN.n);
	P2_multiply(&P,P2,h1);
	P2_add(&P,P,P_pub);
	Pairing_opt(&u,P,S);
	F12_multiply(&w,u,t);

	len1 = strlen((const char*)M);
	len2 = len1 + 384;  // 一个12次扩域元素需要 32*12 = 384 个字节
	msg2 = (BYTE*)malloc(len2);
	memcpy(msg2,M,len1);
	F12toByte(&msg2[len1],w);
	Hash_2(h2, msg2, len2, BN.n);
	
	free(msg1);
	free(msg2);
	return Cmp(*h2,h)==0 ? 1 : 0;
}

int parallel_DSA_Verify(CBigInt *h2h2, CBigInt *hh, BNPoint *SS, BYTE *M, BYTE *ID,BNPoint P1, BNPoint2 P2, BNPoint2 P_pub, const int num)
{
	
    BNField12 g[num],t[num],u[num],w[num];
	BYTE *msg1,*msg2;
	BYTE hid = 0x01;
	int len1,len2;
	CBigInt h1[num];
	BNPoint2 P;
    
    if(Cmp(hh[0],BN.n)>=0||Cmp(hh[0],BN.ONE)<=0){
        return 0;
    } //假设verify的参数都一直，否侧要改底层的cmp_para代码
  
    for(int i=0;i<num;i++)
	{
		//Pairing_opt(&g,P_pub,P1); //从初始化参数中取出来
		F12_assign(&(g[i]),SIGNPRE.geP1Ppubs);
		F12_exp(&t[i],g[i],hh[i]);
		//F12_exp(&w[i],g[i],r[i]);
	}
	


	len1 = strlen((const char*)ID);
	len1 +=1;
	msg1 = (BYTE*)malloc(len1);
	memcpy(msg1,ID,len1-1);
	msg1[len1-1] = hid;
    
    for(int i=0;i<32;i++){

        Hash_1(&(h1[i]), msg1, len2, BN.n);
        //printf("original hh[%d] = %s\n",i , Put(h1[i],HEX));

    }
	//Hash_1(&h1, msg1, len1, BN.n);
    
	P2_multiply(&P,P2,h1[0]);
   
	P2_add(&P,P,P_pub);
    
    for(int i=0;i<32;i++){
        Pairing_opt(&(u[i]),P,SS[i]);
        F12_multiply(&(w[i]),u[i],t[i]);
    }


	len1 = strlen((const char*)M);
	len2 = len1 + 384;  // 一个12次扩域元素需要 32*12 = 384 个字节
	msg2 = (BYTE*)malloc(len2);
	memcpy(msg2,M,len1);
	F12toByte(&msg2[len1],w[0]);
    int ret = 1;
    for(int i=0;i<32;i++){
        Hash_2(&(h2h2[i]), msg2, len2, BN.n);
        //printf("original h2h2[%d] = %s\n",i , Put(h2h2[i],HEX));
        if(Cmp(h2h2[i],hh[i]) ==0){
            ret = 0;
            break;
        }
    }
    free(msg1);
	free(msg2);
	return ret;
}





