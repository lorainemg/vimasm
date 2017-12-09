%include "keys.mac"
%include "tools.mac"

;keyboard externs
	extern isKey1,isKey2,isKey3, getChar 


;text externs
	extern cursor.moveH, cursor.moveV
	extern text.insert,text.newline
	extern lastline
	extern text


;main externs
	extern vim.update,UpdateBuffer
	
section .text


global mode.insert 
mode.insert:

		call getChar				;obtiene el caracter de la tecla que se presiono
		cmp ax, 0 					;si no se presiona ninguna tecla
		je .commad					;entonces se salta hasta el final

		push eax					;se guarda el caracter en la pila como parametro de text.write
		call text.insert				;se procede a escribir el caracter en el texto	call UpdateBuffer
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
		checkKey1 key.esc, .exitmode 	

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
			jmp .end
	
		.backspace:
		;Logica del backspace
			jmp .end
	
		.enter:
		;Logica del enter

			jmp .end
	
		.exitmode:
		;Logica para salir del modo
			jmp .end

	.end:
	;Update
	call UpdateBuffer
	.end2:
	call vim.update

	jmp mode.insert
	ret