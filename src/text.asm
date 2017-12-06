%include "tools.mac"

extern UpdateBuffer

section .edata
	
	text.length  dw 		65535   				;el tamano del texto

section .bss

	global text
	text	resb 	65535						;donde guardo el texto
	
	lines	resd 	800							;control de lineas :  <comienzo,cantidad> en funcion de bytes del text
section .data
	

	global cursor
	cursor 		dw		0			;la posicion del cursor
	
	currentline	dw		0 		;la linea actual

	global lastline
	lastline 	dw 		0		;la ultima linea que se ha escrito

section .text







global text.startConfig
text.startConfig:
	startSubR
		
	; section .data:
		mov byte [text],' '

	; section .bss:
		mov word [lines],1 		;valor inicial del texto 
	endSubR 0



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
	    inc word [lines]
	    
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
 		mov edx,text.length
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
	mov edx,4			;muevo 4 a dl para multiplicar y asi obtener el valor de lines[line]
	mul edx				;multiplico por 4
	mov ebx,lines	    ;obtengo la referencia
	add ebx,eax			;indexo
	xor eax,eax
	mov ax,[ebx+2]		;recupero el valor del indexado,sumo 2 para estar en la perte alta de lines[line], y optener el comienzo de linea
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
	xor eax,eax
	mov ax,[ebx]		;recupero valor de cantidad de caracteres
	add ax,[ebx+2]		;sumo el inicio de linea
	endSubR 4



;Determina la linea que ocupa una posicion determinada
	;call:
	;push dword posicion: ebp + 4
	;call text.line
	;return: eax -> numero de linea
global text.line
text.line:
	startSubR
		mov edx, [lastline]				;guardo un contador de las lineas que voy a analinzar
		;mov ebx, lines	
		.lp:
			mov eax, [lines+2+4*edx]
			cmp eax, [ebp+4]
			jb .end

			dec edx
			cmp edx, 0
			jae .lp
		.end:
		mov eax, edx					;guardo en ax la ultima linea que analice, que es en donde esta la posiciom
	endSubR 4



;Crea, si es posible, la linea en una posicion determinada
	;call: 
	;push dword line: ebp + 4
	;call text.newline
global text.newline
text.newline:
	startSubR


	

		push dword [ebp+4]
		call text.startline
		mov edx,eax					;salvo el valor de el comienzo de la linea dada



		push dword 1
		push dword [ebp+4]
		call text.skipline			;muevo el bloque de lineas

		
		
		;rectifico si la linea a crear es, a lo sumo, inmediata a la ultima creada
		mov ax,[lastline]
		inc ax
		cmp ax,[ebp+4]
		jb .end       				;si: line > lastline+1 => no tiene sentido alguno crearla
		je .create					;si: line == lastline+1, me salto el corrimiento de lineaso
		

		;veo si la linea a crear 
		xor ecx,ecx
		mov cx,[lastline]
		sub ecx,[ebp+4]			 	;ecx = cantidad de lineas que tuve que mover un fila para crear esta




		lea edi,[lines + eax + 4]
		lea esi,[lines + eax]
		std
		rep movsd 					;muevo desde abajo hasta arriba los valores de las lineas

		.create:
		mov eax,[ebp+4]
		mov [lines+4*eax+2],dx
		inc word [lastline]
		.end:
	endSubR 4



;elimina, si es posible, la linea determinada
	;call: 
	;push dword line: ebp + 4
	;call text.deleteline
global text.deleteline
text.deleteline:
	startSubR
	




	endSubR 4



;Mueve a partir de linea determinada (diferente de zero) todo el texto 
	;call: 
	;push dword count: ebp + 8
	;push dword line: ebp + 4
	;call text.newline
