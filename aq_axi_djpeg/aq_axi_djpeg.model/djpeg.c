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
// JPEGデコード
// 2005年10月26日 V1.0 
// All Rights Reserved, Copyright (c) Hidemi Ishihara
//////////////////////////////////////////////////////////////////////////////
//
// JPEGを入力するとBitmapを出力します。
// 
// % gcc -o djpeg fjpeg.c
// % djpeg 入力ファイル名　出力ファイル名
//////////////////////////////////////////////////////////////////////////////
#include <stdio.h>
#include <stdlib.h>

#define log_printf(...) 

unsigned int BuffIndex;	// JPEGデータの位置
unsigned int BuffSize;	// JPEGデータの大きさ
unsigned int BuffX;		// 画像の横サイズ
unsigned int BuffY;		// 画像の縦サイズ
unsigned int BuffBlockX; // MCUの横個数
unsigned int BuffBlockY; // MCUの縦個数
unsigned char *Buff;		// 伸長したデータを入れるバッファ

unsigned char	TableDQT[4][64];	// 量子化テーブル
unsigned short TableDHT[4][162]; // ハフマンテーブル

unsigned short TableHT[4][16];	// ハフマンスタートテーブル
unsigned char	TableHN[4][16];	// ハフマンスタート番号

unsigned char BitCount = 0;	// 圧縮データの読み込み位置
unsigned int LineData;		// 伸長に使うデータ
unsigned int NextData;		// 伸長に使うデータ

unsigned int PreData[3];		// DC成分用の貯めバッファ

unsigned char CompCount;		// コンポーネント数
unsigned char CompNum[4];	// コンポーネント番号(未使用)
unsigned char CompSample[4];	// コンポーネント
unsigned char CompDQT[4];	// コンポーネントのDQTテーブル番号
unsigned char CompDHT[4];	// コンポーネントのDHTテーブル番号
unsigned char CompSampleX, CompSampleY;

// ジグザグテーブル
int zigzag_table[]={
	 0, 1, 8, 16,9, 2, 3,10,
	17,24,32,25,18,11, 4, 5,
	12,19,26,33,40,48,41,34,
	27,20,13, 6, 7,14,21,28,
	35,42,49,56,57,50,43,36,
	29,22,15,23,30,37,44,51,
	58,59,52,45,38,31,39,46,
	53,60,61,54,47,55,62,63,
	0
};

typedef unsigned short WORD;
//typedef unsigned long DWORD;
//typedef long LONG;
typedef unsigned int DWORD;
typedef int LONG;

typedef struct tagBITMAPFILEHEADER {
	WORD	bfType;
	DWORD	bfSize;
	WORD	bfReserved1;
	WORD	bfReserved2;
	DWORD	bfOffBits;
} BITMAPFILEHEADER, *PBITMAPFILEHEADER;

typedef struct tagBITMAPINFOHEADER{
	DWORD	biSize;
	LONG	biWidth;
	LONG	biHeight;
	WORD	biPlanes;
	WORD	biBitCount;
	DWORD	biCompression;
	DWORD	biSizeImage;
	LONG	biXPelsPerMeter;
	LONG	biYPelsPerMeter;
	DWORD	biClrUsed;
	DWORD	biClrImportant;
} BITMAPINFOHEADER, *PBITMAPINFOHEADER;

/*
 * Bitmap出力
 * file: ファイル名
 * x,y:  画像のサイズ
 * b:    バイトカウント(1ドット辺りのバイト数)
 */
