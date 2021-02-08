#include <stdio.h>
#include <stdlib.h>

typedef struct {
    int width, height; //+0 +4
    int imgoffset;     //+8
    int xc, yc;         //+12, +16
    int col;            // +20
    int linesbytes;     // + 24
    int filesize;       // +28
    unsigned char* filebuf; //+32
    unsigned char* pImg; 
     
} imgInfo;

extern void line_to(int x, int y, imgInfo *imginfo);
extern void set_pixel(int x, int y, imgInfo *imginfo);
extern void test_my(char *s);
extern void set_pixel_k(imgInfo* imginfo, int x, int y);

imgInfo* readInfo(FILE* inputFile);
void saveImage(imgInfo* imginfo);

void setPixel(imgInfo* imginfo, int x, int y);

int main(int argc, char *argv[])
{
    FILE *inputFile;

    if (argc <= 1)
    {
        printf("Too few arguments!\n");
        return 0;
    }

    inputFile = fopen(argv[1], "rb");
    if (inputFile == NULL)
    {
        printf("Error during opening of the file %s \n", argv[1]);
        return 0;
    }
    else
    {
        imgInfo *imginfo;
        imginfo = readInfo(inputFile);
        char text[] = "abc123";

        // my function
        printf("test 1\n");
        printf("imgoffset: %d\n", imginfo->imgoffset);

        //set_pixel(0, 0, imginfo);
        set_pixel_k(imginfo, 1, 1);
        //setPixel(imginfo, 1, 1);
        saveImage(imginfo);

        free(imginfo);
        imginfo = NULL;
    }

    
    return 0;
}

imgInfo* readInfo(FILE *inputFile)
{
    unsigned long imageSize = 0;
    imgInfo *imginfo = malloc(sizeof(imgInfo));

    // opening and saving to the file buffer

    fseek(inputFile, 0, SEEK_END);
    imginfo->filesize = ftell(inputFile);
    fseek(inputFile, 0, SEEK_SET);
    

    imginfo->filebuf = malloc(imginfo->filesize);

    if (imginfo->filebuf == NULL)
    {
        printf("Error during opening of the file\n");
        return 0;
    }

    fread(imginfo->filebuf, 1, imginfo->filesize, inputFile);

    // initializing with default values
    imginfo->xc = 0;
    imginfo->yc = 0;
    imginfo->col = 1;

    // reading info and updating the imginfo structure
    imginfo->width = imginfo->filebuf[18];
    imginfo->height = imginfo->filebuf[22];
    imginfo->imgoffset = imginfo->filebuf[10];
    imginfo->linesbytes = ((imginfo->width + 31) >> 5) << 2;


   //imginfo->pImg = (unsigned char*) malloc(imginfo->filesize);

    for (int i = 0; i < imginfo->height; ++i)
	{
		fread(imginfo->pImg, 1, imginfo->linesbytes, inputFile);
		imginfo->pImg += imginfo->linesbytes;
	}

    fclose(inputFile);
    return imginfo;
}

void saveImage(imgInfo* imginfo)
{
    FILE *outputFile;

    outputFile = fopen("result.bmp", "wb");
    fwrite(imginfo->filebuf, 1, imginfo->filesize, outputFile);
    fclose(outputFile);

    printf("saved\n");

    return;    
}

void setPixel(imgInfo* imginfo, int x, int y)
{

	unsigned char *pPix = imginfo->filebuf + imginfo->imgoffset + ((imginfo->linesbytes) * y + (x >> 3));
	unsigned char mask = 0x80 >> (x & 0x07);
	if (imginfo->col)
		*pPix |= mask;
	else
		*pPix &= ~mask;

}
