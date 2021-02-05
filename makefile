CC=gcc
ASMBIN=nasm

all : asm cc link
asm : 
	$(ASMBIN) -o line_to.o -f elf -g -l line_to.lst line_to.asm
cc :
	$(CC) -m32 -c -g -O0 main.c
link :
	$(CC) -m32 -g -o program main.o line_to.o
clean :
	rm *.o
	rm program.exe
	rm line_to.lst