void BmpSave(unsigned char *file,unsigned char *buff,
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
	tbuff[1] = ((14 +40 +x *y *b) >>	8) & 0xff;
	tbuff[0] = ((14 +40 +x *y *b) >>	0) & 0xff;
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
	lpBi.biSize			= 40;
	lpBi.biWidth			= x;
	lpBi.biHeight			= y;
	lpBi.biPlanes			= 1;
	lpBi.biBitCount		= b*8;
	lpBi.biCompression	 = 0;
	lpBi.biSizeImage		= x*y*b;
	lpBi.biXPelsPerMeter	= 300;
	lpBi.biYPelsPerMeter	= 300;
	lpBi.biClrUsed		 = 0;
	lpBi.biClrImportant	= 0;
	fwrite(&lpBi,1,40,fp);

	// 上下反転
	for(k=0;k<y/2;k++){
		for(i=0;i<x*3;i++){
			str = buff[k*x*3+i];
			buff[k*x*3+i] = buff[((y-1)*x*3 -k*x*3) +i];
			buff[((y-1)*x*3-k*x*3) +i] = str;
		}
	}

	fwrite(buff,1,x*y*b,fp);

	fclose(fp);
}

/*****************************************
 * データ取得部
 *****************************************/

/*
 * 1Byte取得
 */
unsigned char get_byte(unsigned char *buff){
	if(BuffIndex >= BuffSize) return 0;
	return buff[BuffIndex++];
}
/*
 * 2Byte取得
 */
unsigned short get_word(unsigned char *buff){
	unsigned char h,l;
	h = get_byte(buff);
	l = get_byte(buff);
	return (h<<8)|l;
}

/*
 * 4Byte取得(伸張時のみ使用)
 */
unsigned int get_data(unsigned char *buff){
	unsigned char str = 0;
	unsigned int data = 0;
	str = get_byte(buff);
	if(str ==0xff) if(get_byte(buff)== 0x00) str = 0xFF; else str = 0x00;
	data = str;
	str = get_byte(buff);
	if(str ==0xff) if(get_byte(buff)== 0x00) str = 0xFF; else str = 0x00;
	data = (data << 8) | str;
	str = get_byte(buff);
	if(str ==0xff) if(get_byte(buff)== 0x00) str = 0xFF; else str = 0x00;
	data = (data << 8) | str;
	str = get_byte(buff);
	if(str ==0xff) if(get_byte(buff)== 0x00) str = 0xFF; else str = 0x00;
	data = (data << 8) | str;
	//log_printf(" Get Data: %08x\n",data);
	return data;
}

/*
 * ビットデータ取得(伸張時のみ使用)
 */
unsigned int get_bit(unsigned char *buff){
	unsigned int BitData;

	// ビットカウントの位置が32を越えた場合、新たにデータを取得する
	if(BitCount >=32){
		LineData = NextData;
		NextData = get_data(buff);
		BitCount -= 32;
	}
	// Huffmanデコードで使用するデータに置き換える
	if(BitCount >0){
		BitData = (LineData << BitCount) | (NextData >> (32 - BitCount));
	}else{
		BitData = LineData;
	}

	return BitData;
}

/********************
 * マーカー解析
 ********************/
/*
 * APP0処理
 */
void GetAPP0(unsigned char *buff){
	unsigned short data;
	unsigned char str;
	unsigned int i;
	
	data = get_word(buff); // Lp(レングス)
	// APP0は読まなくてもいいので取り合えずレングス分スキップする
	for(i=0;i<data-2;i++){
    str = get_byte(buff);
	}
#if 0
	str = get_byte(buff);		// 識別子(5文字,"JFIF"と[00])
	str = get_byte(buff);
	str = get_byte(buff);
	str = get_byte(buff);
	str = get_byte(buff);
	data = get_word(buff);	// バージョン
	str = get_byte(buff);		// 解像度の単位
	data = get_word(buff);	// 横方向の解像度
	data = get_word(buff);	// 縦方向の解像度
	data = get_word(buff);	// サムネイルの横ピクセル数
	data = get_word(buff);	// サムネイルの縦ピクセル数
	data = get_word(buff);	// サムネイルデータ(ある場合だけ)
#endif
}

/*
 * DQT処理
 */
