%include "keys.mac"
%include "tools.mac"

;keyboad externs
extern isKey1,isKey2,isKey3, isNum, getChar
;text externs
extern cursor.moveH, cursor.moveV, cursor.moveline, cursor
extern lines.last, lines.endword, lines.current
extern select.copy.normal, copy.line
;modes externs
extern mode.insert, mode.replace, mode.visual, start.visual, select.paste
;main externs
extern vim.update, video.Update, videoflags

section .data
lastkey db 0

section .text

global mode.normal
mode.normal:
	;Controles de movimiento:
		checkKey1 key.left,  .moveleft			;si se presiono la tecla izq 
		checkKey1 key.right, .moveright			;si se presiono la tecla der 
		checkKey1 key.up, 	 .moveup			;si se presiono la tecla arriba 
		checkKey1 key.down,  .movedown			;si se presiono la tecla abajo 
	

	;Controles basicos
		checkKey1 key.p, .paste					;si se presiono p
		
	;Cambiar de modo:
		checkKey1 key.i, .insertmode			;si se presiono i
		checkKey2 key.shiftL, key.v, .visualLinemode	;si se presiono shift+v
		checkKey1 key.v, .visualmode 			;si se presiono v
	

	;Optativos:
		checkKey2 key.ctrl, key.v, .visualBlockmode	;si se presiono ctrl+v
		checkKey1 key.r, .replacemode			;si se presiono r


	;Controles optativos:
		checkKey1 key.u, .undo					;si se presiono u
		checkKey1 key.point, .point				;si se presiono .

	;Moverse por el fichero:
		checkKey2 key.shiftL, key.g, .goLine	;si se presiono shift+g
		checkKey1 key.g, .goStart				;si se presiono 2 vecer g

	;TODO: Faltan los operadores + repeticiones + movimiento
	;Operadores:
		checkKey1 key.y, .copy
		checkKey1 key.d, .erase
		checkKey1 key.c, .replace
	;Operadores de movimiento
    	checkKey1 key.4, .endline    
    	checkKey1 key.6, .startline
    	checkKey1 key.w, .endword

		checknum .num

			jmp .end
	;##########################################################################################################################################################
	;##########################################################################################################################################################


	;Comandos de movimientos:
		.moveright:					;mueve el cursor a la derecha
			mov byte[lastkey], 0
			push dword 1
			call cursor.moveH			
			jmp .end
		.moveleft:					;mueve el cursor a la izquierda
			mov byte[lastkey], 0
			push dword -1
			call cursor.moveH
			jmp .end
		.moveup:					;mueve el cursor hacia arriba
			mov byte[lastkey], 0
			push dword -1
			call cursor.moveV
			jmp .end
		.movedown:					;mueve el cursor para abajo
			mov byte[lastkey], 0
			push dword 1
			call cursor.moveV
			jmp .end

	;Cambiar de modo:
		.insertmode:
		;Logica para cambiar al modo insertar
			mov byte[lastkey], 0
			call mode.insert
			jmp .end
		.visualmode:
		;Logica para cambiar al modo visual con seleccion estandar
			mov byte[lastkey], 0
			push dword 0
			call start.visual
			call mode.visual
			jmp .end
		.visualLinemode:
		;Logica para cambiar al modo visual con seleccion en modo linea
			mov byte[lastkey], 0
			push dword 1
			call start.visual
			call mode.visual
			jmp .end
		.visualBlockmode:
		;Logica para cambiar al modo visual con seleccion en modo bloque
			mov byte[lastkey], 0
			push dword 2
			call start.visual
			call mode.visual
			jmp .end
		.replacemode:
		;Logica para cambiar al modo reemplazar
			mov byte[lastkey], 0
			call mode.replace
			jmp .end

	;Comandos especiales:
		.paste:						
		;Logica para pegar
			mov byte[lastkey], 0
			call select.paste
			jmp .end
		.undo:						
		;Logica para deshacer una accion
			mov byte[lastkey], 0
			jmp .end
		.goStart:
		;Logica para ir al pricipio del text
			cmp byte[lastkey], 'g'			;el ultimo caracter presionado fue 'g'?
			jne .no							;si no lo fue, entonces no realizo ninguna accion
			push dword 0					;si lo fue:
			call cursor.moveline			;muevo el cursor hacia el inicio de la preimera linea
			mov byte[lastkey], 0			;reestablezco el valor de la ultima tecla en 0
			.no:
			mov byte[lastkey], 'g'			;si no hice ninguna accion, entonces pongo como caracter de mi ultima tecla g
			jmp	.end
		.goLine:
		;Logica para ir hacia una linea del text del text
			inRange 48, 57, [lastkey]		;para moverme en una linea en especifica:
			cmp eax, 0						;el valor de la ultima tecla es un numero? 
			je .goEnd						;si no lo es, entonces simplemente voy al final del textos
			xor eax, eax					
			mov al, [lastkey]				;sino, cojo el valor de la ultima tecla y dependiendo de su valor
			sub al, 49						;hago operaciones para convertirlo de ASCII a numero
			push eax
			call cursor.moveline			;y muevo el cursor en el principio de esa linea
			mov byte[lastkey], 0			;desactualizo el valor de la ultima tecla
			jmp .end
			.goEnd:
			push dword[lines.last]			;para ir al final del texto:
			call cursor.moveline			;pongo el cursor en el primer caracter de la primera linea
			mov byte[lastkey], 0			;desactualizo el valor de la ultima tecla
			jmp .end
		.point:
		;Logica para el comando punto
			jmp .end

		.copy:
		;Logica para copiar con repeticion + operadores de movimiento
			cmp byte[lastkey], 'y'
			je .copyline
			mov byte[lastkey], 'y'
			jmp .end
			.copyline:
				inRange 48, 57, byte[lastkey+1]		;hay un numero en lastkey?
				cmp eax, 0						;el valor de la ultima tecla es un numero? 
				je .start						;si no lo es, entonces simplemente voy al final del textos
				xor eax, eax
				mov al, [lastkey+1]
				sub eax, 48
				.start:
				push eax
				push dword 1
				call copy
			jmp .end
		.erase:
		;Logica para borrar con repeticion + operadores de movimiento
			mov byte[lastkey], 'e'
			jmp .end
		.replace:
		;Logica para reemplazar con repeticion + operadores de movimiento
			mov byte[lastkey], 'r'
		 	jmp .end

		.endline:
		;Logica para realizar la operacion hasta el final de una linea
			jmp .end  
		.startline:
		;Logica para realizar la operacion hacia el inicio de una linea
			jmp .end
		.endword:
		;Logica para realizar la operacion hacia el final de una linea
			xor ebx, ebx
			mov bl, [lastkey]
			cmp byte[lastkey], 'y'
			je .yank
			.yank:
				inRange 48, 57, byte[lastkey+1]		;hay un numero en lastkey?
				cmp eax, 0						;el valor de la ultima tecla es un numero? 
				je .starty						;si no lo es, entonces simplemente voy al final del textos
				xor eax, eax
				mov al, [lastkey+1]
				sub eax, 48
				.starty:
				push eax
				push dword 0
				call copy
			jmp .end

		.num:
		;Control intermedio para decidir que se hace cuando se presiona un numero
			cmp byte[lastkey], 'y'			;si no se a presionado ninguna tecla
			je .tryop						;se guarda el valor del numero en la tecla actual
			cmp byte[lastkey], 'c'
			je .tryop
			cmp byte[lastkey], 'd'
			je .tryop
			mov byte[lastkey], al			;para los movimientos por el fichero
			jmp .end
			.tryop:							;si no, es una operacion lo que esta en lastkey
			mov byte[lastkey+1], al			;se deja la operacion en el primer byte, y en el segundo se pone el numero
			xor ebx, ebx
			mov bl, byte[lastkey+1]
			jmp .end

	.end:
	;Update
	or byte[videoflags], 1 << 1
	call video.Update
	.end2:
	call vim.update
	jmp mode.normal
