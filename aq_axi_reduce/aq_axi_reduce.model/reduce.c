//////////////////////////////////////////////////////////////////////////////
// 平均画素法による縮小
// 2006年 2月21日 V1.0 
// All Rights Reserved, Copyright (c) Hidemi Ishihara
//////////////////////////////////////////////////////////////////////////////
//
// 縮小したいBitmap(元画像)を入力すると縮小したBitmapを出力します。
// 
// % gcc -o reduce reduce.c
// % reduce 元画像ファイル名　縮小出力ファイル名 縮小後のXサイズ 縮小後のYサイズ
//////////////////////////////////////////////////////////////////////////////
#include <stdio.h>
#include <stdlib.h>

typedef unsigned short WORD;
typedef unsigned int DWORD;
typedef int LONG;

typedef struct tagBITMAPFILEHEADER {
  WORD    bfType;
  DWORD   bfSize;
  WORD    bfReserved1;
  WORD    bfReserved2;
  DWORD   bfOffBits;
} BITMAPFILEHEADER, *PBITMAPFILEHEADER;

typedef struct tagBITMAPINFOHEADER{
  DWORD  biSize;
  LONG   biWidth;
  LONG   biHeight;
  WORD   biPlanes;
  WORD   biBitCount;
  DWORD  biCompression;
  DWORD  biSizeImage;
  LONG   biXPelsPerMeter;
  LONG   biYPelsPerMeter;
  DWORD  biClrUsed;
  DWORD  biClrImportant;
} BITMAPINFOHEADER, *PBITMAPINFOHEADER;

unsigned int xl,yl,xs,ys,bc;
unsigned char *buffin, *buffin2, *buffout, *buffout2;

//////////////////////////////////////////////////////////////////////////////
// Bitmapを出力する
// file: ファイル名
// x,y:  画像のサイズ
// b:    バイトカウント(1ドット辺りのバイト数)
//////////////////////////////////////////////////////////////////////////////
void BmpSave(char *file,unsigned char *buff,
	     unsigned int x,unsigned int y,unsigned int b){
  BITMAPFILEHEADER lpBf;
  BITMAPINFOHEADER lpBi;
  unsigned char tbuff[4];
  FILE *fp;
  unsigned char str;
  int i,k;

  if((fp = fopen(file,"wb")) == NULL){
    perror(0);
    exit(0);
  }

  // ファイルヘッダの設定
  tbuff[0] = 'B';
  tbuff[1] = 'M';
  fwrite(tbuff,2,1,fp);
  tbuff[3] = ((14 +40 +x *y *b) >> 24) & 0xff;
  tbuff[2] = ((14 +40 +x *y *b) >> 16) & 0xff;
  tbuff[1] = ((14 +40 +x *y *b) >>  8) & 0xff;
  tbuff[0] = ((14 +40 +x *y *b) >>  0) & 0xff;
  fwrite(tbuff,4,1,fp);
  tbuff[1] = 0;
  tbuff[0] = 0;
  fwrite(tbuff,2,1,fp);
  fwrite(tbuff,2,1,fp);
  tbuff[3] = 0;
  tbuff[2] = 0;
  tbuff[1] = 0;
  tbuff[0] = 54;
  fwrite(tbuff,4,1,fp);

  // インフォメーションの設定
  lpBi.biSize            = 40;
  lpBi.biWidth           = x;
  lpBi.biHeight          = y;
  lpBi.biPlanes          = 1;
  lpBi.biBitCount        = b*8;
  lpBi.biCompression     = 0;
  lpBi.biSizeImage       = x*y*b;
  lpBi.biXPelsPerMeter   = 300;
  lpBi.biYPelsPerMeter   = 300;
  lpBi.biClrUsed         = 0;
  lpBi.biClrImportant    = 0;
  fwrite(&lpBi,1,40,fp);

  // 上下反転
  /*
  for(k=0;k<y/2;k++){
    for(i=0;i<x*bc;i++){
      str = buff[k*x*bc+i];
      buff[k*x*bc+i] = buff[((y-1)*x*bc -k*x*bc) +i];
      buff[((y-1)*x*bc-k*x*bc) +i] = str;
    }
  }
  */

  fwrite(buff,1,x*y*b,fp);

  fclose(fp);
}

void BmpRead(char *file){
  BITMAPFILEHEADER lpBf;
  BITMAPINFOHEADER lpBi;
  FILE *fp_in;

  if((fp_in = fopen(file,"rb")) == NULL){
    perror(0);
    exit(0);
  }

  fread(&lpBf,14,1,fp_in);
  fread(&lpBi,40,1,fp_in);

  xl = lpBi.biWidth;
  yl = lpBi.biHeight;
  bc = lpBi.biBitCount /8;

  fseek(fp_in, lpBi.biSize + 14, SEEK_SET);

  printf("元画像サイズ：X,Y = %d,%d(%d)\n",xl,yl,lpBi.biBitCount);
  buffin = (unsigned char *)malloc(xl*yl*bc);
  fread(buffin,1,xl*yl*bc,fp_in);
  fclose(fp_in);
}

