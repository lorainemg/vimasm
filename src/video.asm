%include "video.mac"
%include "tools.mac"
; Frame buffer location
%define FBUFFER 0xB8000

; FBOFFSET(byte row, byte column)
%macro FBOFFSET 2.nolist
    xor eax, eax
    mov al, COLS
    mul byte %1
    add al, %2
    adc ah, 0
    shl ax, 1
%endmacro


section .text

extern text
extern cursor

;call:
;call UpdateBuffer
global UpdateBuffer
UpdateBuffer:
startSubR
mov edi ,FBUFFER  ;edi = buffer
mov esi ,text ;esi = text
mov ecx ,2000     ;filas*culumnas
cld               ;df =0
mov ax,0x0f00
.loop:            ;ciclo 
lodsb             ;eax = actual linea del text
stosw             ; movemos al buffer el Format + ASCII
loop .loop        ;volver 

mov eax,[cursor]
shl eax,1
mov dl,[FBUFFER + eax]
mov dh,0xf0
mov [FBUFFER + eax],dx

endSubR 0
