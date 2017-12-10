%include "keys.mac"
%include "tools.mac"

;keyboad externs
extern isKey1,isKey2,isKey3, isNum, getChar
;text externs
extern cursor.moveH, cursor.moveV, cursor.moveline, lines.last
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
		checknum .num
		;TODO: Funcion especial para ver si se presiono un # y shift+g, en cuyo caso va a la linea especificada


	;TODO: Faltan los operadores + repeticiones + movimiento
	

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

		.num:
		;Control intermedio para decidir que se hace cuando se presiona un numero
			cmp byte[lastkey], 0
			jne .tryop
			mov byte[lastkey], al
			jmp .end
			.tryop:
			jmp .end

	.end:
	;Update
	or byte[videoflags], 1 << 1
	call video.Update
	.end2:
	call vim.update
	jmp mode.normal
	ret