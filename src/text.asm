%include "tools.mac"


section .edata
	textlength  dw 		65535   ;el tamano del texto
section .bss
global text
	text	resb 	65535	;donde guardo el texto 
	lines	resd 	800		;control de lineas :  <comienzo,final> en funcion de bytes del text
section .data
global cursor
	cursor 		dw		0		;la posicion del cursor
	currentline	dw		0 		;la linea actual
	lastline 	dw 		0		;la ultima linea que se ha escrito

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
;push dword dir*count: ebp +12 
;push dword start: ebp + 8
;push dword end : ebp + 4
;call text.move 
global text.move
text.move:
	startSubR
		mov eax,[ebp+12]
		cmp eax,0
		jg .right					;si es menor, entonces se va a mover hacia la derecha
		jl .left					;si el principio es mayor, entonces se va a mover a la izquierda
		jmp .end 					;si son iguales, entonces se finaliza
	.right:
		;Se saca la cuenta de cuantas veces se va a copiar
		mov ecx,[ebp+4]				;se guarda el final
		sub ecx,[ebp+8]				;y se resta por el principio, esa es la cantidad de movimientos que se van a hacer

		mov eax,[ebp+12]

		;<<<<<<truncar!
 		mov edx,textlength
 		sub edx,[ebp+4]
		cmp eax,edx
		jb .tR
		mov eax,edx

	.tR:
		push eax
		std 						;se setea el direction flag 
		mov ebx,text 				;se guarda en ebx el texto para indexar
		add ebx,[ebp+4]				;se indexa como text[end]

		mov esi,ebx					;el origen es el caracter anterior que se estaba copiando
		mov edi,ebx 				;el destino es el texto en el final
		add edi,eax						
		jmp .move					;salta para moverse
	
	.left:
		;Se saca la cuenta de cuantas veces se va a copiar
		mov ecx,[ebp+4]				;se guarda el principio
		sub ecx,[ebp+8]				;se resta menos el final, esa es la cantidad de mov que se van a hacer
		
		mov eax,[ebp+12]
		neg eax						;eax = |dir*count|

		;<<<<<<truncar!
		cmp eax,[ebp+8]
		jb .tL
		mov eax,[ebp+8]

	.tL:
		push eax
		cld 						;se limpia el direction flag
		mov ebx,text 				;se mueve a ebx el texto para indexar
		add ebx,[ebp+8] 			;se indexa como text[start]
		
		mov esi,ebx					;el origen es hacia donde se va a copiar menos 1			
		mov edi,ebx 				;el destino, es el texto en el final
		sub edi,eax			        ;se incrementa ebx
		
		jmp .move					;se procede a mover el texto
	.move:
		inc ecx
		rep movsb					;se repite el movimiento caracter por caracter de acuerdo con la cuenta sacada	
	.fill:
		pop ecx
		mov al,0
		rep	stosb 	
	.end:
	endSubR 12

;Recibe una linea y determina en donde empieza la linea y la cantidad de caracteres
;call:
;push dword line: ebp + 4
;call text.lineindex
;return: ax -> posicion en donde empieza la linea, dx -> cantidad de caracteres
global text.lineindex
text.lineindex:
	push ebp
	lea ebp, [esp+4]
	push ebx

	mov ebx, lines	
	add ebx, [ebp+4]			;indexo lines[line]
	mov dx, [ebx]
	add ebx,2
	mov ax, [ebx]				;pongo en bx la parte baja del registro (la cant de caracteres)
	
	pop ebx
	pop ebp
	ret 4

;Determina la posicion en donde se acaba una linea (solo haya ceros a la der)
;call:
;push dword line: ebp + 4
;call text.endline
;return: ax -> posicion donde esta el final de la linea
global text.endline
text.enline:
	startSubR
		push dword [ebp+4]			;pongo la linea que me piden como parametro
		call text.lineindex			;llamo a lineindex para obtener, en ax donde empieza la linea y en dx la cantidad de caracteres
		add ax, dx					;el final de linea seria donde comienza mas la cantidad de caracteres
	endSubR 4

;Determina la linea que ocupa una posicion determinada
;call:
;push dword posicion: ebp + 4
;call text.line
;return: eax -> numero de linea
global text.line
text.line:
	startSubR
		mov ecx, [lastline]				;guardo un contador de las lineas que voy a analinzar
		;mov ebx, lines	
		.lp:
			mov eax, [lines+4*ecx]
			cmp eax, [ebp+4]
			jb .end

			dec ecx
			cmp ecx, 0
			jae .lp
		.end:
		mov eax, ecx					;guardo en ax la ultima linea que analice, que es en donde esta la posiciom
	endSubR 4

;;call:
;;push dword start: ebp +12
;;push dword end: ebp +8
;;push dword count: ebp +4
;global text.rmove
;text.rmove:
;	startSubR
;	mov ecx,0
;	
;	.loop:
;	mov [ebp+12] 
;	add ebp
;	push ebp
;	call text.move 
;	endSubR 0
;
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
