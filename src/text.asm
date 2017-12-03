%include "tools.mac"



section .bss
global text
	text	resb 	65536	;donde guardo el texto 
	lines	resd 	800		;control de lineas :  <comienzo,final> en funcion de bytes del text
section .data
global cursor
	cursor 	dw		0		;la posision del cursor
	cline	dw		0 		;la linea actual
section .text


extern UpdateBuffer

;<<<<<<  TEXT >>>>>>>>

global text.write
;call:
;push ASCII
;call write
;no return
text.write:
startSubR
	mov ebx,text  		;ebx =text
	add ebx,[cursor]	;ebx = text + cursor
	mov al,[ebp+4]   	;
	mov [ebx],al		;[text + cursor] = ASCII
    call cursor.fmove 
    ;actualizar linea
	;mover forzado el cursor
endSubR 4

;call
;push dword start: ebp + 8
;push dword end : ebp + 4
;call text.move 
global text.move
text.move:
startSubR
	mov ax,[ebp+8]				;pone en ax en donde se va a comenzar a mover el texto
	cmp ax,[ebp+4]				;se compara el principio con el final
	jb .right					;si es menor, entonces se va a mover hacia la derecha
	ja .left					;si el principio es mayor, entonces se va a mover a la izquierda
	jmp .end 					;si son iguales, entonces se finaliza
.right:
	;Se saca la cuenta de cuantas veces se va a copiar
	mov ecx,[ebp+4]				;se guarda el final
	sub ecx,[ebp+8]				;y se resta por el principio, esa es la cantidad de movimientos que se van a hacer

	std 						;se setea el direction flag 
	mov ebx,text 				;se guarda en ebx el texto para indexar
	add ebx,[ebp+4]				;se indexa como text[end]
	
	mov edi,ebx 				;el destino es el texto en el final
	dec ebx						
	mov esi,ebx					;el origen es el caracter anterior que se estaba copiando
	jmp .move					;salta para moverse

.left:
	;Se saca la cuenta de cuantas veces se va a copiar
	mov cx,[ebp+8]				;se guarda el principio
	sub cx,[ebp+4]				;se resta menos el final, esa es la cantidad de mov que se van a hacer
	
	cld 						;se limpia el direction flag
	mov ebx,text 				;se mueve a ebx el texto para indexar
	add ebx,[ebp+4] 			;se indexa como text[end]
	
	mov edi,ebx 				;el destino, es el texto en el final
	inc ebx						;se incrementa ebx
	mov esi,ebx					;el origen es hacia donde se va a copiar menos 1
	jmp .move					;se procede a mover el texto
.move:
	rep movsb					;se repite el movimiento caracter por caracter de acuerdo con la cuenta sacada
    dec word [cursor]			
.end:
endSubR 8


; <<<<<<<< CURSOR >>>>>>>>
global cursor.move
;call: 
;call cursor.move
cursor.move:
startSubR						
	call cursor.canmove			;determina si se puede mover el cursor o no
	cmp al,0					;se puede mover?
	jz .end 					;si no se puede mover, finaliza
	add word [cursor],1			;por el contrario mueve el cursor
	.end:
endSubR 0


;call:
;call cursor.fmove
cursor.fmove:					;fuerza el movimiento del cursor
startSubR
	call cursor.canmove			;pregunta si se puede mover el cursor
	cmp al,0					;se puede mover?
	jz .z 						;si no, entonces salta 
	call cursor.move			;si si, llama a mover el cursor
	jmp .end 					;y finaliza
	.z:
	add word [cursor],1			;procede a mover el cursor
	.end:
endSubR 0


;call: 
;call cursor.canmove
;return: in al 1 si se puede mover, 0 si no
cursor.canmove:
startSubR
	mov ebx,text     			;se mueve el texto para indexar
	add ebx,[cursor]			;se indexa como text[cursor+1] y se guarda en ebx
	inc ebx
	;lea ebx, [ebx+cursor+1]
	mov al,[ebx]				;se mueve en al lo que hay en el texto indexado
	cmp al,0					;si es cero, entonces se esta en la ultima posicion del texto y no se puede seguir moviendo
	jz .end  					;asi que se salta hasta el final, dejando en al cero
	mov al,1					;sino se pone en al 1
	.end:
endSubR 0
