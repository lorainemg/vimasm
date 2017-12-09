%include "tools.mac"
%include "keys.mac"

;keyboad externs
extern isKey1,isKey2,isKey3, getChar 
;text externs
extern cursor.moveH, cursor.moveV, select.start
;main externs
extern vim.update, video.Update

section .data
mode db 0

section .text
;call:
;push dword <mode> (0 normal, 1 linea, 2 bloque) 
global start.visual
start.visual:
startSubR
    mov eax, [ebp+4]
    push eax
    call select.start
endSubR 4

global mode.visual
mode.visual:
startSubR
    checkKey1 key.esc, .exit

    checkKey1 key.y, .copy

    ;Si se movio alguna tecla de movimiento
	checkKey1 key.left,  .moveleft			;Comprueba si se presiono la tecla izq 
	checkKey1 key.right, .moveright			;Comprueba si se presiono la tecla der 
	checkKey1 key.up, 	 .moveup			;Comprueba si se presiono la tecla arriba 
	checkKey1 key.down,  .movedown			;Comprueba si se presiono la tecla abajo 
    
    ;Operadores de movimiento
    checkKey1 key.4, .endline    
    checkKey1 key.6, .startline
    checkKey1 key.w, .endword

    jmp .end2

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
    .copy:
    ;Logica para copiar text
    jmp .end

    .endline:
    ;Selecciona hasta el final de la linea
    jmp .end
    .startline:
    ;Selecciona hasta el inicio de linea
    jmp .end
    .endword:
    ;Selecciona hasta el final de palabra
    jmp .end

    .exit:
    ;Logica para salir del modo
 
	.end:
	;Update
	call video.Update
	
    .end2:
	call vim.update
    jmp mode.visual
endSubR 0