%include "keys.mac"
%include "tools.mac"


extern isKey1,isKey2,isKey3, getChar 
extern cursor.moveH, cursor.moveV
extern UpdateBuffer
extern text.write
extern text

section .text

global mode.insert 
mode.insert:
	call getChar				;obtiene el caracter de la tecla que se presiono
	cmp ax, 0 					;si no se presiona ninguna tecla
	je .commad					;entonces se salta hasta el final
	.cont3:
	push eax					;se guarda el caracter en la pila como parametro de text.write
	call text.write				;se procede a escribir el caracter en el texto	call UpdateBuffer
	jmp .cont
	.commad:

	;Para comprobar las teclas de movimientos
	checkKey1 key.left,  .moveleft			;Comprueba si se presiono la tecla izq 
	checkKey1 key.right, .moveright			;Comprueba si se presiono la tecla der 
	checkKey1 key.up, 	 .moveup			;Comprueba si se presiono la tecla arriba 
	checkKey1 key.down,  .movedown			;Comprueba si se presiono la tecla abajo 
	
	checkKey1 key.tab, 		 .tab 			;Comprueba si se presiono tab
	checkKey1 key.backspace, .backspace 	;Comprueba si se presiono backspace
	checkKey1 key.enter, 	 .enter 		;Comprueba si se presiono enter

	checkKey1 key.esc, .exitmode 	

	jmp .end

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
	
	.tab:
	;Logica de tab
	jmp .cont
	.backspace:
	;Logica del backspace
	jmp .cont
	.enter:
	;Logica del enter
	jmp .cont

	.exitmode:
	;Logica para salir del modo
	jmp .cont

	.cont:
	call UpdateBuffer
	.end:
	ret