%include "tools.mac"
%include "keys.mac"

extern getChar, checkKey1, isKey1
extern video.Update

section .bss
text resb 80

section .data
cursor db 0
top db 0

section .text
global mode.command
mode.command:
    	;Veo si escribo una palabra
		call getChar				;obtiene el caracter de la tecla que se presiono
		cmp ax, 0 					;si no se presiona ninguna tecla
		je .command				;entonces se salta hasta el final

		push eax					    ;se guarda el caracter en la pila como parametro de text.write
		call text.insert			    ;se procede a escribir el caracter en el texto	call UpdateBuffer
		jmp .end

        .command:
        ;Otros  comandos:
        checkKey1 key.backspace, .erase
		checkKey1 key.enter, 	 .enter 		;Comprueba si se presiono enter
		checkKey1 key.esc,       .exitmode 	

        jmp .end2
        ;---------------------------------------------------------------------------------------------------
        .erase:
		push dword[cursor]			;para borrar mueve el texto hacia la izq desde la posicion del cursor
		call text.movebackward
		jmp .end        
        .enter:
        ;Logica para presionar enter
        jmp .end
        .exitmode:
        ;Logica para salir del modo
        jmp .end


    .end:
    call video.Update
    .end2:
    jmp mode.command
ret


text.insert:
	startSubR
		push dword[cursor]
		call text.moveforward

		mov ebx,text  					;ebx =text
		add ebx,[cursor]				;ebx = text + cursor
		mov al,[ebp+4]   				;guardo 
		mov [ebx],al					;[text + cursor] = ASCII
	    
	    inc dword [cursor]				;incremento la posicion del cursor
	endSubR 4

;mueve todo el texto
	;call 
	;push dword start: ebp + 4
	;call text.move 
text.moveforward:
	startSubR
	    ;creo espacio en texto
        mov eax, [top]

	    mov ecx, eax						;cuento cuanto me voy a mover:
	    sub ecx,[ebp+4]						;la ultima pos del texto - la posicion actual
	    inc ecx
	    dec eax								;decremento eax porque es antes de la pos que me dan (antes del cursor)
	    std
	    lea edi,[text+eax+1]				;voy a copiar hacia la ultima pos del texto+1
	    lea esi,[text+eax]					;desde la ultima pos del texto
	    rep movsb							;repito ese movimiento
        inc byte[top]
	endSubR 4


;call:
	;push dword start: ebp + 4
	;call text.move
text.movebackward:
	startSubR
	mov eax, [ebp+4]						;eax = pos a partir de la cual voy a copiar
	dec eax	

	cmp eax, 0								;si estoy en el primer caracter
	jl .end									;entonces no borro

	mov dl, [text+eax]
	push edx								;guardo el caracter que voy a borrar para analizarlo luego
	lea edi, [text+eax]						;mi destino es la posicion actual						
	lea esi, [text+eax+1]					;mi origen es la posicion actual mas 1

	cld								
	mov ecx, [top]
	sub ecx, eax							;calculo las veces que voy a moverme: el tamano del text-pos
	cmp ecx, 1								;si estoy en la posicion final del texto
	jbe .end								;entonces no borro
	rep movsb 								;voy moviendo las palabras
	
	dec dword[cursor]						;decremento la posicion del cursor
	dec dword[top]				        	;decremento el tamano del texto
    .end:
	endSubR 4