void GetDQT(unsigned char *buff){
	unsigned short data;
	unsigned char str;
	unsigned int i;
	unsigned int tablenum;

	data = get_word(buff);
	str = get_byte(buff); // テーブル番号
	
	log_printf("*** DQT Table %d\n",str);
	for(i=0;i<64;i++){
    TableDQT[str][i] = get_byte(buff);
    log_printf(" %2d: %2x\n",i,TableDQT[str][i]);
	}
}

/*
 * DHT処理
 */
void GetDHT(unsigned char *buff){
	unsigned short data;
	unsigned char str;
	unsigned int i;
	unsigned char max,count;
	unsigned short ShiftData = 0x8000,HuffmanData =0x0000;
	unsigned int tablenum;

	data = get_word(buff);
	str = get_byte(buff);

	switch(str){
	case 0x00:
		// Y直流成分
		tablenum = 0x00;
		break;
	case 0x10:
		// Y交流成分
		tablenum = 0x01;
		break;
	case 0x01:
		// CbCr直流成分
		tablenum = 0x02;
		break;
	case 0x11:
		// CbCr交流成分
		tablenum = 0x03;
		break;
	}

	log_printf("*** DHT Table/Number %d\n",tablenum);
	// テーブルを作成する
	max = 0;
	for(i=0;i<16;i++){
		count = get_byte(buff);
		TableHT[tablenum][i] = HuffmanData;
		TableHN[tablenum][i] = max;
		log_printf(" %2d: %4x,%2x\n",i,TableHT[tablenum][i],TableHN[tablenum][i]);
		max = max + count;
		while(!(count==0)){
			HuffmanData += ShiftData;
			count--;
		}
		ShiftData = ShiftData >> 1; // 右に1bitシフトする
	}

	log_printf("*** DHT Table %d\n",tablenum);
	for(i=0;i<max;i++){
		TableDHT[tablenum][i] = get_byte(buff);
		log_printf(" %2d: %2x\n",i,TableDHT[tablenum][i]);
	}
}

/*
 * SOF処理
 */
void GetSOF(unsigned char *buff){
	unsigned short data;
	unsigned char str;
	unsigned int i;
	unsigned char count;
	unsigned char num;

	data = get_word(buff);
	str = get_byte(buff);
	BuffY = get_word(buff); // 画像の横サイズ
	BuffX = get_word(buff); // 画像の縦サイズ
	CompCount	= get_byte(buff); // データのコンポーネント数
	log_printf(" CompCount: %d\n", CompCount);
	for(i=0;i<CompCount;i++){
		str = get_byte(buff); // コンポーネント番号
		num = str;
		log_printf(" Comp[%d]: %02X\n", i, str);
		str = get_byte(buff); // サンプリング比率
		CompSample[num] = str;
		log_printf(" Sample[%d]: %02X\n", i, str);
		str = get_byte(buff); // DQTテーブル番号
		CompDQT[num] = str;
		log_printf(" DQT[%d]: %02X\n", i, str);
	}
	
	if(CompCount == 1){
		CompSampleX = 1;
		CompSampleY = 1;
	}else{
		CompSampleX =  CompSample[1]       & 0x0F;
		CompSampleY = (CompSample[1] >> 4) & 0x0F;
	}

	// MCUのサイズを算出する(ひと塊分)
	BuffBlockX = (int)(BuffX /(8 * CompSampleX));
	if(BuffX % (8 * CompSampleX) >0) BuffBlockX++;
	BuffBlockY = (int)(BuffY /(8 * CompSampleY));
	if(BuffY % (8 * CompSampleY) >0) BuffBlockY++;
	Buff = (unsigned char*)malloc(BuffBlockY*(8 * CompSampleY)*BuffBlockX*(8 * CompSampleX)*3);

	log_printf(" size : %d x %d,(%d x %d)\n",BuffX,BuffY,BuffBlockX,BuffBlockY);
}

/*
 * SOS処理
 */
