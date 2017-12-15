%include "tools.mac"
%include "keys.mac"

extern getChar, checkKey1, isKey1
extern video.Update
extern text.find

section .bss
text 	resb 80
search 	resb 80

section .data
cursor 		dd 0
top 		dd 0

section .text
global start.command
start.command:
    startSubR
        inc dword[top]
        mov byte[text], ':'
    endSubR 0


global mode.command
mode.command:
    	;Veo si escribo una palabra
		call getChar				;obtiene el caracter de la tecla que se presiono
		cmp ax, 0 					;si no se presiona ninguna tecla
		je .command				    ;entonces se salta hasta el final

		push eax				    ;se guarda el caracter en la pila como parametro de text.write
		call text.insert	        ;se procede a escribir el caracter en el texto	call UpdateBuffer
		jmp .end

        .command:
        ;Otros  comandos:
        checkKey1 key.backspace, .erase
		checkKey1 key.enter, 	 .enter 		;Comprueba si se presiono enter
		checkKey1 key.esc,       .exitmode 	

        jmp .end2
        ;---------------------------------------------------------------------------------------------------
        .erase:
        ;Logica para borrar
		push dword[cursor]			;para borrar mueve el texto hacia la izq desde la posicion del cursor
		call text.movebackward
		jmp .end        
        .enter:
        ;Logica para presionar enter
        call searchCmd
		ret
        ;Busca un comando valido, si lo es, lo ejecuta, si no emite un mensaje de comando no valido
        ;Despues sale a modo normal
        jmp .end
        .exitmode:
        call text.erase
        ret

    .end:
    call video.Update
    .end2:
    jmp mode.command
ret

;Para borrar lo que esta guardado en el text del modo comando
;call:
;call text.erase
text.erase:
    startSubR
        mov ecx, [top]          ;la cantidad de movimientos es la cantidad de caracteres insertados
        mov edi, text           ;mi destino es el texto
        mov al, 0               ;en al pongo 0
        rep stosb               ;y repito ese movimiento las veces calculadas
        mov dword[top], 0       ;el tope es ahora 0
        mov dword[cursor], 0    ;y el cursor esta en la posicion 0
    endSubR 0


;call:
;push dword ascii: ebp + 4
;call text.insert
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
        inc dword[top]
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

searchCmd:
    startSubR
        cmp byte[text+1], '/'
        jne .end
        call find
        .end:
    endSubR 0

find:
    startSubR
        lea esi, [text+2]
        mov edi, search
        mov ecx, [top]
        sub ecx, 2
		mov eax, ecx
		rep movsb
		push eax
		push search
		call text.find  
    endSubR 0