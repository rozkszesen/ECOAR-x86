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

global _set_pixel
global _set_pixel_k
global _line_to_k
extern _setPixel

_line_to_k:
; prologue
	push	ebp			
	mov		ebp, esp

;body:
	; ebp+8 - x
	; ebp+12 - y
	; ebp+16 - imgInfo structure

	; eax - imgInfo structure
	; STACK:
	;
	sub esp, 36				; allocate space for xc, yc, dx, dy, xi, yi, ai, bi, d
	mov eax, [ebp+8]		; move imgInfo structure from stack to eax
	
	mov edx, [eax+12]		; imgInfo->xc
	mov [esp], edx			; put xc on stack

	mov edx, [eax+16]		; imgInfo->yc
	mov [esp+4], edx		; put yc on stack

	mov edx, [ebp+12]		; get x from stack
	sub edx, [esp]			; dx = x - xc
	mov [esp+8], edx		; put dx on stack

	mov edx, [ebp+16]		; get y from stack
	sub edx, [esp+4]		; dy = y - yc
	mov [esp+12], edx		; put dy onto stack

	mov DWORD[esp+16], 1	; put xi = 1 on stack; optionally change later
	mov DWORD [esp+20], 1	; put yi = 1 on stack; -||-

	cmp dword [esp+8], 0	; if (dx>=0)
	jge xi_positive		
		
;otherwise: xi_negative
	mov dword [esp+16], -1	; xi = -1
	neg dword [esp+8]		; dx = -dx

xi_positive:
	cmp dword [esp+12], 0	; if (dy>=0)
	jge yi_positive	

;otherwise: yi_negative
	mov dword [esp+20], -1	; yi = -1
	neg dword [esp+12]		; dy = -dy

yi_positive:		
	mov edx, [esp+4]		; yc
	mov ecx, [esp]			; xc
	push edx				; push third (last) argument: y
	push ecx				; push second argument: x
	push eax				; push first argument: imgInfo structure
	call _setPixel			; setPixel(pImg, xc, yc)
	
	add esp, 12				; remove previously pushed values

; deciding on leading axis:
	mov edx, [esp+8]		; dx
	mov ecx, [esp+12]		; dy
	cmp edx, ecx			; if dx > dy
	jg leading_axis_x		; do horizontal drawing

;otherwise: leading axis y:
	sub ecx, edx			; dy - dx
	neg ecx					; (dx - dy)
	shl ecx, 1				; (dx - dy) * 2 = ai
	mov [esp+24], ecx		; move ai on stack

	mov ecx, [esp+8]		; dx
	shl ecx, 1				; dx * 2 = bi
	mov [esp+28], ecx		; move bi on stack

	mov edx, [esp+28]		; bi
	sub edx, [esp+12]		; bi - dy = d
	mov [esp+32], edx		; move d on stack

loop_next_y:
	mov ecx, [esp+4]		; yc
	mov edx, [ebp+16]		; y
	cmp ecx, edx			; if yc = y
	je exit_line_to			; exit the loop

	cmp dword [esp+32], 0	; check if d >= 0
	jge if_greater
	
;otherwise: if_less		
	mov edx, [esp+28]		; load bi
	add [esp+32], edx		; d += bi

	mov edx, [esp+20]		; load yi
	add [esp+4], edx		; yc += xi

	jmp use_set_pixel

if_greater:
	mov edx, [esp+16]		; xi
	add [esp], edx			; xc += xi;
	mov edx, [esp+20]		; yi
	add [esp+4], edx		; yc += yi;
	mov edx, [esp+24]		; ai
	add [esp+32], edx		; d += ai;

use_set_pixel:			
	mov edx, [esp+4]		; yc
	mov ecx, [esp]			; xc
	push edx				
	push ecx
	push eax
	call _setPixel			; setPixel(pImg, xc, yc)
	
	add esp, 12
	jmp loop_next_y

leading_axis_x:	
	sub ecx, edx			; dy - dx
	shl ecx, 1				; (dy - dx) * 2 = ai
	mov [esp+24], ecx		; move ai on stack

	mov ecx, [esp+12]		; dy
	shl ecx, 1				; dy * 2
	mov [esp+28], ecx		; bi = dy * 2;
	mov edx, [esp+28]		; bi
	sub edx, [esp+8]		; bi-dx
	mov [esp+32], edx		; d = bi - dx;
while1:
	mov ecx, [esp]			; xc
	mov edx, [ebp+12]		; x
	cmp ecx, edx			; if (xc==x)
	je exit_line_to			; then end while loop
	cmp dword [esp+32], 0	; if (d >= 0)
	jge while1if			; then enter if body
	mov edx, [esp+28]		; bi
	add [esp+32], edx		; d += bi;
	mov edx, [esp+16]		; xi
	add [esp], edx			; xc += xi;
	jmp endwhile1if1
while1if:
	mov edx, [esp+16]		; xi
	add [esp], edx			; xc += xi;
	mov edx, [esp+20]		; yi
	add [esp+4], edx		; yc += yi;
	mov edx, [esp+24]		; ai
	add [esp+32], edx		; d += ai;
endwhile1if1:			
	mov edx, [esp+4]		; yc
	mov ecx, [esp]			; xc
	mov eax, [ebp+8]		; imgInfo
	push edx				
	push ecx
	push eax
	call _setPixel			; setPixel(pImg, xc, yc)
	add esp, 12
	jmp while1
exit_line_to:	
	mov eax, [ebp+8]		; imgInfo
	mov edx, [ebp+12]		; x
	mov [eax+12], edx		; pImg->xc = x;
	mov edx, [ebp+16]		; y
	mov [eax+16], edx		; pImg->yc = y;
	mov esp, ebp			; restore stack pointer to free up the space
	pop ebp					; restore ebp
	ret						; return