void GetSOS(unsigned char *buff){
	unsigned short data;
	unsigned char str;
	unsigned int i;
	unsigned char count;
	unsigned char num;

	data = get_word(buff);
	count = get_byte(buff);
	for(i=0;i<count;i++){
		str = get_byte(buff);
		num = str;
		log_printf(" CompNum[%d]: %02X\n", i, str);
		str = get_byte(buff);
		CompDHT[num] = str;
		log_printf(" CompDHT[%d]: %02X\n", i, str);
	}
	str = get_byte(buff);
	str = get_byte(buff);
	str = get_byte(buff);
}

/*
 * ハフマンデコード＋逆量子化＋逆ジグザグ
 */
void HuffmanDecode(unsigned char *buff, unsigned char table, int *BlockData){
	unsigned int data;
	unsigned char zero;
	unsigned short code,huffman;
	unsigned char count =0;
	unsigned int BitData;
	unsigned int i;
	unsigned char tabledqt,tabledc,tableac,tablen;
	unsigned char ZeroCount,DataCount;
	int DataCode;

	for(i=0;i<64;i++) BlockData[i] = 0x0; // データのリセット

	// テーブル番号を設定する
	if(table ==0x00){
		tabledqt =0x00;
		tabledc =0x00;
		tableac =0x01;
	}else if(table ==0x01){
		tabledqt =0x01;
		tabledc	=0x02;
		tableac	=0x03;
	}else{
		tabledqt =0x01;
		tabledc	=0x02;
		tableac	=0x03;
	}

	count = 0; // 念のために
	while(count <64){

	BitData = get_bit(buff);
  
	log_printf(" Haffuman BitData(%2d,%2d): %8x\n",table,count,BitData);

	// 使用するテーブルのセレクト
	if(count ==0) tablen = tabledc; else tablen = tableac;
	code = (unsigned short)(BitData >> 16); // コードは16ビット使用する
	// ハフマンコードがどのビット数にいるか割り出す
	for(i=0;i<16;i++) {
		log_printf(" Haff hit(%2d:%2d): %8x,%8x\n",table,i,TableHT[tablen][i],code);
		if(TableHT[tablen][i]>code) break;
	}
	i--;

	code	= (unsigned short)(code >> (15 - i)); // コードの下位を揃える
	huffman = (unsigned short)(TableHT[tablen][i] >> (15 - i));

	log_printf(" PreUse Dht Number(%2d): %8x,%8x,%8x\n",i,code,huffman,TableHN[tablen][i]);

	// ハフマンテーブルの場所を算出する
	code = code - huffman + TableHN[tablen][i];

	log_printf(" Use Dht Number: %8x\n",code);

	ZeroCount = (TableDHT[tablen][code] >> 4) & 0x0F; // ゼロレングスの個数
	DataCount = (TableDHT[tablen][code]) & 0x0F;		// 続くデータのビット長
	log_printf(" Dht Table: %8x,%8x\n",ZeroCount,DataCount);
	// ハフマンコードを抜き、続くデータを取得する
	DataCode	= (BitData << (i + 1)) >> (16 + (16 - DataCount));
	// 先頭ビットが"0"であれば負のデータ、上位ビットに１を立てて、１を足す
	//if(!(DataCode & (1<<(DataCount-1)))) DataCode=DataCode-(1<<DataCount)+1;
	if(!(DataCode & (1<<(DataCount-1))) && DataCount !=0){
		DataCode |= (~0) << DataCount;
		DataCode += 1;
	}

	log_printf(" Use Bit: %d\n",(i + DataCount +1));
	BitCount += (i + DataCount +1); // 使用したビット数を加算する

	if(count ==0){
		// DC成分の場合、データとなる
		if(DataCount ==0) DataCode =0x0; // DataCountが0ならデータは0である
		PreData[table] += DataCode; // DC成分は加算しなければならない
		// 逆量子化＋ジグザグ
		BlockData[zigzag_table[count]] =PreData[table]*TableDQT[tabledqt][count];
		count ++;
	}else{
		if(ZeroCount == 0x0 && DataCount == 0x0){
			// AC成分でEOB符号が来た場合は終了する
			break;
		}else if(ZeroCount ==0xF && DataCount == 0x0){
			// ZRL符号が来た場合、15個のゼロデータとみなす
			count += 15;
		}else{
			count += ZeroCount;
			// 逆量子化＋ジグザグ
			BlockData[zigzag_table[count]] = DataCode * TableDQT[tabledqt][count];
		}
		count ++;
	}
	}
}

