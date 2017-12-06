%include "keys.mac"

extern isKey1,isKey2,isKey3, getChar 
extern cursor.moveH, cursor.moveV
extern UpdateBuffer
extern text.write

;Comprueba si se presiono una tecla, y si se hizo, intonces salta para la etiqueta especificada
;checkKey(tecla, etiqueta)
%macro checkKey 2
	mov eax, %1							;pone en eax la tecla 
	push eax							;pasa el codigo scan de la tecla como parametro
	call isKey1							;llama para comprobar si se presiono la tecla
	cmp eax, 1							;si se presiono
	je %2								;entonces salta para la etiqueta especificada
%endmacro


section .text

global checkKeyboardStatus 
checkKeyboardStatus:
	call getChar				;obtiene el caracter de la tecla que se presiono
	cmp ax,0 					;si no se presiona ninguna tecla
	je .commad					;entonces se salta hasta el final
	push eax					;se guarda el caracter en la pila como parametro de text.write
	call text.write				;se procede a escribir el caracter en el texto
	call UpdateBuffer
	jmp .end					;entonces, se salta hasta el final
	.commad:

	;Para comprobar las teclas de movimientos
	checkKey key.left, .moveleft			;Comprueba si se presiono la tecla izq 
	checkKey key.right, .moveright			;Comprueba si se presiono la tecla der 
	checkKey key.up, .moveup				;Comprueba si se presiono la tecla arriba 
	checkKey key.down, .movedown			;Comprueba si se presiono la tecla abajo 
	
	;checkKey key.tab, .tab 
	
	
	.moveright:
	push dword 1
	call cursor.moveH
	jmp .cont
	.moveleft:
	push dword -1
	call cursor.moveH
	jmp .cont
	.moveup:
	push dword -1
	call cursor.moveV
	jmp .cont
	.movedown:
	push dword 1
	call cursor.moveV
	jmp .cont

	.cont:
	call UpdateBuffer
	.end:
	ret