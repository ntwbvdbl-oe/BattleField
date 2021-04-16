#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cstring>

#ifdef WIN32

#include <windows.h>

#else

typedef unsigned char BYTE;
typedef unsigned short WORD;
typedef unsigned int DWORD;
typedef int LONG;

#pragma pack(2)
typedef struct tagBITMAPFILEHADER {
	WORD bfType;			//0x424D for .bmp
	DWORD bfSize;			//FileSize
	WORD bfReserved1;		//Windows Reserve
	WORD bfReserved2;		//Windows Reserve
	DWORD bfOffBits;		//Offset to bit data
}BITMAPFILEHEADER;
#pragma pack()

typedef struct tagBITMAPINFOHEADER {
	DWORD biSize;			//sizeof(BITMAPINFOHEADER), 40
	LONG biWidth;			//image width
	LONG biHeight;			//image height
	WORD biPlanes;			//1
	WORD biBitCount;		//1, 2, 4, 8, 16, 24, 32
	DWORD biCompression;	//bit zip type
	DWORD biSizeImage;		//sizeof bit data
	LONG biXPelsPerMeter;	//XPixels
	LONG biYPelsPerMeter;	//YPixels
	DWORD biClrUsed;		//num of colors
	DWORD biClrImportant;	//important color
}BITMAPINFOHEADER;

typedef struct tagRGBQUAD {
	BYTE rgbBlue;
	BYTE rgbGreen;
	BYTE rgbRed;
	BYTE rgbReserved;
}RGBQUAD;

#endif

using namespace std;

class Bitmap {
public:
	Bitmap(): colorTable(NULL), dataBuf(NULL) {}

	Bitmap(const char *name) { read(name); }

	Bitmap(const Bitmap &bm) { *this = bm; }

	~Bitmap() {
		if(colorTable)
			free(colorTable);
		if(dataBuf)
			free(dataBuf);
	}

	Bitmap& operator = (const Bitmap &bm) {			//copy constructor
		fileHeader = bm.fileHeader;
		infoHeader = bm.infoHeader;
		width = bm.width;
		height = bm.height;
		lineByte = bm.lineByte;
		if(infoHeader.biBitCount == 8) {
			colorTable = (RGBQUAD*)malloc(256 * sizeof(RGBQUAD));
			memcpy(colorTable, bm.colorTable, 256 * sizeof(RGBQUAD));
		}else
			colorTable = NULL;
		dataBuf = (BYTE*)malloc(infoHeader.biSizeImage);
		memcpy(dataBuf, bm.dataBuf, infoHeader.biSizeImage);
		return *this;
	}
	
	void read(const char *name) {		//read bitmap from file
		FILE *fp;
		fp = fopen(name, "rb");
		fread(&fileHeader, sizeof(BITMAPFILEHEADER), 1, fp);
		fread(&infoHeader, sizeof(BITMAPINFOHEADER), 1, fp);

		width = infoHeader.biWidth;
		height = infoHeader.biHeight;
		if(infoHeader.biBitCount == 24)
			lineByte = (width * 3 + 3) / 4 * 4;		//4k bytes per line in Bitmap
		else
			lineByte = (width + 3) / 4 * 4;
		dataBuf = (BYTE*)malloc(infoHeader.biSizeImage);

		if(infoHeader.biBitCount == 8) {
			colorTable = (RGBQUAD*)malloc(256 * sizeof(RGBQUAD));
			fread(colorTable, 256, sizeof(RGBQUAD), fp);
		}else
			colorTable = NULL;
		fread(dataBuf, 1, infoHeader.biSizeImage, fp);
		fclose(fp);
	}

	void write(const char *name) {			//write bitmap to file
		FILE *fp;
		fp = fopen(name, "wb");
		fwrite(&fileHeader, sizeof(BITMAPFILEHEADER), 1, fp);
		fwrite(&infoHeader, sizeof(BITMAPINFOHEADER), 1, fp);
		if(infoHeader.biBitCount == 8)
			fwrite(colorTable, sizeof(RGBQUAD), 256, fp);
		fwrite(dataBuf, 1, infoHeader.biSizeImage, fp);
		fclose(fp);
	}

