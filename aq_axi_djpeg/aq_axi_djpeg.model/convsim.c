/*
* Copyright (C)2005-2014 H.Ishihara
*
* License: The Open Software License 3.0
* License URI: http://www.opensource.org/licenses/OSL-3.0
*
* For further information please contact.
*	http://www.aquaxis.com/
*	info(at)aquaxis.com or hidemi(at)sweetcafe.jp
*/
//////////////////////////////////////////////////////////////////////////////
#include <stdio.h>
#include <stdlib.h>

typedef unsigned short WORD;
typedef unsigned int DWORD;
typedef int LONG;

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

//////////////////////////////////////////////////////////////////////////////
// メイン関数
//////////////////////////////////////////////////////////////////////////////
int main(int argc, char *argv[])
{
  unsigned char buff[4];
  char data[256];
  FILE *rfp,*wfp;

  unsigned long width;
  unsigned long height;
  unsigned long bitdata;
  unsigned char tbuff[4];
  BITMAPINFOHEADER lpBi;

  unsigned char *image;
  unsigned int i;

  if((rfp = fopen(argv[1],"rb")) == NULL){
    perror(0);
    exit(0);
  }

  if((wfp = fopen(argv[2],"wb")) == NULL){
    perror(0);
    exit(0);
  }
 

  fgets(data,256,rfp);
  width = (unsigned int)strtol(data,NULL,10);
  fgets(data,256,rfp);
  height = (unsigned int)strtol(data,NULL,10);

  image = (unsigned char *)malloc(height*width*3);

  // ファイルヘッダの設定
  tbuff[0] = 'B';
  tbuff[1] = 'M';
  fwrite(tbuff,2,1,wfp);
  tbuff[3] = ((14 +40 +width * height * 3) >> 24) & 0xff;
  tbuff[2] = ((14 +40 +width * height * 3) >> 16) & 0xff;
  tbuff[1] = ((14 +40 +width * height * 3) >>  8) & 0xff;
  tbuff[0] = ((14 +40 +width * height * 3) >>  0) & 0xff;
  fwrite(tbuff,4,1,wfp);
  tbuff[1] = 0;
  tbuff[0] = 0;
  fwrite(tbuff,2,1,wfp);
  fwrite(tbuff,2,1,wfp);
  tbuff[3] = 0;
  tbuff[2] = 0;
  tbuff[1] = 0;
  tbuff[0] = 54;
  fwrite(tbuff,4,1,wfp);

  // インフォメーションの設定
  lpBi.biSize            = 40;
  lpBi.biWidth           = width;
  lpBi.biHeight          = height;
  lpBi.biPlanes          = 1;
  lpBi.biBitCount        = 3*8;
  lpBi.biCompression     = 0;
  lpBi.biSizeImage       = width*height*3;
  lpBi.biXPelsPerMeter   = 300;
  lpBi.biYPelsPerMeter   = 300;
  lpBi.biClrUsed         = 0;
  lpBi.biClrImportant    = 0;
  fwrite(&lpBi,1,40,wfp);

  i = 0;
  while(!feof(rfp)){
    if(i>=width*height) break;
    fgets(data,256,rfp);
    bitdata=strtol(data,NULL,16);
    image[((height-i/width-1)*width*3)+(i%width)*3+0] = (bitdata >>  0) & 0xff;
    image[((height-i/width-1)*width*3)+(i%width)*3+1] = (bitdata >>  8) & 0xff;
    image[((height-i/width-1)*width*3)+(i%width)*3+2] = (bitdata >> 16) & 0xff;
    i++;
  }
  fwrite(image,1,width*height*3,wfp);
  fclose(rfp);
  fclose(wfp);
  free(image);

  return 0;
}
