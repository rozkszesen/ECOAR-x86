;edi - pointer to image
;ch  - rfactor
;cl  - padding
;esi - normWidth
;ebx - columnCounter
;edx - rowCounter
;eax - temporary register for calculations

;algorithm
;pixel -= 128;
;pixel *= rfactor;
;pixel /= 128;
;pixel += 128;
section .text
global _line_to

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
         
