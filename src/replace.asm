%include "keys.mac"
%include "tools.mac"

;keyboard externs
	extern isKey1,isKey2,isKey3, getChar 

;text externs
	extern cursor.moveH, cursor.moveV, cursor
	extern text.replace,text.newline, lines.endline
	extern lastline, lines, lines.current
	extern text

;main externs
	extern vim.update,UpdateBuffer

section .text
global mode.replace 
mode.replace:
		call getChar				;obtiene el caracter de la tecla que se presiono
		cmp ax, 0 					;si no se presiona ninguna tecla
		je .commad					;entonces se salta hasta el final
		
		; cmp eax, 0x0d
		; je .enter
		; cmp eax, ASCII.tab
		; je .tab

		push eax					;se guarda el caracter en la pila como parametro de text.write
		call text.replace
		jmp .end                    

	.commad:

	;Para comprobar las teclas de movimientos
		checkKey1 key.left,  .moveleft			;Comprueba si se presiono la tecla izq 
		checkKey1 key.right, .moveright			;Comprueba si se presiono la tecla der 
		checkKey1 key.up, 	 .moveup			;Comprueba si se presiono la tecla arriba 
		checkKey1 key.down,  .movedown			;Comprueba si se presiono la tecla abajo 
	
	;para comprobar acciones especiales
		checkKey1 key.tab, 		 .tab 			;Comprueba si se presiono tab
		checkKey1 key.backspace, .backspace 	;Comprueba si se presiono backspace
		checkKey1 key.enter, 	 .enter 		;Comprueba si se presiono enter

	;commandos especiales
		checkKey1 key.esc, .exitmode 	        ;Si se presiono escape

	jmp .end2
	;movimientos del cursor

		.moveright:					;mueve el cursor a la derecha
			push dword 1
			call cursor.moveH			
			jmp .end
	
		.moveleft:					;mueve el cursor a la izquierda
			push dword -1
			call cursor.moveH
			jmp .end
	
		.moveup:					;mueve el cursor hacia arriba
			push dword -1
			call cursor.moveV
			jmp .end
	
		.movedown:					;mueve el cursor para abajo
			push dword 1
			call cursor.moveV
			jmp .end
	
	;acciones especiales

		.tab:
		;Logica de tab
			push dword ASCII.tab
			call text.replace
			jmp .end
	
		.backspace:
			call backspace
			jmp .end			
	
		.enter:
		;Logica del enter
			push dword[cursor]
			call text.newline	
			jmp .end    
	
		.exitmode:
		;Logica para salir del modo
			jmp .end

	.end:
	;Update
	call UpdateBuffer
	.end2:
	call vim.update

	jmp mode.replace
	ret

;Logica para ejecutar backspace
;call:
;call backspace
backspace:
startSubR
	cmp dword[cursor], 0				;si el cursor esta en la primera posicion, no me muevo
	je .end					
	mov eax, [cursor]					;eax = posicion del cursor
	dec dword[cursor]					;decremento el cursor
	mov dl, 80							;bl = 80 (para dividir)
	div dl								;divido pos del cursor con 80
	cmp ah, 0							;el resto es 0?
	jne .end							;si no lo es, entonces ya termino
	mov eax, [lines.current]			;de serlo, entonces hago eax = linea actual
	dec eax								;busco la linea anterior a la actual
	push eax							;la pongo como parametro
	call lines.endline					;y pregunto su fin de linea
	mov [cursor], eax					;actualizo el cursor, para que se ponga en el fin de linea de la palabra
	dec dword[lines.current]			;decremento la linea actual
	.end:
endSubR 0