#ifndef _SM9DSA_H_
#define _SM9DSA_H_
#include "utility.h"
#include <time.h>
#include <sys/time.h>

struct SM9DSAParams
{
    //一次签名可能要用到的参数

    //预计算结果
    BNField12 geP1Ppubs; // g = e(P_1,P_pusbs)

}SIGNPRE;

void geP1Ppubs_assign(struct SM9DSAParams *signpre, BNPoint2 P_pub, BNPoint P1);

void DSA_Demo();
void parallel_DSA_Demo();

void DSA_Keygen(BNPoint *dsA,CBigInt ks, BYTE *ID,BNPoint P1);

void DSA_Sign(CBigInt *h, BNPoint *S, BYTE *M,BNPoint P1, BNPoint2 P_pub, BNPoint dsA);
void parallel_DSA_Sign(CBigInt *h[], BNPoint *S[], BYTE *M, BNPoint P1, BNPoint2 P_pub, BNPoint dsA,const int num);

int DSA_Verify(CBigInt *h2, CBigInt h, BNPoint S, BYTE *M, BYTE *ID,BNPoint P1, BNPoint2 P2, BNPoint2 P_pub);

void parallel_DSA_Sign_v2(CBigInt *hh, BNPoint *SS, BYTE *M, BNPoint P1, BNPoint2 P_pub, BNPoint dsA,const int num);
int parallel_DSA_Verify(CBigInt *h2h2, CBigInt *hh, BNPoint *SS, BYTE *MM, BYTE *ID,BNPoint P1, BNPoint2 P2, BNPoint2 P_pub, const int num);
#endif