%include "keys.mac"
%include "tools.mac"

;keyboard externs
	extern isKey1,isKey2, getChar 


;text externs
	extern cursor.moveH, cursor.moveV, cursor
	extern text.insert,lines.newline
<<<<<<< HEAD
	extern erasetimes, eraseline
	extern text, text.movebackward, text.moveforward, text.save
=======
	extern lines.current, lines.startsline, erasetimes, eraseline
	extern text, text.movebackward, text.moveforward,pRecord.mode
>>>>>>> b504b19da25a6630769fd8b14a679c4e72993e69


;main externs
	extern vim.update,video.Update,cursor.blink,cursor.noblink

section .bss
global record
record	resb  400		;graba las palabras que se escriben

section .data
start dd 0

global count
count dd 0				;lleva la cuenta de cuantas palabras se han escrito
global save
save db	0				;determina cuando empezar a guardar las palabras que se escriben

section .text

global mode.insert 
mode.insert:

	;Borrando usando operadores de movimiento:
		checkKey2 key.ctrl, key.h, .backspace		;Si se presiona ctrl+h
		checkKey2 key.ctrl, key.w, .eraseword		;Si se presiona ctrl+w
		checkKey2 key.ctrl, key.u, .erasestartline	;Si se presiona ctrl+u

		cmp dword[start], 0
		je .end2
		call cursor.blink
	;Veo si escribo una palabra
		call getChar				;obtiene el caracter de la tecla que se presiono
		cmp ax, 0 					;si no se presiona ninguna tecla
		je .commad					;entonces se salta hasta el final
		
		cmp byte[save], 0
		je .noRecord
		mov edx, [count]
		mov [record+edx], al
		inc dword[count]
		
		.noRecord:
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
			mov dword[save], 0
			push dword 1
			call cursor.moveH			
			jmp .end
	
		.moveleft:					;mueve el cursor a la izquierda
			mov dword[save], 0
			push dword -1
			call cursor.moveH
			jmp .end
	
		.moveup:					;mueve el cursor hacia arriba
			mov dword[save], 0
			push dword -1
			call cursor.moveV
			jmp .end
	
		.movedown:					;mueve el cursor para abajo
			mov dword[save], 0
			push dword 1
			call cursor.moveV
			jmp .end
	
	;acciones especiales

		.tab:
		;Logica de tab
			mov dword[save], 0
			push dword ASCII.tab		;inserta un tab en la posicion actual del texto
			call text.insert
			jmp .end
	
		.backspace:
		;Logica del backspace
			mov dword[save], 0
			push dword[cursor]			;para borrar mueve el texto hacia la izq desde la posicion del cursor
			call text.movebackward
			jmp .end
	
		.enter:
		;Logica del enter
			mov dword[save], 0
			call lines.newline			;para presionar enter crea una nueva linea
			jmp .end
	
		.eraseword:
		;Logica para borrar una palabra. Borra desde la posicion del cursor en adelante
			mov dword[save], 0
			call eraseword		
			call text.save
			jmp .end

		.erasestartline:
		;Logica para borrar hasta el inicio de linea
			mov dword[save], 0
			call eraseline
			call text.save
			jmp .end

		.exitmode:
		;Logica para salir del modo
			mov dword[save], 0
			mov dword[start], 0

			call text.save
			ret
			jmp .end
	.end:
	;Update
	call cursor.noblink
	call video.Update
	.end2:
	call vim.update
	mov dword[start], 1
	jmp mode.insert
ret

;Borra desde el cursor hasta el principio de una palabra
eraseword:
	startSubR
		mov eax, [cursor]				;eax = cursor
		lea esi, [text+eax]				;el origen seria desde la posicion del cursor en el texto
		xor ecx, ecx					;cuento en ecx la cantidad de char q tengo q borrar para llegar al pricipio de palabra 						
		std
		.lp:
			lodsb						;al = lo que esta actualmente en el texto
			cmp esi, text				;si llegue al principio del texto, termino actualizando los valores de ecx
			je .fix
			cmp al, ' '					;si es el principio de una palabra termino
			je .end
			cmp al, ASCII.enter			;si el char es una nueva linea termino
			je .end
			cmp al, ASCII.tab			;se es un tab tambien termino
			je .end
			inc ecx						;incremento el contador
			jmp .lp
		.end:							;Arreglo los valores de ecx en ambos casos
		dec ecx
		jmp .erase
		.fix:
			inc ecx
		.erase:							;y empiezo a borrar tantas veces como las calculadas
		push ecx
		call erasetimes
	endSubR 0