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

//////////////////////////////////////////////////////////////////////////////
// ÉÅÉCÉìä÷êî
//////////////////////////////////////////////////////////////////////////////
int main(int argc, char *argv[])
{
  unsigned char buff[4];
  char data[256];
  FILE *rfp,*wfp;

  if((rfp = fopen(argv[1],"rb")) == NULL){
    perror(0);
    exit(0);
  }
  if((wfp = fopen(argv[2],"wb")) == NULL){
    perror(0);
    exit(0);
  }
  while(!feof(rfp)){
    fread(buff,1,4,rfp);
    sprintf(data,"%02X%02X%02X%02X\n",buff[3],buff[2],buff[1],buff[0]);
    fwrite(data,1,9,wfp);
  }
  fclose(rfp);
  fclose(wfp);

  return 0;
}
