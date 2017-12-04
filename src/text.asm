%include "tools.mac"

extern UpdateBuffer

section .edata
	textlength  dw 		65535   ;el tamano del texto
	;
section .bss

	global text
	text	resb 	65535	;donde guardo el texto
	lines	resd 	800		;control de lineas :  <comienzo,cantidad> en funcion de bytes del text
section .data

	global cursor
	cursor 		dw		0		;la posicion del cursor

	;
	;lines 		dd 		0
	;lines times 800	dd		0;0x00500000		

	currentline	dw		0 		;la linea actual
	lastline 	dw 		0		;la ultima linea que se ha escrito

section .text







;HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
;HHHHHHHHHHHHHHHHH TEXT CONTROL HHHHHHHHHHHHHHHHHH
;HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH 


;call:
;push ASCII
;call write
;no return
global text.write
text.write:
	startSubR
		mov ebx,text  		;ebx =text
		add ebx,[cursor]	;ebx = text + cursor
		mov al,[ebp+4]   	;
		mov [ebx],al		;[text + cursor] = ASCII
	    
	    call cursor.fmove
	    
	    
	    inc dword [lines]
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








;HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
;HHHHHHHHHHHHHHHHH LINE CONTROL HHHHHHHHHHHHHHHHHH
;HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH 



;Recibe una linea y determina en donde empieza la linea y la cantidad de caracteres
	;call:
	;push dword line: ebp + 4
	;call text.lineindex
	;return: ax -> posicion en donde empieza la linea, dx -> cantidad de caracteres
global text.startline
text.startline:
	startSubR	
	mov eax,[ebp+4]		;muevo a eax la linea		
	mov dl,4			;muevo 4 a dl para multiplicar y asi obtener el valor de lines[line]
	mul dl				;multiplico por 4
	mov ebx,lines	    ;obtengo la referencia
	add ebx,eax			;indexo
	mov eax,[ebx+2]		;recupero el valor del indexado,sumo 2 para estar en la perte alta de lines[line], y optener el comienzo de linea
	endSubR 4



;Determina la posicion en donde se acaba una linea (solo haya ceros a la der)
	;call:
	;push dword line: ebp + 4
	;call text.endline
	;return: ax -> posicion donde esta el final de la linea
global text.endline
text.endline:
	startSubR
	mov eax,[ebp+4]		;muevo a eax la linea		
	mov dl,4			;muevo 4 a dl para multiplicar y asi obtener el valor de lines[line]
	mul dl				;multiplico por 4
	mov ebx,lines	    ;obtengo la referencia
	add ebx,eax			;indexo
	mov eax,[ebx]		;recupero valor de cantidad de caracteres
	add eax,[ebx+2]		;sumo el inicio de linea
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



;Crea, si es posible, la linea siguiente a una posicion determinada
	;call: 
	;push dword line: ebp + 4
	;call text.newline
global text.newline
text.newline:
	startSubR
	
	endSubR 4



;elimina, si es posible, la linea determinada
	;call: 
	;push dword line: ebp + 4
	;call text.deleteline
global text.deleteline
text.deleteline:
	startSubR
	
	endSubR 4



;Mueve a partir de linea determinada todo el texto 
	;call: 
	;push dword count: ebp + 8
	;push dword line: ebp + 4
	;call text.newline
global text.skipline
text.skipline:
	startSubR
		   					
	push dword [lastline]	;push a la ultima linea para asi tener el valor de la linea mas abajo qe he creado y mover sin solapar
	call text.endline		;eax = final de la ultima linea
	mov edx,eax  			;guardo en edx el valor para reusar
	

	push dword [ebp+4]  	;push a la linea desde la cual se quiere hacer el skip, para obtener el valor de donde comienza
	call text.startline		;eax = inciode la linea deseada
	mov ecx,eax 			;guardo en ecx el valor para reusar

	mov eax,80				;cantidad de una linea
	mul byte [ebp+8]		;multiplico por la cantidad a mover, esto es: cuantas lineas quieres que mueva? 
	push  eax				;count 				
	push  ecx				;start
	push  edx				;end
	call text.move			;muevo el text 

	;se! que se movio bien y que todos los metodos usados funcionaron

	;mov ecx,[ebp + 8];[lastline]
	;;sub ecx,[ebp+4]			; ecx = lastline - line = cantidad de lineas movidas
	;
	;mov eax,[ebp+4]
	;mov ebx,lines	
	;add ebx,eax				;donde empiezo a actualizar

	;mov edi,ebx				
	;mov esi,ebx

	;mov eax,80
	;mul word [ebp+8]
	;mov edx,eax
	;.lp:

	;lodsw 					;esto es para mover los punteros en 2 
	;stosw 					

	;lodsw 					;guardo el valor del comienzo
	;add ax,dx				;modifico con la cantidad q movi
	;stosw 					;vuelvo a poner el valor en su sitio

	;loop .lp

	endSubR 8






;HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
;HHHHHHHHHHHHHHHHH CURSOR CONTROL HHHHHHHHHHHHHHHH
;HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH 

;call: 
;call cursor.move
global cursor.move
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