; ======================================================
_set_pixel_k:
; prologue
	push	ebp
	mov		ebp, esp

; function body

	; allocate local variables
	mov		esi, [ebp + 8] ; image descriptor
	mov		ecx, [ebp + 12] ; x coordinate
	mov		edi, [ebp + 16] ; y coordinate

	; eax for pPix
	; ebx for mask

;    int width, height; //+0 +4
;    int imgoffset;     //+8
;    int xc, yc;         //+12, +16
;    int col;            // +20
;    int linesbytes;     // + 24
;    int filesize;       // +28
;    unsigned char* filebuf; // +32

	; check validity of x and y coordinate
		; if x and y don't satisfy conditions, return
	cmp		ecx, [esi]	; x >= width
	jae		fin
	cmp		edi, [esi + 4]	; y >= height
	jae		fin

	; apply pixel mask
		; unsigned char *pPix = pImg->pImg + (((pImg->width + 31) >> 5) << 2) * y + (x >> 3)
	mov		eax, [esi]	; load width
	add		eax, 31	; add 31
	shr		eax, 5	; multiply by 32
	shl		eax, 2	; divide by 4
	mul		edi	; multiply by y
	shr		ecx, 3	; divide x by 8
	add		eax, ecx	; add x/8
	add		eax, [esi + 32]	; add pImg
	add 	eax, [esi+8]			; add image offset
	mov		[ebp - 4], eax	; save pPix

		; unsigned char mask = 0x80 >> (x & 0x07)
	mov		ecx, [ebp + 12]	; restore x coordinate
	and		ecx, 0x07
	mov		ebx, 0x80
	shr		ebx, cl
	mov		eax, ebx
	mov		BYTE [ebp - 5], al	; save mask

		; if color is 0, add mask with or
	; mov		ecx, [esi + 16]
	cmp		DWORD [esi + 20], 0
	je		add_mask

		; else, add ~mask with and
	mov		eax, [ebp - 4]	; retrive pPix
	movzx	eax, BYTE [eax]
	or		al, BYTE [ebp - 5]	; masked pixel
	mov		edx, eax
	mov		eax, [ebp - 4]
	mov		BYTE [eax], dl
	jmp		fin

add_mask:
	mov		eax, [ebp - 4]	; retrive pPix
	movzx	ebx, BYTE [ebp - 5]	; retrive mask
	movzx	eax, BYTE [eax]
	not		ebx	; ~mask
	and		eax, ebx	; masked pixel
	mov		edx, eax
	mov		eax, [ebp - 4]
	mov		BYTE [eax], dl
	jmp		fin

fin:
; epilogue
	leave
	ret

; ==========================================
_set_pixel:
	push    ebp 
    mov     ebp, esp     
    push    edi
    push    esi
        
    mov		edx, [ebp+8] ; load x into edx
    mov 	esi, [ebp+12] ; load y into esi
    mov 	edi, DWORD[ebp+16] ; load the structure

;unsigned char *pPix = imgInfo->filebuf + imgInfo->imgoffset + (((pImg->width + 31) >> 5) << 2) * y + (x >> 3);
	mov eax, [edi] ; load WIDTH (first member of the structure)
    add eax, 31
	shr eax, 5
	shl eax, 2
	mul esi ; esi holds y apparently
	mov ecx, edx ; edx holds x -> move it to ecx
	shr ecx, 3 ; x >> 3
	add eax, ecx ; add (width+31)*2/5 * y  and x/3
	add eax, [edi+8] ; add the image offset 
	add eax, [edi+32] ; add the pointer imgInfo->filebuf to the above result, store in eax

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

;======================================================================
global _test_my

_test_my:
	push    ebp 
    mov     ebp, esp   
	mov		eax, DWORD[ebp+8]
	mov 	ebx, 0

count_loop:
	mov		dl, [eax]	;dolna cwiartka edx, ladujemy 1st byte stringa (pod adresem [eax])
	inc 	eax 	;inkrementujemy wskaznik stringa
	test 	dl, dl	; operacja bitowa AND z ustawieniem odp flag -> mozna skorzystac ze skoku warunkowego
	; jesli to co jest w dl jest NIE zerem, to idziemy dalej w petli
	jnz		count_loop
end_count_loop:
	;korekcja indeksu o 2. jak dojdziemy na ostatni znak stringa \0 = "NULL"
	; bo abc\0
	sub 	eax, 2

remove_loop:
	;wskaznik eax jest juz na koncu
	mov		dl, [eax] ; to jest domyslnie BYTE.
		;jakbysmy pisali cale edx, to musielibysmy uzyc BYTE[eax]
		;ale dl jest 8bitowy, wiec nie musimy
	dec 	eax		;bo idziemy od konca
	cmp 	dl, '9'		; jesli jest wieksze, to znaczy ze znak ktory napotkalismy
						; jest rozny od ycfry
	ja	end  		; bo to znaczy ze skonczylismy usuwac
		;jesli okaze sie ze jest mniejsze badz rowne 9 to robimy znow cmp
	cmp	dl, '0' ; jezeli aktualny znak w dl jes >= '0' to robimy znow iteracje jae
	jae remove_loop
	; jesli okaze sie < to idziemy do end

end:
	mov		BYTE [eax + 2], 0 ;zakonczyc string w odpow. miejscu  - wstawiamu NULL termiantion character
				;trzeba dodac 2, bo trzeba wstawic je na miejsce dalej
	mov 	eax, DWORD [ebp+8]	; EAX - rejestr zwrotny - interfejs wyzszego poziomu (C) bierze z niego rezultat funkcji

;epilogue
    pop     ebp
	ret
