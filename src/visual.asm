%include "tools.mac"
%include "keys.mac"

;keyboad externs
extern isKey1,isKey2,isKey3, getChar 
;text externs
extern cursor, cursor.moveH, cursor.moveV, select.mark, select.copy, select.changemode
;tratamiento de lineas:
extern lines.startsline, lines.endline, lines.endword, lines.current
;main externs
extern vim.update, video.Update, videoflags

section .text
;call:
;push dword <mode> (0 normal, 1 linea, 2 bloque) 
global start.visual
start.visual:
startSubR
    mov eax, [ebp+4]
    push eax
    call select.mark
    xor byte[videoflags], 1<< 1
endSubR 4

global mode.visual
mode.visual:
    checkKey1 key.esc, .exit
    checkKey1 key.y, .copy

    ;Si se movio alguna tecla de movimiento
	checkKey1 key.left,  .moveleft			;Comprueba si se presiono la tecla izq 
	checkKey1 key.right, .moveright			;Comprueba si se presiono la tecla der 
	checkKey1 key.up, 	 .moveup			;Comprueba si se presiono la tecla arriba 
	checkKey1 key.down,  .movedown			;Comprueba si se presiono la tecla abajo 
    
    ;Operadores de movimiento
    checkKey2 key.shiftL, key.4, .endline    
    checkKey2 key.shiftL, key.6, .startline
    checkKey1 key.w, .endword

    ;Cambiar de modo dentro del modo visual
	checkKey2 key.shiftL, key.v, .visualLinemode	;si se presiono shift+v
	checkKey2 key.ctrl, key.v, .visualBlockmode	;si se presiono ctrl+v
	checkKey1 key.v, .visualmode 			;si se presiono v

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
        call select.copy
    jmp .end

	.visualmode:
	;Logica para cambiar al modo visual con seleccion estandar
		push dword 0
		call select.changemode
		jmp .end
	.visualLinemode:
	;Logica para cambiar al modo visual con seleccion en modo linea
		push dword 1
		call select.changemode
		jmp .end
	.visualBlockmode:
	;Logica para cambiar al modo visual con seleccion en modo bloque
		push dword 2
		call select.changemode
		jmp .end

    .endline:
    ;Selecciona hasta el final de la linea
        push dword[lines.current]
        call lines.endline
        dec eax
        mov [cursor], eax
    jmp .end
    
    .startline:
    ;Selecciona hasta el inicio de linea
        push dword[lines.current]
        call lines.startsline
        mov [cursor], eax
    jmp .end
    
    .endword:
    ;Selecciona hasta el final de palabra
        push dword[cursor]
        call lines.endword
        mov [cursor], eax
    jmp .end

    .exit:
       jmp .finish
    ;Logica para salir del modo
    
	.end:
	;Update
	call video.Update
	
    .end2:
	call vim.update
    jmp mode.visual
    .finish:
ret