	Bitmap rgbToYUV() {
		Bitmap ret = *this;
		for(int i = 0; i < height; ++i)
			for(int j = 0; j < width; ++j) {
				//calc start address
				BYTE *rgbData = dataBuf + i * lineByte + j * 3;
				BYTE *yuvData = ret.dataBuf + i * lineByte + j * 3;
				yuvData[0] = (BYTE)(rgbData[2] * 0.299 + rgbData[1] * 0.587 + rgbData[0] * 0.114);				//y
				yuvData[1] = (BYTE)(rgbData[2] * -0.147 + rgbData[1] * -0.289 + rgbData[0] * 0.435 + 128);		//u [-128, 128)
				yuvData[2] = (BYTE)(rgbData[2] * 0.615 + rgbData[1] * -0.515 + rgbData[0] * -0.100 + 128);		//v [-128, 128)
			}
		return ret;
	}

	Bitmap yuvToRGB() {
		Bitmap ret = *this;
		for(int i = 0; i < height; ++i)
			for(int j = 0; j < width; ++j) {
				BYTE *rgbData = ret.dataBuf + i * lineByte + j * 3;
				BYTE *yuvData = dataBuf + i * lineByte + j * 3;
				rgbData[2] = (BYTE)min(255, max(0, (int)(yuvData[0] + 1.14 * (yuvData[2] - 128))));
				rgbData[1] = (BYTE)min(255, max(0, (int)(yuvData[0] - 0.39 * (yuvData[1] - 128) - 0.58 * (yuvData[2] - 128))));
				rgbData[0] = (BYTE)min(255, max(0, (int)(yuvData[0] + 2.03 * (yuvData[1] - 128))));
			}
		return ret;
	}

	Bitmap reduceLuminance() {
		Bitmap ret = *this;
		for(int i = 0; i < height; ++i)
			for(int j = 0; j < width; ++j)
				ret.dataBuf[i * lineByte + j * 3] /= 2;
		return ret;
	}

	Bitmap toGrayScale() {
		Bitmap ret;
		ret.fileHeader = fileHeader;
		ret.infoHeader = infoHeader;
		ret.width = width;
		ret.height = height;
		ret.lineByte = (width + 3) / 4 * 4;

		ret.infoHeader.biBitCount = 8;
		ret.infoHeader.biSizeImage = ret.lineByte * ret.height;
		ret.infoHeader.biClrUsed = 256;
		ret.fileHeader.bfOffBits = sizeof(BITMAPFILEHEADER) + sizeof(BITMAPINFOHEADER) + sizeof(RGBQUAD) * 256;
		ret.fileHeader.bfSize = ret.fileHeader.bfOffBits + ret.infoHeader.biSizeImage;

		ret.dataBuf = (BYTE*)malloc(ret.infoHeader.biSizeImage);
		for(int i = 0; i < height; ++i)
			for(int j = 0; j < width; ++j) {
				BYTE *DataBuf = dataBuf + i * lineByte + j * 3;
				ret.dataBuf[i * ret.lineByte + j] = (BYTE)(DataBuf[2] * 0.299 + DataBuf[1] * 0.587 + DataBuf[0] * 0.114);
			}

		ret.colorTable = (RGBQUAD*)malloc(256 * sizeof(RGBQUAD));
		for(int i = 0; i < 256; ++i) {
			ret.colorTable[i].rgbBlue = (BYTE)i;
			ret.colorTable[i].rgbGreen = (BYTE)i;
			ret.colorTable[i].rgbRed = (BYTE)i;
			ret.colorTable[i].rgbReserved = 0;
		}
		return ret;
	}

	double calcBetween(const Bitmap &binary) {		//Calc Between, grayscale: *this, binary: binary
		int sumFgrd = 0, sumBgrd = 0, cntFgrd = 0, cntBgrd = 0;
		for(int i = 0; i < height; ++i)
			for(int j = 0; j < width; ++j)
				if(binary.dataBuf[i * lineByte + j])
					++cntFgrd, sumFgrd += dataBuf[i * lineByte + j];
				else
					++cntBgrd, sumBgrd += dataBuf[i * lineByte + j];
		double wF = 1.0 * cntFgrd / (width * height), wB = 1.0 * cntBgrd / (width * height);
		double uF = 1.0 * sumFgrd / cntFgrd, uB = 1.0 * sumBgrd / cntBgrd;
		double u = wF * uF + wB * uB;
		return wF * (uF - u) * (uF - u) + wB * (uB - u) * (uB - u);
	}