const int C1_16 = 4017; // cos( pi/16) x4096
const int C2_16 = 3784; // cos(2pi/16) x4096
const int C3_16 = 3406; // cos(3pi/16) x4096
const int C4_16 = 2896; // cos(4pi/16) x4096
const int C5_16 = 2276; // cos(5pi/16) x4096
const int C6_16 = 1567; // cos(6pi/16) x4096
const int C7_16 = 799;	// cos(7pi/16) x4096

/*
 * iDCT
 */
void DctDecode(int *BlockIn, int *BlockOut){
	int i;
	int s0,s1,s2,s3,s4,s5,s6,s7;
	int t0,t1,t2,t3,t4,t5,t6,t7;

  /* iDCT X方向 */
	log_printf("-----------------------------\n");
	log_printf(" iDCT(In)\n");
	log_printf("-----------------------------\n");
	for(i=0;i<64;i++){
    log_printf("%2d: %8x\n",i,BlockIn[i]);
	}

	for(i=0;i<8;i++) {
		s0 = (BlockIn[0] + BlockIn[4]) * C4_16;
		s1 = (BlockIn[0] - BlockIn[4]) * C4_16;
		s3 = (BlockIn[2] * C2_16) + (BlockIn[6] * C6_16);
		s2 = (BlockIn[2] * C6_16) - (BlockIn[6] * C2_16);
		s7 = (BlockIn[1] * C1_16) + (BlockIn[7] * C7_16);
		s4 = (BlockIn[1] * C7_16) - (BlockIn[7] * C1_16);
		s6 = (BlockIn[5] * C5_16) + (BlockIn[3] * C3_16);
		s5 = (BlockIn[5] * C3_16) - (BlockIn[3] * C5_16);

		log_printf("s0:%8x\n",s0);
		log_printf("s1:%8x\n",s1);
		log_printf("s2:%8x\n",s2);
		log_printf("s3:%8x\n",s3);
		log_printf("s4:%8x\n",s4);
		log_printf("s5:%8x\n",s5);
		log_printf("s6:%8x\n",s6);
		log_printf("s7:%8x\n",s7);

		t0 = s0 + s3;
		t3 = s0 - s3;
		t1 = s1 + s2;
		t2 = s1 - s2;
		t4 = s4 + s5;
		t5 = s4 - s5;
		t7 = s7 + s6;
		t6 = s7 - s6;

		log_printf("t0:%8x\n",t0);
		log_printf("t1:%8x\n",t1);
		log_printf("t2:%8x\n",t2);
		log_printf("t3:%8x\n",t3);
		log_printf("t4:%8x\n",t4);
		log_printf("t5:%8x\n",t5);
		log_printf("t6:%8x\n",t6);
		log_printf("t7:%8x\n",t7);

		s6 = (t5 + t6) * 181 / 256; // 1/sqrt(2)
		s5 = (t6 - t5) * 181 / 256; // 1/sqrt(2)

		log_printf("s5:%8x\n",s5);
		log_printf("s6:%8x\n",s6);

		*BlockIn++ = (t0 + t7) >> 11;
		*BlockIn++ = (t1 + s6) >> 11;
		*BlockIn++ = (t2 + s5) >> 11;
		*BlockIn++ = (t3 + t4) >> 11;
		*BlockIn++ = (t3 - t4) >> 11;
		*BlockIn++ = (t2 - s5) >> 11;
		*BlockIn++ = (t1 - s6) >> 11;
		*BlockIn++ = (t0 - t7) >> 11;
	}

	BlockIn -= 64;

  /* iDCT Y方向 */
	log_printf("-----------------------------\n");
	log_printf(" iDCT(Middle)\n");
	log_printf("-----------------------------\n");
	for(i=0;i<64;i++){
	log_printf("%2d: %8x\n",i,BlockIn[i]);
	}

	for(i=0;i<8;i++){
		s0 = (BlockIn[ 0] + BlockIn[32]) * C4_16;
		s1 = (BlockIn[ 0] - BlockIn[32]) * C4_16;
		s3 = BlockIn[16] * C2_16 + BlockIn[48] * C6_16;
		s2 = BlockIn[16] * C6_16 - BlockIn[48] * C2_16;
		s7 = BlockIn[ 8] * C1_16 + BlockIn[56] * C7_16;
		s4 = BlockIn[ 8] * C7_16 - BlockIn[56] * C1_16;
		s6 = BlockIn[40] * C5_16 + BlockIn[24] * C3_16;
		s5 = BlockIn[40] * C3_16 - BlockIn[24] * C5_16;

		log_printf("s0:%8x\n",s0);
		log_printf("s1:%8x\n",s1);
		log_printf("s2:%8x\n",s2);
		log_printf("s3:%8x\n",s3);
		log_printf("s4:%8x\n",s4);
		log_printf("s5:%8x\n",s5);
		log_printf("s6:%8x\n",s6);
		log_printf("s7:%8x\n",s7);

		t0 = s0 + s3;
		t1 = s1 + s2;
		t2 = s1 - s2;
		t3 = s0 - s3;
		t4 = s4 + s5;
		t5 = s4 - s5;
		t6 = s7 - s6;
		t7 = s6 + s7;

		log_printf("t0:%8x\n",t0);
		log_printf("t1:%8x\n",t1);
		log_printf("t2:%8x\n",t2);
		log_printf("t3:%8x\n",t3);
		log_printf("t4:%8x\n",t4);
		log_printf("t5:%8x\n",t5);
		log_printf("t6:%8x\n",t6);
		log_printf("t7:%8x\n",t7);

		s5 = (t6 - t5) * 181 / 256; // 1/sqrt(2)
		s6 = (t5 + t6) * 181 / 256; // 1/sqrt(2)

		log_printf("s5:%8x\n",s5);
		log_printf("s6:%8x\n",s6);

		BlockOut[ 0] = ((t0 + t7) >> 15);
		BlockOut[56] = ((t0 - t7) >> 15);
		BlockOut[ 8] = ((t1 + s6) >> 15);
		BlockOut[48] = ((t1 - s6) >> 15);
		BlockOut[16] = ((t2 + s5) >> 15);
		BlockOut[40] = ((t2 - s5) >> 15);
		BlockOut[24] = ((t3 + t4) >> 15);
		BlockOut[32] = ((t3 - t4) >> 15);
		
		BlockIn++;
		BlockOut++;
	}
	BlockOut-=8;

	log_printf("-----------------------------\n");
	log_printf(" iDCT(Out)\n");
	log_printf("-----------------------------\n");
	for(i=0;i<8;i++){
    log_printf(" %2d: %04x;\n",i+ 0,BlockOut[i+ 0]&0xFFFF);
    log_printf(" %2d: %04x;\n",i+56,BlockOut[i+56]&0xFFFF);
    log_printf(" %2d: %04x;\n",i+ 8,BlockOut[i+ 8]&0xFFFF);
    log_printf(" %2d: %04x;\n",i+48,BlockOut[i+48]&0xFFFF);
    log_printf(" %2d: %04x;\n",i+16,BlockOut[i+16]&0xFFFF);
    log_printf(" %2d: %04x;\n",i+40,BlockOut[i+40]&0xFFFF);
    log_printf(" %2d: %04x;\n",i+24,BlockOut[i+24]&0xFFFF);
    log_printf(" %2d: %04x;\n",i+32,BlockOut[i+32]&0xFFFF);
	}
}

