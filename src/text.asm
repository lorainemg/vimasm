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
endSubR 2

;call
;push start: ebp + 6
;push  end : ebp + 4
;call text.move 
global text.move
text.move:
startSubR
	;mov ax,[ebp+8]
	;cmp ax,[ebp+4]
	;jb .right
	;ja .left
	;jmp .end
	jmp .left
.right:
	mov ecx,[ebp+4]
	sub ecx,[ebp+8]

	std
	mov ebx,text
	add ebx,[ebp+4]
	
	mov edi,ebx
	dec ebx
	mov esi,ebx
	jmp .move

.left:
	mov cx,[ebp+8]
	sub cx,[ebp+4]
	
	cld
	mov ebx,text
	add ebx,[ebp+4]
	
	mov edi,ebx
	inc ebx
	mov esi,ebx
	jmp .move
.move:
	rep movsb
    dec word [cursor]
.end:
endSubR 8




; <<<<<<<< CURSOR >>>>>>>>
global cursor.move
;call: 
;call cursor.move
cursor.move:
	startSubR
	call cursor.canmove
	cmp al,0
	jz .end
	add word [cursor],1
	.end:
endSubR 0


;call:
;call cursor.fmove
cursor.fmove:
	startSubR
	call cursor.canmove
	cmp al,0
	jz .z 
	call cursor.move
	jmp .end
	.z:
	add word [cursor],1
	.end:
endSubR 0


;call: 
;call cursor.canmove
cursor.canmove:
	startSubR
	mov ebx,text
	add ebx,[cursor]
	inc ebx
	mov al,[ebx]
	cmp al,0
	jz .end
	mov al,1
	.end:
endSubR 0
