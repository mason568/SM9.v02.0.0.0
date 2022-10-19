
#include <stdio.h>
#include <time.h>
#include <sys/time.h>
#include "square063.cuh"
int main(){
  int a = -1;
  squaretest();
  printf("CPU main... a=%d\r",a);
  return 0;
}