//////////////////////////////////////////////////////////////////////////////
// 4:1:1のデコード処理
void Decode411(unsigned char *buff, int *BlockY, int *BlockCb, int *BlockCr){
	int BlockHuffman[64];
	int BlockYLT[64];
	int BlockYRT[64];
	int BlockYLB[64];
	int BlockYRB[64];
	int Block[64];
	unsigned int i;
	unsigned int m, n;

	for(n=0;n<CompSampleY;n++){
		for(m=0;m<CompSampleX;m++){
			log_printf("BlockY:%d,%d\n",m,n);
			HuffmanDecode(buff,0x00,BlockHuffman);
			DctDecode(BlockHuffman,Block);
			for(i=0;i<64;i++){
				BlockY[(int)(i/8)*8*CompSampleX+(i%8)+(m*8)+(n*64*CompSampleY)] = Block[i];
			}
		}
	}

	if(CompCount > 1){
		// 青色差
		log_printf("Block:10\n");
		HuffmanDecode(buff,0x01,BlockHuffman);
		DctDecode(BlockHuffman,BlockCb);

		// 赤色差
		log_printf("Block:11\n");
		HuffmanDecode(buff,0x02,BlockHuffman);
		DctDecode(BlockHuffman,BlockCr);
	}
}

/*
 * YUV→RGBに変換
 */