	pair<double, double> calcAvg(const Bitmap &binary) {	//Calc Average, grayscale: *this, binary: binary
		int sumFgrd = 0, sumBgrd = 0, cntFgrd = 0, cntBgrd = 0;
		for(int i = 0; i < height; ++i)
			for(int j = 0; j < width; ++j)
				if(binary.dataBuf[i * lineByte + j])
					++cntFgrd, sumFgrd += dataBuf[i * lineByte + j];
				else
					++cntBgrd, sumBgrd += dataBuf[i * lineByte + j];
		return make_pair(1.0 * sumFgrd / cntFgrd, 1.0 * sumBgrd / cntBgrd);
	}

	Bitmap binarize(BYTE threshold) {		//binarize *this using threshold
		Bitmap ret = *this;
		for(int i = 0; i < height; ++i)
			for(int j = 0; j < width; ++j)
				if(ret.dataBuf[i * lineByte + j] < threshold)
					ret.dataBuf[i * lineByte + j] = 0;
				else
					ret.dataBuf[i * lineByte + j] = 255;
		return ret;
	}

	Bitmap binarizeInOTSU() {		//OTSU Algorithm
		Bitmap bm;
		BYTE threshold = 0;
		double maxBetween = 0;
		for(BYTE i = 255; i; --i) {		//for any threshold, binarize and find maximum between
			bm = binarize(i);
			double tmp = calcBetween(bm);
			if(tmp > maxBetween)
				maxBetween = tmp, threshold = i;
		}
		return binarize(threshold);
	}

	Bitmap binarizeInIteration() {		//Iteration Algorithm,
		Bitmap bm;
		BYTE threshold, tmp = 127;
		pair<double, double> avg;
		do {
			threshold = tmp;
			bm = binarize(threshold);
			avg = calcAvg(bm);
			tmp = BYTE((avg.first + avg.second) / 2.0 + 0.5);		//round to integer
		}while(tmp != threshold);	//stop when average is equal to threshold
		return binarize(threshold);
	}

	Bitmap erosion() {		//Erosion using '+'
		Bitmap ret = *this;
		int dx[] = {0, 0, 1, 0, -1}, dy[] = {0, 1, 0, -1, 0};
		for(int i = 0; i < height; ++i)
			for(int j = 0; j < width; ++j) {
				bool flag = true;
				for(int k = 0; k < 5; ++k)
					if(i + dx[k] >= 0 && i + dx[k] < height && j + dy[k] >= 0 && j + dy[k] < width && dataBuf[(i + dx[k]) * lineByte + j + dy[k]] == 0)
						flag = false;		//and
				ret.dataBuf[i * ret.lineByte + j] = flag ? 255 : 0;
			}
		return ret;
	}

	Bitmap dilation() {		//Dilation using '+'
		Bitmap ret = *this;
		int dx[] = {0, 0, 1, 0, -1}, dy[] = {0, 1, 0, -1, 0};
		for(int i = 0; i < height; ++i)
			for(int j = 0; j < width; ++j) {
				bool flag = false;
				for(int k = 0; k < 5; ++k)
					if(i + dx[k] >= 0 && i + dx[k] < height && j + dy[k] >= 0 && j + dy[k] < width && dataBuf[(i + dx[k]) * lineByte + j + dy[k]])
						flag = true;		//or
				ret.dataBuf[i * ret.lineByte + j] = flag ? 255 : 0;
			}
		return ret;
	}

	Bitmap opening() { return erosion().dilation(); }

	Bitmap closing() { return dilation().erosion(); }

	Bitmap visibilityEnhancement() {
		Bitmap ret = rgbToYUV();
		BYTE maxLuminance = 0;
		for(int i = 0; i < height; ++i)
			for(int j = 0; j < width; ++j)
				maxLuminance = max(maxLuminance, ret.dataBuf[i * lineByte + j * 3]);
		for(int i = 0; i < height; ++i)
			for(int j = 0; j < width; ++j)
				ret.dataBuf[i * lineByte + j * 3] = (BYTE)(log(ret.dataBuf[i * lineByte + j * 3] + 1) / log(maxLuminance + 1) * 255);
		ret = ret.yuvToRGB();
		return ret;
	}

