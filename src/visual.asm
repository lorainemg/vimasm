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
    mov [mode], eax
endSubR 4


global mode.visual
mode.visual:
startSubR
    checkKey1 key.esc, .exit

    checkKey1 key.y, .copy

    ;Si se movio alguna tecla de movimiento
    checkKey1 key.up,    .select
    checkKey1 key.down,  .select
    checkKey1 key.left,  .select
    checkKey1 key.right, .select
    
    ;Operadores de movimiento
    checkKey1 key.4, .endline    
    checkKey1 key.6, .startline
    checkKey1 key.w, .endword

    .exit:
    ;Logica para salir del modo
    jmp .end

   .select:
    ;Para ver el modo en que se entra
    mov al, [mode]
    cmp al, 0
    je .normal
    cmp al, 1
    je .line
    cmp al, 2
    je .block
    jmp .end

    .normal:
    ;Logica para seleccionar en modo normal
    jmp .end
    .line:
    ;Logica para seleccionar en modo linea
    jmp .end
    .block:
    ;Logica para seleccionar en modo bloque
    jmp .end

    .copy:
    ;Logica para copiar text
    jmp .end

    .endline:
    ;Se mueve hasta el final de la linea
    jmp .end
    .startline:
    ;Se mueve hasta el inicio de linea
    jmp .end
    .endword:
    ;Se mueve hasta el final de palabra
    jmp .end

.end
endSubR 0