void DecodeYUV(int *y, int *cb, int *cr, unsigned char *rgb){
	int r,g,b;
	int p,i;

	log_printf("----RGB----\n");
	for(i=0;i<((CompCount>1)?256:64);i++){
		p = ((int)(i/32) * 8) + ((int)((i % 16)/2));
		r = 128 + y[i] + ((CompCount>1)?cr[p]*1.402:0);
		r = (r & 0xffffff00) ? (r >> 24) ^ 0xff : r;
		g = 128 + y[i] - ((CompCount>1)?cb[p]*0.34414:0) - ((CompCount>1)?cr[p]*0.71414:0);
		g = (g & 0xffffff00) ? (g >> 24) ^ 0xff : g;
		b = 128 + y[i] + ((CompCount>1)?cb[p]*1.772:0);
		b = (b & 0xffffff00) ? (b >> 24) ^ 0xff : b;
		rgb[i*3+0] = b;
		rgb[i*3+1] = g;
		rgb[i*3+2] = r;
	log_printf("[RGB]%3d: %3x,%3x,%3x = %2x,%2x,%2x\n",i,
			y[i]&0x1FF,cr[p]&0x1FF,cb[p]&0x1FF,
			rgb[i*3+2],rgb[i*3+1],rgb[i*3+0]);
	}
}

//////////////////////////////////////////////////////////////////////////////
// イメージのデコード
void Decode(unsigned char *buff,unsigned char *rgb){
	int BlockY[256];
	int BlockCb[256];
	int BlockCr[256];
	int x,y,i,p;

	for(y=0;y<BuffBlockY;y++){
		for(x=0;x<BuffBlockX;x++){
			Decode411(buff,BlockY,BlockCb,BlockCr);	// 4:1:1のデコード
			DecodeYUV(BlockY,BlockCb,BlockCr,rgb);		// YUV→RGB変換
			for(i=0;i<((CompCount>1)?256:64);i++){
				if((x*(8*CompSampleX)+(i%(8*CompSampleX))<BuffX) && (y*(8*CompSampleY)+i/(8*CompSampleY)<BuffY)){
					p=y*(8*CompSampleY)*BuffX*3+x*(8*CompSampleX)*3+(int)(i/(8*CompSampleY))*BuffX*3+(i%(8*CompSampleX))*3;
					Buff[p+0] = rgb[i*3+0];
					Buff[p+1] = rgb[i*3+1];
					Buff[p+2] = rgb[i*3+2];
			
					log_printf("RGB[%4d,%4d]: %2x,%2x,%2x\n",x*(8*CompSampleX)+(i%(8*CompSampleX)),y*(8*CompSampleY)+i/(8*CompSampleY),rgb[i*3+2],rgb[i*3+1],rgb[i*3+0]);
				}
			}
		}
	}
}

