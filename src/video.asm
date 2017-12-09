%include "video.mac"
%include "tools.mac"


; buffer.position(byte row, byte column)
%macro buffer.position 2.nolist
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
    format.enter      db BG.YELLOW
    format.tap          db BG.RED

    respawntimecursor dd 1 

    ;videoflags
    videoflags db 0
    %define hidecursor      1<<0  
    %define hideselection   1<<1
    %define hidesearch      1<<2
    %define respawcursor    1<<3
    ;video control
    scroll dd 0      ;linea que marca el scroll
    buffer.width    dd   80
    buffer.height   dd   24 
    %define buffer.length 2000 
    %define buffer.textlength 1920
    %define buffer 0xB8000

extern text
extern cursor,lines.current,lines.lengths,lines.endline,lines.startsline

section .text


;call:
;call video.Update
global video.Update
video.Update:
    startSubR
        call video.UpdateText
   
        mov al, [videoflags]
    .trycursor:
        test al,  hidecursor
        jnz .tryselection
        call video.UpdateCursor
   
    .tryselection:
        test al, hideselection
        jnz .trysearch
        call video.UpdateSelection
   
    .trysearch:
        test al, hidesearch
        jnz .end
        call video.UpdateSearch

   .end:
endSubR 0


video.UpdateText:
startSubR
  ;  break
    mov esi,text
    mov edi,buffer
    mov ecx,[buffer.height]
    cld
.rows:
    push ecx
    mov ecx,[buffer.width]
.columns:
    lodsb               ;eax = ACSII
  ;  break
    cmp al,ASCII.enter  ;si es enter entonces pinto enter
    je .paintEnter

    cmp al,ASCII.tab   ;si es tap entonces pinto taps
    je .paintTab

    cmp al,0
    je .paintEmpty


    mov ah,[format.text]                 ;pinto ACSII
    stosw
    loop .columns

.endrow:
    pop ecx
    loop .rows
    jmp .end

.paintEmpty:
    mov al,'~' 
    mov ah,[format.text]
    and ah,0x0f0                         ;nnannarita negra
    stosw                               ;solo pinto una
    dec ecx
    xor al,al
    rep stosw                           ;termino fila
    ; mov bl, [buffer]
    ; break
    jmp .endrow

.paintEnter:
    mov ah,[format.enter]
    rep stosw                           ;pintara el resto de la linea del formato 
    jmp .endrow
.paintTab:
    jmp .columns
.end:
endSubR 0




video.UpdateSelection:
startSubR

endSubR 0

video.UpdateSearch:
startSubR

endSubR 0

video.UpdateCursor:
startSubR
mov eax,[lines.current]                 
sub eax,[scroll]                        
mov dx,[buffer.width]                               
mul dx
mov edx,eax                             ;edx = 80*(lines.current - scroll)
mov eax,[lines.current] 
push eax
call lines.startsline
push edx
mov edx,eax
mov eax,[cursor]
sub eax,edx
pop edx
add edx,eax

mov ah,[format.cursor]
mov al,[buffer + 2*edx]             ;
mov [buffer + 2*edx],ax
endSubR 0


