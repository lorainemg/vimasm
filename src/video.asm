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

section .data
    ;Formats
    format.cursor       db BG.CYAN|0xf
    format.text         db BG.BRIGHT|0xf
    format.selection    db 0x90
    format.search       db 0x00

    ;videoflags
    videoflags db 0
    %define hidecursor 0x1  
    %define respawncursor 0x2
    %define hidesearch 0x4

    respawntimecursor db 1 



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
mov ah,[format.text]

.loop:            ;ciclo 
lodsb             ;eax = actual linea del text
stosw             ; movemos al buffer el Format + ASCII
loop .loop        ;volver 

mov eax,[cursor]
shl eax,1
mov dl,[FBUFFER + eax]
mov dh,[format.cursor]
mov [FBUFFER + eax],dx
endSubR 0