	Bitmap histogramEqualization() {
		Bitmap ret = *this;
		BYTE color[256];
		int size = height * width;	//n
		int sum[256] = {0};			//sum of pixels
		for(int i = 0; i < height; ++i)
			for(int j = 0; j < width; ++j)
				++sum[dataBuf[i * lineByte + j]];
		for(int i = 1; i < 256; ++i)
			sum[i] += sum[i - 1];	//s_k * n
		for(int i = 0; i < 256; ++i)
			color[i] = (BYTE)(1.0 * sum[i] / size * 255 + 0.5);		//s_k * 255 and round to integer
		for(int i = 0; i < height; ++i)
			for(int j = 0; j < width; ++j)
				ret.dataBuf[i * lineByte + j] = color[ret.dataBuf[i * lineByte + j]];
		return ret;
	}
	Bitmap transfer(double p[3][3]) {
		Bitmap ret;
		ret.fileHeader = fileHeader;
		ret.infoHeader = infoHeader;
		ret.height = ret.width = 0;
		for(int i = 0; i < height; ++i)		//calc max size
			for(int j = 0; j < width; ++j) {
				ret.height = max(ret.height, (int)(p[0][0] * i + p[0][1] * j + p[0][2] + 0.5));
				ret.width = max(ret.width, (int)(p[1][0] * i + p[1][1] * j + p[1][2] + 0.5));
			}
		ret.infoHeader.biWidth = ++ret.width;
		ret.infoHeader.biHeight = ++ret.height;

		if(infoHeader.biBitCount == 8) {
			ret.lineByte = (ret.width + 3) / 4 * 4;
			ret.colorTable = (RGBQUAD*)malloc(256 * sizeof(RGBQUAD));
			memcpy(ret.colorTable, colorTable, 256 * sizeof(RGBQUAD));
		}else
			ret.lineByte = (ret.width * 3 + 3) / 4 * 4;
		ret.infoHeader.biSizeImage = ret.lineByte * ret.height;
		ret.fileHeader.bfSize = ret.fileHeader.bfOffBits + ret.infoHeader.biSizeImage;

		ret.dataBuf = (BYTE*)malloc(ret.infoHeader.biSizeImage);
		memset(ret.dataBuf, 255, ret.infoHeader.biSizeImage);	//initial white
		for(int i = 0; i < height; ++i)
			for(int j = 0; j < width; ++j) {
				int x = (int)(p[0][0] * i + p[0][1] * j + p[0][2] + 0.5);
				int y = (int)(p[1][0] * i + p[1][1] * j + p[1][2] + 0.5);
				if(x < 0 || x >= ret.height || y < 0 || y >= ret.width)		//without boundary
					continue;
				if(ret.infoHeader.biBitCount == 8)
					ret.dataBuf[x * ret.lineByte + y] = dataBuf[i * lineByte + j];
				else
					for(int k = 0; k < 3; ++k)
						ret.dataBuf[x * ret.lineByte + y * 3 + k] = dataBuf[i * lineByte + j * 3 + k];
			}
		return ret;
	}

	Bitmap roleInterpolation() {
		Bitmap ret = *this;
		for(int i = 0; i < height; ++i)
			for(int j = width - 1; j; --j)	//reverse order and copy from j - 1
				if(ret.infoHeader.biBitCount == 8) {
					if(ret.dataBuf[i * lineByte + j] == 255)
						ret.dataBuf[i * lineByte + j] = ret.dataBuf[i * lineByte + j - 1];
				}else {
					BYTE *DataBuf = ret.dataBuf + i * lineByte + j * 3;
					if(DataBuf[0] == 255 && DataBuf[1] == 255 && DataBuf[2] == 255) {
						DataBuf[0] = DataBuf[-3];
						DataBuf[1] = DataBuf[-2];
						DataBuf[2] = DataBuf[-1];
					}
				}
		return ret;
	}

