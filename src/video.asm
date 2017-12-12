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

section .bss
    modetext resb 10
    buffer.textcache    resw 0xf00

section .data
    ;Formats
    format.cursor       db BG.CYAN|0xf
    format.text         db BG.BRIGHT|0xf
    format.select       db 0x90
    format.search       db 0x00
    format.enter        db BG.YELLOW
    format.tap          db BG.RED

    respawntimecursor   dd 1 

    ;videoflags
    global videoflags
    videoflags          db 0
    %define hidecursor      1<<0  
    %define hideselection   1<<1
    %define hidesearch      1<<2
    %define respawcursor    1<<3
    
    ;video control
    scroll              dd 0      ;linea que marca el scroll
    
    buffer.width        dd   80
    buffer.height       dd   24 
    %define buffer.length       2000 
    %define buffer.textlength   0x780
    %define buffer              0xB8000
    %define buffer.lastrow     0xb8f00
;externs del texto
extern text
extern cursor,lines.current,lines.lengths,lines.endline,lines.startsline,lines.endline,lines.starts,lines.line
extern select.start,select.mode


section .text


;call:
;call video.Update
global video.Update
video.Update:
    startSubR
        call video.UpdateText
        mov dl, [videoflags]
    
    .trycursor:
        test dl,  hidecursor
        jnz .tryselection
        call video.UpdateCursor
    
    .tryselection:
        test dl, hideselection
        jnz .trysearch
        call video.UpdateSelection
   
    .trysearch:
 ;      test al, hidesearch
 ;       jnz .end
        ;call video.UpdateSearch

   .end:
   call video.UpdateBuffer
endSubR 0

video.UpdateBuffer:
  startSubR
        
        mov esi,buffer.textcache
        mov edi,buffer
        mov ecx,[buffer.height]
        cld
    .rows:
        push ecx
        mov ecx,[buffer.width]
    .columns:
        lodsw               ;eax = ASCII
        cmp al,ASCII.enter  ;si es enter entonces pinto enter
        je .paintEnter

        cmp al,ASCII.tab   ;si es tap entonces pinto taps
        je .paintTab
        cmp al,0
        je .paintEmpty

        stosw
        loop .columns

    .endrow:
        pop ecx
        loop .rows
        jmp .end

    .paintEmpty:
        mov al,'~' 
        stosw                               ;solo pinto una
        dec ecx
        xor al,al
        rep stosw                           ;termino fila
        jmp .endrow

    .paintEnter:
        stosw
        dec ecx
        mov ah,[format.text]
        xor al,al
        rep stosw                           ;pintara el resto de la linea del formato 
        jmp .endrow
    .paintTab:
        jmp .columns
    .end:
endSubR 0 

video.UpdateText:
    startSubR
    mov eax,[scroll]
    push eax 
    call lines.startsline

    lea esi,[text +eax]
    mov edi, buffer.textcache
    mov ecx, buffer.textlength
    cld

    .lp:
    lodsb 
    cmp al,ASCII.enter
    je .enter 
    mov ah,[format.text]
    jmp .stos 
    .enter:
    mov ah,[format.enter]

    .stos:
    stosw
    loop .lp
    
endSubR 0



 
video.UpdateSelection:
	startSubR
    
	mov eax,[select.start]
	mov edx,[cursor]
	
    cmp eax,edx
	jbe .mode
	
    push eax
    push edx
    pop eax
    pop edx 
	
    .mode:
	push edx
    push eax

	cmp dword [select.mode],0
	jne .tryline
	call video.UpdateSelection.normal
    
    jmp .end
    .tryline:
	
    cmp dword [select.mode],1
	jne .tryblock
	call video.UpdateSelection.line
    jmp .end
    .tryblock:
    pop eax
    pop eax
    ;call select.copy.block
.end:
endSubR 0

;call:
;push dword end: ebp + 8
;push dword start: ebp + 4
video.UpdateSelection.normal:
startSubR
	mov eax,[ebp+4]
	mov edx,[ebp+8]
	;Se copiaria, desde el principio de la linea hasta el final de mi linea actual
	mov ecx, edx					;la cantidad de movimientos q hago:					
	sub ecx, eax
    inc ecx					;
	lea edi, [buffer.textcache+2*eax]
    lea esi, [buffer.textcache+2*eax]
    cld
	.lp:
    lodsw
    mov ah,[format.select]
	stosw
    loop .lp
endSubR 8
;Selecciona en modo linea
	;call:
	;push dword end ebp+8
	;push dword start ebp+4
	;call select.line
video.UpdateSelection.line:
startSubR
	push dword[ebp+4]				;pongo donde empieza mi seleccion como parametro
	call lines.line					;pregunto por la linea de mi seleccion
	mov edx, [lines.starts+4*eax]	;busco el principio de esa linea


	push dword[ebp+8]		        ;pongo mi linea actual como parametro
	call lines.line                 ;busco la linea de mi final como parametro
	push eax                        ;pongo la lina como parametro
	call lines.endline				;busco el final de la linea
    dec eax 

	;Se copiaria, desde el principio de la linea de inicio hasta el final de la linea final
	mov ecx, eax					;la cantidad de movimientos q hago:					
	sub ecx, edx					;
	inc ecx
	lea esi, [buffer.textcache+2*edx]
	lea edi, [buffer.textcache+2*edx]
    cld
	.lp:
        lodsw
        mov ah,[format.select]
	    stosw
        loop .lp
endSubR 8


video.UpdateSearch:
    startSubR

endSubR 0

video.UpdateCursor:
    startSubR
    push dword [scroll] 
    call lines.startsline
    mov edx,[cursor]
    sub edx,eax
    mov al,[format.cursor]
    mov [buffer.textcache + 2*edx +1],al
endSubR 0






