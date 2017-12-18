%include "tools.mac"
%include "keys.mac"

;keyboad externs
extern isKey1,isKey2, getChar 
;text externs
extern cursor, cursor.moveH, cursor.moveV, select.mark, select.copy, select.changemode
extern save, mode.insert, select.movestart, record, count
;tratamiento de lineas:
extern lines.startsline, lines.endline, lines.endword, lines.current, block.insert, select.start
;main externs
extern vim.update, video.Update, videoflags, cursor.blink, cursor.noblink

section .data
mode dd 0       ;para guardar el modo de seleccion (0 normal, 1 linea, 2 bloque)

section .text
;call:
;push dword <mode> (0 normal, 1 linea, 2 bloque) 
global start.visual
start.visual:
startSubR
    mov eax, [ebp+4]
    mov [mode], eax
    push eax
    call select.mark
    and byte[videoflags], ~1<< 1
endSubR 4

global mode.visual
mode.visual:
    call cursor.blink
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

    checkKey2 key.shiftL, key.i, .insert

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
        mov dword[mode], 0
		push dword 0
		call select.changemode
		jmp .end
	.visualLinemode:
	;Logica para cambiar al modo visual con seleccion en modo linea
		mov dword[mode], 1
        push dword 1
		call select.changemode
		jmp .end
	.visualBlockmode:
	;Logica para cambiar al modo visual con seleccion en modo bloque
		mov dword[mode], 2
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

    .insert:
    ;Para entrar en la insercion en modo bloque
        cmp dword[mode], 2              ;si no se esta en modo bloque, entonces no se hace nada
        jne .end

       	or byte[videoflags], 1 << 1		;se activa el bit de esconder la seleccion
        
        mov eax, [cursor]               
        cmp dword[select.start], eax    ;es el principio de seleccion > a la pos del cursor?
        jb .case1                       ;si es menor, entonces es el caso 1
                                        ;Si es mayor:
        push dword[select.start]        ;el final de la seleccion seria el principio
        push dword[cursor]              ;y el inicio la pos actual del cursor
        jmp .start                      ;los guardo en la pila y procedo a insertar texto
        
        .case1:                         ;si el principio de la seleccion es < que la pos del cursor:
        push  dword[cursor]             ;guardo la posicion del cursor, que es el final de la seleccion       
        push dword[select.start]        ;y el principio de la seleccion como principio de 

        call select.movestart           ;se pone el cursor en la posicion de inicio de la seleccion
        
        .start:
        mov byte[save], 1               ;activo la variable para empezar a grabar
        call mode.insert                ;y llamo a insertar      
        mov dword[save], 0              ;dejo de grabar
        
        push dword[count]               ;guardo la longitud de la palabra que se 'grabo'
        push record                     ;pongo la palabra
        call block.insert               ;y llamo a insertar texto en modo bloque
      
        mov dword[count], 0             ;regreso el tamano de la palabra en 0
        jmp .finish
    jmp .end

    .exit:
       jmp .finish
    ;Logica para salir del modo
    
	.end:
	;Update
	call cursor.noblink
	call video.Update
    .end2:
	call vim.update
    jmp mode.visual
    .finish:
    or byte[videoflags], 1 << 1				;para terminar, se activa el bit de esconder la seleccion
ret