global text.skipline
text.skipline:
	startSubR
		
		;rectifico si la linea es mayor que la ultima creada, en es caso voy al final
		mov eax,[ebp+4]
		cmp ax,[lastline]
		jg .end

		mov eax,80				;cantidad de una linea
		imul dword [ebp+8]		;multiplico por la cantidad a mover, esto es: cuantas lineas quieres que mueva? 
		push  eax				;count 	
	
		push dword [ebp+4]  	;push a la linea desde la cual se quiere hacer el skip, para obtener el valor de donde comienza
		call text.startline		;eax = inciode la linea deseada
		push eax 				;start
		

		push dword [lastline]	;push a la ultima linea para asi tener el valor de la linea mas abajo qe he creado y mover sin solapar
		call text.endline		;eax = final de la ultima linea
		push eax  				;end 
		
		call text.move			;muevo el text 

	;se! que se movio bien y que todos los metodos usados funcionaron
	;ahora me dispongo a mover los valores de las lineas,  comienzos+80*count
	
		
		mov eax,[ebp+8]			;eax = count*dir	
		mov edx,80				;muevo a 	eax = 80, para mover los comienzos tantos 80s como lineas queria que saltara
		imul edx 				;multiplico por count*dir
		push eax				;en la pila se encuentra el valor por defecto en caso de que no se necesite ningun trunke
		
		

		mov eax,[ebp+8]
		cmp eax,0				;veo como es el valor de count con respecto a zero
 		jl .lz
 		jg .gz

 		pop eax
 		je .end

	.gz:						;en caso que sea mayor que zero		
		push dword [lastline]	;guardo en pila el valor de [lastline], esto es para calcular la ultima fila escrita en toda la matriz del texto
		call text.endline		;calculo donde termina la ultima linea
		mov dl,80				;divido entre 80, si el resto es zero este es el valor de la ultima fila, sino, es ax+1,esto ultimo no no hare ahora
		div dl	
		mov edx,800				;cantidad de lineas
		sub edx,eax				;esto es: la cantidad de filas menos la ultima, osea, la cantidad que tengo disponible
		mov eax,[ebp+8]			;lo muevo a eax : eax = count
		cmp eax,edx				;veo como es el count en comparacion con la cantidad posible
		jbe .ready 				;si es menor, entonces puedo hacer el skip , sino
		
		pop eax					;quito de la pila el valor 
		mov eax,80				;muevo a 	eax = 80, para mover los comienzos tantos 80s como lineas queria que saltara
		mul dx					;multiplico por valor disponible para saltar
		push eax				;en la pila se encuentra el valor por defecto en caso de que no se necesite ningun trunke
		jmp .ready

	.lz:

		

		push dword [ebp+4]		;edx = linea a mover
		call text.startline		;pregunto por el valor inicial de la linea
		mov dl,80				;para ver la fila exacta donde empieza
		div dl		
		mov edx,eax				;edx = fila donde empieza la linea a subir
		
		push edx				;salvo valor en la pila, el valor de la fila

		mov eax,[ebp+8]			;lo muevo a eax : eax = count
		neg eax				

		pop edx					;recupero valor de la pila 

		cmp ax,dx				;veo como es el count en comparacion con la cantidad posible
		jbe .ready 				;si es menor, entonces puedo hacer el skip , sino
		
		pop eax					;quito de la pila el valor (inicial)
		
		xor eax,eax
		mov ax,80				;muevo a 	eax = 80, para mover los comienzos tantos 80s como lineas queria que saltara
		mul dx					;multiplico por valor disponible para saltar
		neg eax

		push eax				;en la pila se encuentra el valor por defecto en caso de que no se necesite ningun trunke
		jmp .ready
	

	.ready:
	
		mov eax,[ebp+4]			;eax = linea cambiada
		mov dl,4				;factor indexador
		mul dl					;multiplico: eax = line*4
		
		lea edi,[lines +eax +2]	;muevo a 	edi = lines[] 
		lea esi,[lines +eax +2]	;muevo a  	esi = lines[]


		mov ecx,[lastline]
		sub ecx,[ebp+4]		 	;guardo en ecx el valor 		
		inc ecx

		pop edx
		cld
		
	.lp:					
		lodsd					;guardo el valor del comienzo en eax
		add ax,dx				;modifico con la cantidad de salto
		stosd 					;vuelvo a poner el valor en su sitio
		
		loop .lp
	.end:

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