	Bitmap translation(int dx = 0, int dy = 0) {
		double trans[3][3] = {{1, 0, 1.0 * dx}, {0, 1, 1.0 * dy}, {0, 0, 1}};
		return transfer(trans);
	}

	Bitmap mirror(bool isX = false, bool isY = false) {
		double trans[3][3] = {{isX ? -1.0 : 1.0, 0, isX ? height - 1.0 : 0}, {0, isY ? -1.0 : 1.0, isY ? width - 1.0 : 0}, {0, 0, 1}};
		return transfer(trans);
	}

	Bitmap rotation(double theta = 0.0) {
		double trans[3][3] = {{cos(theta), -sin(theta), sin(theta) > 0 ? width * sin(theta) : 0}, {sin(theta), cos(theta), sin(theta) < 0 ? -height * sin(theta) : 0}, {0, 0, 1}};
		return transfer(trans).roleInterpolation();
	}

	Bitmap scale(double fx = 1.0, double fy = 1.0) {
		double trans[3][3] = {{fx, 0, 0}, {0, fy, 0}, {0, 0, 1}};
		return transfer(trans);
	}

	Bitmap shear(double fx = 0.0, double fy = 0.0) {
		double trans[3][3] = {{1, fx, 0}, {fy, 1, 0}, {0, 0, 1}};
		return transfer(trans);
	}

	void printInIPCore() {
		for(int i = height - 1; i >= 0; --i)
			for(int j = 0; j < width; ++j) {
				BYTE *rgbData = dataBuf + i * lineByte + j * 3;
				int r = rgbData[2] >> 4, g = rgbData[1] >> 4, b = rgbData[0] >> 4;
				printf("%x%x%x,", r, g, b);
			}
	}

	void printInVGA(const char* name) {
		FILE *fp = fopen(name, "w");
		for(int i = height - 1; i >= 0; --i)
			for(int j = 0; j < width; ++j) {
				BYTE *rgbData = dataBuf + i * lineByte + j * 3;
				int r = rgbData[2] >> 4, g = rgbData[1] >> 4, b = rgbData[0] >> 4;
				fprintf(fp, "\t\tdataDigit[9][%d][%d] <= 12'h%x%x%x;\n", height - 1 - i, j, r, g, b);
			}
		fclose(fp);
	}

	void printInVerilogModule(const char* name) {
		size_t len = strlen(name);
		char *fileName = (char*)malloc(len + 3);
		strcpy(fileName, name);
		fileName[len] = '.';
		fileName[len + 1] = 'v';
		fileName[len + 2] = 0;
		FILE *fp = fopen(fileName, "w");
		fprintf(fp, "`timescale 1ns / 1ps\n");
		fprintf(fp, "module %s(\n", name);
		fprintf(fp, "\tinput [8:0] x,\n\tinput [9:0] y,\n\toutput reg [11:0] rgb\n\t);\n\n");
		fprintf(fp, "\treg [11:0] data[0:%d][0:%d];\n", height - 1, width - 1);
		fprintf(fp, "\tinitial begin\n");
		for(int i = height - 1; i >= 0; --i)
			for(int j = 0; j < width; ++j) {
				BYTE *rgbData = dataBuf + i * lineByte + j * 3;
				int r = rgbData[2] >> 4, g = rgbData[1] >> 4, b = rgbData[0] >> 4;
				fprintf(fp, "\t\tdata[%d][%d] <= 12'h%x%x%x;\n", height - 1 - i, j, r, g, b);
			}
		fprintf(fp, "\tend\n\n");
		fprintf(fp, "\talways @* begin\n\t\trgb = data[x][y];\n\tend\n\n");
		fprintf(fp, "endmodule\n");
		fclose(fp);
		free(fileName);
	}
private:
	BITMAPFILEHEADER fileHeader;
	BITMAPINFOHEADER infoHeader;
	LONG width;
	LONG height;
	LONG lineByte;
	RGBQUAD *colorTable;
	BYTE *dataBuf;
};