ret

;Copia 
;call:
;push dword times: ebp + 8
;push dword mode: ebp + 4	(0 palabra, 1 linea)
copy:
	startSubR
		mov ecx, [ebp+8]
		mov eax, [ebp+4]
		cmp eax, 1
		je .modeline
		mov eax, [cursor]
		cmp ecx, 0
		jne .lp1
		inc ecx
	.lp1:							;para copiar varias palabras calculo el total de cuato me voy a mover:
		push eax					;pongo la posicion en la que estoy ahora como parametro
		call lines.endword			;y pregunto por la posicion final de esa palabra, eax se va incrementando
		inc eax
		loop .lp1					;VER: a lo mejor hay que incrementar el valor de eax
		dec eax
		push eax					;pongo la pos final de la palabra como parametro
		push dword[cursor]			;pongo la pos inicial como parametro
		call select.copy.normal		;copio desde mi posicion hasta el final de la palabra
		jmp .end
	.modeline:						;Para copiar en modo linea:
		mov eax, [lines.current]	;eax = linea actual
		mov edx, eax				
		add edx, ecx				;edx = linea actual + cantidad de veces que se repite la accion
		dec edx
		push edx					;el final de la copia sera edx
		push eax					;el inicio eax
		call copy.line				;y llamo para copiar
	.end:
	endSubR 8