void Reduce(unsigned char *buffin,unsigned char *buffout,
	    unsigned int xl,unsigned int yl,
	    unsigned int xs,unsigned int ys,
	    unsigned int bc){

  unsigned int z;
  unsigned int xx,xo;
  unsigned int yy,yo;

  // 最大公約数を求める
  xo = xl;
  xx = xs;
  while(1){
    z = xo % xx;
    if(z == 0) break;
    xo = xx;
    xx = z;
  }

  yo = yl;
  yy = ys;
  while(1){
    z = yo % yy;
    if(z == 0) break;
    yo = yy;
    yy = z;
  }
  printf("最大公約数：X,Y = %d,%d\n",xx,yy);

  // 最小公倍数を求める
  unsigned int xk = (xl * xs) / xx;
  unsigned int yk = (yl * ys) / yy;
  printf("最小公倍数：X,Y = %d,%d\n",xk,yk);

  // 元画像の拡大率
  unsigned int xa = xk / xl;
  unsigned int ya = yk / yl;
  printf("元画像の拡大率：X,Y = %d,%d\n",xa,ya);
  
  // 変換後の拡大率
  unsigned int xb = xk / xs;
  unsigned int yb = yk / ys;
  printf("変換後の拡大率：X,Y = %d,%d\n",xb,yb);

  unsigned int k,l,m;
  unsigned int xg; // X方向の残り
  unsigned int xp; // 縮小後のX位置
  unsigned int xz; // X方向バッファ
  unsigned int yg; // Y方向の残り
  unsigned int yp; // 縮小後のY位置
  unsigned int *yz; // Y方向バッファ
  unsigned char xd,xe;
  yz = (unsigned int *)malloc(xs*bc+bc);
  for(m=0;m<bc;m++){ // mは色を指します
    yg = yb;
    yp = 0;
    for(l=0;l<yl;l++){ // lはY方向
      xg = xb;
      xp = 0;
      xz = 0;
      for(k=0;k<xl;k++){ // kはX方向
        xd = buffin[l*xl*bc+k*bc+m];
        if(xg <= xa){
          xz += xd * xg;
          xz = xz / xb;
          if(xz > 0xFF) xz = 0xFF;
          xe = xz & 0xFF;
          xz = xd * (xa - xg);
          xg = xb - (xa - xg);
          
          if(yg <= ya){
            yz[xp] += xe * yg;
            yz[xp] = yz[xp] / yb;
            if(yz[xp] > 0xFF) yz[xp] = 0xFF;
            buffout[yp*xs*bc+xp*bc+m] = yz[xp] & 0xFF;
            yz[xp] = xe * (ya - yg);
          }else{
            yz[xp] += xe * ya;
          }
          xp++;
        }else{
          xz += xd * xa;
          xg = xg - xa;
        }
      }
      if(yg <= ya){
        yg = yb - (ya - yg);
        yp++;
      }else{
        yg = yg - ya;
      }
    }
  }
  //free(yz);
}

void FreqConv(unsigned char *buffin,unsigned char *buffout,int x,int y){
  int m,n,a;

  memcpy(buffout,buffin,x*y*bc);
  for(n=1;n<y-1;n++){
    for(m=1;m<x-1;m++){
      for(a=0;a<bc;a++){
      buffout[n*x*bc+m*bc+a] = 
	(((buffin[(n-1)*x*bc+(m-1)*bc+a] *0.5 + 
	   buffin[(n-1)*x*bc+(m  )*bc+a] *1.0+ 
	   buffin[(n-1)*x*bc+(m+1)*bc+a] *0.5) /2) *0.5 + 
	 ((buffin[(n  )*x*bc+(m-1)*bc+a] *0.5+ 
	   buffin[(n  )*x*bc+(m  )*bc+a] *1.0+ 
	   buffin[(n  )*x*bc+(m+1)*bc+a] *0.5) /2) *1.0+ 
	 ((buffin[(n+1)*x*bc+(m-1)*bc+a] *0.5+ 
	   buffin[(n+1)*x*bc+(m  )*bc+a] *1.0+ 
	   buffin[(n+1)*x*bc+(m+1)*bc+a] *0.5) /2) *0.5) /2;
      }
    }
  }
}

int main(int argc, char* argv[])
{
  unsigned char tbuff[4];

  BITMAPFILEHEADER lpBf;
  BITMAPINFOHEADER lpBi;

  FILE *fp_in, *fp_out;

  xs = atoi(argv[3]);
  ys = atoi(argv[4]);

  BmpRead(argv[1]);
  buffout = (unsigned char *)malloc(xs*ys*bc);
  buffout2 = (unsigned char *)malloc(xs*ys*bc);
  buffin2 = (unsigned char *)malloc(xl*yl*bc);

  FreqConv(buffin,buffin2,xl,yl);
  Reduce(buffin2,buffout,xl,yl,xs,ys,bc);
  FreqConv(buffout,buffout2,xs,ys);
  BmpSave(argv[2],buffout,xs,ys,bc);

  free(buffout);
  free(buffin);

  return 0;
}
