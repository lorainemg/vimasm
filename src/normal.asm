%include "keys.mac"
%include "tools.mac"

extern isKey1,isKey2,isKey3, getChar 
extern cursor.moveH, cursor.moveV
extern UpdateBuffer

section .text
global mode.normal
mode.normal:
	
	;Controles de movimiento:
	checkKey1 key.left,  .moveleft			;si se presiono la tecla izq 
	checkKey1 key.right, .moveright			;si se presiono la tecla der 
	checkKey1 key.up, 	 .moveup			;si se presiono la tecla arriba 
	checkKey1 key.down,  .movedown			;si se presiono la tecla abajo 
	
	checkKey1 key.p, .paste					;si se presiono p
	
	;Cambiar de modo:
	checkKey1 key.i, .insertmode			;si se presiono i
	checkKey1 key.v, .visualmode 			;si se presiono v
	checkKey2 key.shiftL, key.v, .visualLinemode	;si se presiono shift+v
	;optativos:
	checkKey2 key.ctrl, key.v, .visualBlockmode	;si se presiono ctrl+v
	checkKey1 key.r, .replacemode			;si se presiono r

	; Controles optativos:
	checkKey1 key.u, .undo					;si se presiono u
	checkKey1 key.point, .point				;si se presiono .

	;TODO: Ver si se presiona g 2 veces consecutivas
	checkKey1 key.g, .goStart				;si se presiono 2 vecer g
	checkKey2 key.shiftL, key.g, .goEnd		;si se presiono shift+g
	;TODO: Funcion especial para ver si se presiono un # y shift+g, en cuyo caso va a la linea especificada

	;TODO: Faltan los operadores + repeticiones + movimiento
	jmp .end

	;Comandos de movimientos:
	.moveright:					;mueve el cursor a la derecha
	push dword 1
	call cursor.moveH			
	jmp .cont
	.moveleft:					;mueve el cursor a la izquierda
	push dword -1
	call cursor.moveH
	jmp .cont
	.moveup:					;mueve el cursor hacia arriba
	push dword -1
	call cursor.moveV
	jmp .cont
	.movedown:					;mueve el cursor para abajo
	push dword 1
	call cursor.moveV
	jmp .cont

	;Cambiar de modo:
	.insertmode:
	;Logica para cambiar al modo insertar
	jmp .cont
	.visualmode:
	;Logica para cambiar al modo visual con seleccion estandar
	jmp .cont
	.visualLinemode:
	;Logica para cambiar al modo visual con seleccion en modo linea
	jmp .cont
	.visualBlockmode:
	;Logica para cambiar al modo visual con seleccion en modo bloque
	jmp .cont
	.replacemode:
	;Logica para cambiar al modo reemplazar
	jmp .cont

	;Comandos especiales:
	.paste:						
	;Logica para pegar
	jmp .cont
	.undo:						
	;Logica para deshacer una accion
	jmp .cont
	.goStart:
	;Logica para ir al pricipio del text
	jmp	.cont
	.goEnd:
	;Logica para ir al final del text
	jmp .cont
	.point:
	;Logica para el comando punto
	jmp .cont


	.cont:
	call UpdateBuffer
	.end:
ret