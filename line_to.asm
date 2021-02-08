;typedef struct {
;    int width, height; //+0 +4
;    int imgoffset;     //+8
;    int xc, yc;         //+12, +16
;    int col;            // +20
;    int linesbytes;     // + 24
;    int filesize;       // +28
;    unsigned char* filebuf; // +32
;} imgInfo;

section .text

;global _line_to
global _set_pixel

_set_pixel:
	push    ebp 
    mov     ebp, esp     
    push    edi
    push    esi
        
    mov		edx, [ebp+8] ; load x into edx
    mov 	esi, [ebp+12] ; load y into esi
    mov 	edi, DWORD[ebp+16] ; load the structure

;unsigned char *pPix = imgInfo->filebuf + imgInfo->imgoffset + (((pImg->width + 31) >> 5) << 2) * y + (x >> 3);
	mov eax, DWORD[edi] ; load WIDTH (first member of the structure)
	add eax, DWORD[edi+8] ; add the image offset 
    add eax, 31
	shr eax, 5
	shl eax, 2
	imul eax, esi ; esi holds y apparently
	mov ecx, edx ; edx holds x -> move it to ecx
	shr ecx, 3 ; x >> 3
	add eax, ecx ; add (width+31)*2/5 * y  and x/3
	add eax, DWORD[edi+32] ; add the pointer imgInfo->filebuf to the above result, store in eax

	;unsigned char mask = 0x80 >> (x & 0x07);
	mov ecx, edx  ; move x to ecx for operatons on x again
	mov edi, 0x80 ; mask with one white pixel -> loaded to edi
	and ecx, 0x07 ; xmod8 -> place for the pixel in the byte
	shr edi, cl	  ; move the mask cl times to the proper place (result of previous instruction)
	mov ecx, edi  ; move the modified mask to ecx 

	mov edi, DWORD[ebp+16] ; move the structure to edi again

    ;Checking color value and painting proper pixel
	cmp DWORD[edi+20], 1
	je BlackPixel
	or ecx, DWORD[eax]	;*pPix |= mask;
	mov DWORD[eax], ecx
	jmp Return

BlackPixel:
	not ecx			; mask => ~mask
	and ecx, DWORD[eax] ; *pPix &= ~mask
	mov DWORD[eax], ecx ; store result - couldn't be done in one instruction?

Return:

	pop     esi
    pop     edi
    mov     esp, ebp
    pop     ebp

	ret
