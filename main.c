#include <stdio.h>
#include <stdlib.h>

extern void line_to(unsigned char *inputFileArray, unsigned int rfactor);

typedef struct {
    unsigned char* filebuf;
    unsigned char* pImg;
    int width, height;
    int xc, yc;
    int col;
    int linesbytes;
    unsigned long filesize;
} imgInfo;

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
        
        // my function
        setPixel(imginfo, 1, 1);
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

    fread(imginfo->filebuf, 1, imginfo->filesize, inputFile);

    if (imginfo->filebuf == NULL)
    {
        printf("Error during opening of the file\n");
        return 0;
    }

    // initializing with default values
    imginfo->xc = 0;
    imginfo->yc = 0;
    imginfo->col = 1;

    // reading info and updating the imginfo structure
    imginfo->width = imginfo->filebuf[18];
    imginfo->height = imginfo->filebuf[22];
    
    imageSize = (((imginfo->width + 31) >> 5) << 2) * imginfo->height;
    imginfo->pImg = (unsigned char*) malloc(imageSize);
    imginfo->linesbytes = ((imginfo->width + 31) >> 5) << 2;

    // reading the image
    fseek(inputFile, imginfo->filebuf[10], SEEK_SET);
    
    for (int y=0; y < imginfo->height; ++y)
	{
		fread(imginfo->pImg, 1, abs(imginfo->linesbytes), inputFile);
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

	unsigned char *pPix = imginfo->filebuf + imginfo->filebuf[10] + ((imginfo->linesbytes) * y + (x >> 3));
	unsigned char mask = 0x80 >> (x & 0x07);
	if (imginfo->col)
		*pPix |= mask;
	else
		*pPix &= ~mask;

}
