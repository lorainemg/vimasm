%include "keys.mac"
%include "tools.mac"

;keyboad externs
extern isKey1,isKey2,isKey3, getChar 
;text externs
extern cursor.moveH, cursor.moveV
;main externs
extern vim.update


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
		checkKey1 key.v, .visualmode 			;si se presiono v
		checkKey2 key.shiftL, key.v, .visualLinemode	;si se presiono shift+v
	

	;Optativos:
		checkKey2 key.ctrl, key.v, .visualBlockmode	;si se presiono ctrl+v
		checkKey1 key.r, .replacemode			;si se presiono r


	;Controles optativos:
		checkKey1 key.u, .undo					;si se presiono u
		checkKey1 key.point, .point				;si se presiono .


	;TODO: Ver si se presiona g 2 veces consecutivas
		checkKey1 key.g, .goStart				;si se presiono 2 vecer g
		checkKey2 key.shiftL, key.g, .goEnd		;si se presiono shift+g

	
	;TODO: Funcion especial para ver si se presiono un # y shift+g, en cuyo caso va a la linea especificada


	;TODO: Faltan los operadores + repeticiones + movimiento
	

			jmp .end


	;##########################################################################################################################################################
	;##########################################################################################################################################################



	;Comandos de movimientos:
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



	;Cambiar de modo:
		.insertmode:
		;Logica para cambiar al modo insertar
			jmp .end
		.visualmode:
		;Logica para cambiar al modo visual con seleccion estandar
			jmp .end
		.visualLinemode:
		;Logica para cambiar al modo visual con seleccion en modo linea
			jmp .end
		.visualBlockmode:
		;Logica para cambiar al modo visual con seleccion en modo bloque
			jmp .end
		.replacemode:
		;Logica para cambiar al modo reemplazar
			jmp .end



	;Comandos especiales:
		.paste:						
		;Logica para pegar
			jmp .end
		.undo:						
		;Logica para deshacer una accion
			jmp .end
		.goStart:
		;Logica para ir al pricipio del text
			jmp	.end
		.goEnd:
		;Logica para ir al final del text
			jmp .end
		.point:
		;Logica para el comando punto
			jmp .end



	.end:
	;Update
	call vim.update
	ret