int main() {
	Bitmap bitmap;
	/*dataBase
	freopen("dataBase.txt", "w", stdout);
	char dataBaseFileName[100][100] = {
		"picture/0000_hero.bmp",
		"picture/0001_road.bmp",
		"picture/0010_wall.bmp",
		"picture/0011_key.bmp",
		"picture/0100_attack.bmp",
		"picture/0101_defend.bmp",
		"picture/0110_hp.bmp",
		"picture/0111_door.bmp",
		"picture/1000_shop.bmp",
		"picture/1001_shop.bmp",
		"picture/1010_shop.bmp",
		"picture/1011_slim.bmp",
		"picture/1100_skeleton.bmp",
		"picture/1101_wizard.bmp",
		"picture/1110_guard.bmp",
		"picture/1111_boss.bmp",
	};
	printf("memory_initialization_radix = 16;\nmemory_initialization_vector =\n");
	for(int i = 0; i < 16; ++i) {
		bitmap.read(dataBaseFileName[i]);
		bitmap.printInIPCore();
	}
	fclose(stdout);*/
	/*dataStatue
	freopen("dataStatue.txt", "w", stdout);
	char dataStatueFileName[100][100] = {
		"picture/0001_road.bmp",
		"picture/0000_hero.bmp",
		"picture/statue_0010_health.bmp",
		"picture/statue_0011_attack.bmp",
		"picture/statue_0100_defend.bmp",
		"picture/statue_0101_coin.bmp",
		"picture/0011_key.bmp",
	};
	printf("memory_initialization_radix = 16;\nmemory_initialization_vector =\n");
	for(int i = 0; i < 7; ++i) {
		bitmap.read(dataStatueFileName[i]);
		bitmap.printInIPCore();
	}
	//fclose(stdout);
	//dataDigit
	//freopen("dataDigit.txt", "w", stdout);
	char dataDigitFileName[100][100] = {
		"picture/0_digit.bmp",
		"picture/1_digit.bmp",
		"picture/2_digit.bmp",
		"picture/3_digit.bmp",
		"picture/4_digit.bmp",
		"picture/5_digit.bmp",
		"picture/6_digit.bmp",
		"picture/7_digit.bmp",
		"picture/8_digit.bmp",
		"picture/9_digit.bmp",
	};
	//printf("memory_initialization_radix = 16;\nmemory_initialization_vector =\n");
	for(int i = 0; i < 10; ++i) {
		bitmap.read(dataDigitFileName[i]);
		bitmap.printInIPCore();
	}
	fclose(stdout);*/
	//dataShop
	freopen("dataShop.coe", "w", stdout);
	char dataMapFileName[100][100] = {
		"picture/shop.bmp",
		"picture/shop_cursor.bmp",
	};
	printf("memory_initialization_radix = 16;\nmemory_initialization_vector =\n");
	for(int i = 0; i < 2; ++i) {
		bitmap.read(dataMapFileName[i]);
		bitmap.printInIPCore();
	}
	for(int i = 0; i < 7; ++i)
		printf("000,");
	fclose(stdout);
	/*dataBattle
	freopen("dataBattle.coe", "w", stdout);
	char dataBattleFileName[100][100] = {
		"picture/0001_road.bmp",
		"picture/battle_v.bmp",
		"picture/battle_s.bmp",
		"picture/statue_0010_health.bmp",
		"picture/statue_0011_attack.bmp",
		"picture/statue_0100_defend.bmp",
		"picture/1011_slim.bmp",
		"picture/1100_skeleton.bmp",
		"picture/1101_wizard.bmp",
		"picture/1110_guard.bmp",
		"picture/1111_boss.bmp",
		"picture/0_digit.bmp",
		"picture/1_digit.bmp",
		"picture/2_digit.bmp",
		"picture/3_digit.bmp",
		"picture/4_digit.bmp",
		"picture/5_digit.bmp",
		"picture/6_digit.bmp",
		"picture/7_digit.bmp",
		"picture/8_digit.bmp",
		"picture/9_digit.bmp",
	};
	printf("memory_initialization_radix = 16;\nmemory_initialization_vector =\n");
	printf("c60,");
	for(int i = 0; i < 21; ++i) {
		bitmap.read(dataBattleFileName[i]);
		bitmap.printInIPCore();
	}
	for(int i = 0; i < 15; ++i)
		printf("000,");
	fclose(stdout);
	*/
	return 0;
}

