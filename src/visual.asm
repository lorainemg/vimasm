%include "tools.mac"
%include "keys.mac"

;keyboad externs
extern isKey1,isKey2,isKey3, getChar 
;text externs
extern cursor.moveH, cursor.moveV
;main externs
extern vim.update

section .data
mode db 0

section .text
;call:
;push dword <mode> (0 normal, 1 linea, 2 bloque) 
global start.visual
start.visual:
startSubR
    mov eax, [ebp+4]
    ; mov [mode], eax
    push eax
    ;Llamar para empezar la seleccion
endSubR 4

global mode.visual
mode.visual:
startSubR
    checkKey1 key.esc, .exit

    checkKey1 key.y, .copy

    ;Si se movio alguna tecla de movimiento
    checkKey1 key.up,    .selectUp
    checkKey1 key.down,  .selectDown
    checkKey1 key.left,  .selectLeft
    checkKey1 key.right, .selectRight
    
    ;Operadores de movimiento
    checkKey1 key.4, .endline    
    checkKey1 key.6, .startline
    checkKey1 key.w, .endword

    jmp .end2

   .selectUp:
    ;Logica para seleccionar moviendo el cursor arriba
    jmp .end

    .selectDown:
    ;Logica para seleccionar moviendo el cursor hacia abajo
    jmp .end

    .selectLeft:
    ;Logica para seleccionar moviendo el cursor hacia la izq
    jmp .end

    .selectRight:
    ;Logica para seleccionar moviendo el cursor hacia la derecha
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