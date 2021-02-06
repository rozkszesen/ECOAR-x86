;ch  - x
;cl  - y
;edi - pointer to image
;ebx - columnCounter
;edx - rowCounter
;eax - temporary register for calculations

section .text

global _line_to
global _set_pixel

_set_pixel:
{
        push    ebp 
        mov     ebp, esp     
        push    ebx
        push    edi
        push    esi

        mov     ecx, [ebp+8]            ;store x in ch
        mov     edx, [ebp+12]           ;store y in cl 
       ; mov     edi, [ebp+16]          ;store pointer to the file in edi

        
        mov edi, DWORD[ebp+16]          ;store the filebuf pointer as 32bit word
        mov 
 
	;unsigned char *pPix = pImg->pImg + pImg->filebuf[10] + (((pImg->width + 31) >> 5) << 2) * y + (x >> 3);
	mov eax, DWORD[edi]             ;move the filebuf pointer to eax
        add eax, 62
	add eax, 31
	shr eax, 5
	shl eax, 2
	imul eax, edx   ; *y
	mov ecx, esi    ; x
	shr esi, 3
	add eax, esi
	add eax, DWORD[edi] ; stores the address of the pixel to set - in filebuf
 

	;unsigned char mask = 0x80 >> (x & 0x07);
	mov ecx, edx
	mov edi, 0x80
	and ecx, 0x07
	shr edi, cl		
	mov ecx, edi

	mov edi, DWORD[ebp+8]
 
    ;Checking color value and painting proper pixel
	cmp DWORD[Col], 1
	je BlackPixel
	or ecx, DWORD[eax]	;*pPix |= mask;
	mov DWORD[eax], ecx
	jmp Return
 
BlackPixel:
	not ecx			;*pPix &= ~mask;
	and ecx, DWORD[eax]
	mov DWORD[eax], ecx
 
Return:
	xor eax, eax		;return 0
	ret
        

_line_to:
        push    ebp 
        mov     ebp, esp     
        push    ebx
        push    edi
        push    esi
        
        mov     edi, [ebp+8]                    ;store pointer to the file in edi
        mov     ch, [ebp+12]                    ;store rfactor in ch

        ;padding calculate
        mov     ebx, [edi+18]                   ;load width to ebx
        mov     cl, bl                          ;in ebx there is normWidth
        and     cl, 3                           ;store padding in cl

        ;normWidth calculate
        lea     ebx, [ebx + ebx*2]              ;width*3 and store normWidth in ebx

        ;set counters
        mov     edx, [edi+22]                   ;set rowCounter (edx) to height

        ;move image pointer to the beginning of the bitmap (by the offset size)
        mov     eax, [edi+10]                   ;load offset to eax
        add     edi, eax                        ;move pointer by the offset value

row_processing:
        mov     esi, ebx                        ;set columnCounter as normWidth

pixel_processing:
        mov     al, [edi]                       ;load current pixel to al
        sub     eax, 128                        ;pixel -= 128
        imul    ch                              ;pixel *= rfactor
        sar     eax, 7                          ;pixel /= 128
        add     eax, 128                        ;pixel += 128
        mov     byte[edi], al                   ;update pixel in edi
        inc     edi                             ;go to the next pixel
        dec     esi                             ;columnCounter--    
        jnz     pixel_processing

        movzx   eax, cl
        add     edi, eax
        dec     edx                             ;rowCounter--
        jnz     row_processing

exit:  
        pop     esi
        pop     edi
        pop     ebx
        mov     esp, ebp
        pop     ebp
        ret  
         