/*
 * デコード
 */
void JpegDecode(unsigned char *buff){
	unsigned short data;
	unsigned int i;
	unsigned int Image =0;
	unsigned char RGB[256*3];
	while(!(BuffIndex >= BuffSize)){
		if(Image ==0){
			data = get_word(buff);
			switch(data){
				case 0xFFD8: // SOI
				log_printf("Header: SOI\n");
				break;
			case 0xFFE0: // APP0
				log_printf("Header: APP0\n");
				GetAPP0(buff);
				break;
			case 0xFFDB: // DQT
				log_printf("Header: DQT\n");
				GetDQT(buff);
				break;
			case 0xFFC4: // DHT
				log_printf("Header: DHT\n");
				GetDHT(buff);
				break;
			case 0xFFC0: // SOF
				log_printf("Header: SOF\n");
				GetSOF(buff);
				break;
			case 0xFFDA: // SOS
				log_printf("Header: SOS\n");
				GetSOS(buff);
				Image = 1;
				// データの準備
				PreData[0] = 0x00;
				PreData[1] = 0x00;
				PreData[2] = 0x00;
				LineData = get_data(buff);
				NextData = get_data(buff);
				BitCount =0;
				break;
			case 0xFFD9: // EOI
				log_printf("Header: EOI\n");
				break;
			default:
				// 判別できないヘッダーは読み飛ばす
				log_printf("Header: other(%X)\n", data);
				if((data & 0xFF00) == 0xFF00 && !(data == 0xFF00)){
					data = get_word(buff);
					for(i=0;i<data-2;i++){
					get_byte(buff);
					}
				}
				break;
			}
		}else{
			// 伸長(SOSが来ている)
			log_printf("/****Image****/\n");
			Decode(buff,RGB);
		}
	}
}

//////////////////////////////////////////////////////////////////////////////
// メイン関数
//////////////////////////////////////////////////////////////////////////////
int main(int argc, char* argv[])
{
	unsigned char *buff;
	FILE *fp;

	// 型のサイズを表示する
	log_printf( " sizeof(char):           %02d\n", sizeof( char ) );
	log_printf( " sizeof(unsigned char):  %02d\n", sizeof( unsigned char ) );
	log_printf( " sizeof(short):          %02d\n", sizeof( short ) );
	log_printf( " sizeof(unsigned short): %02d\n", sizeof( unsigned short ) );
	log_printf( " sizeof(int):            %02d\n", sizeof( int ) );
	log_printf( " sizeof(unsigned int):   %02d\n", sizeof( unsigned int ) );
	log_printf( " sizeof(long):           %02d\n", sizeof( long ) );
	log_printf( " sizeof(unsigned long):  %02d\n", sizeof( unsigned long ) );

	log_printf( " sizeof:                 %02d\n", sizeof( BITMAPFILEHEADER ) );
	log_printf( " sizeof:                 %02d\n", sizeof( BITMAPINFOHEADER ) );

	if((fp = fopen(argv[1], "rb")) == NULL){
		perror(0);
		exit(0);
	}

	// ファイルサイズを取得する
	BuffSize = 0;
	while(!feof(fp)){
		fgetc(fp);
		BuffSize ++;
	}
	BuffSize--;
	rewind(fp);	// ファイルポインタを最初に戻す

	buff = (unsigned char *)malloc(BuffSize);	// バッファを確保する
	fread(buff,1,BuffSize,fp);					// バッファに読み込む
	BuffIndex = 0;
	JpegDecode(buff);								// JPEGデコードする
	log_printf("Finished decode\n");
	BmpSave(argv[2],Buff,BuffX,BuffY,3);			// Bitmapに保存する
	log_printf("Saved BMP\n");

	// 全て開放します
	fclose(fp);
	free(buff);
	free(Buff);

	return 0;
}
