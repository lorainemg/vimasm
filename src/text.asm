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
	lastline 	dw 		0		;la ultima linea que se ha escrito
	moveV		dw 		0		;el ultimo movimiento vertical

section .text







global text.startConfig
text.startConfig:
	startSubR
		
	; section .data:
		mov byte [text],' '

	; section .bss:
;		mov word [lines+2],0 		;valor inicial del texto 

		lea edi,[lines+6] 		;para moverme desde el segundo comienzo hasta el proximo
		lea esi,[lines+6]		;eso de arriba
		mov cx,800				; cantidad de lineas
		.lp:
		lodsd 					
		add ax,240 				;esto es parche!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!, debe ser zero				
		stosd
		loop .lp
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
	    
	    inc word [cursor]
	    inc word [lines]
	   	.cont:
	    inc ebx
	    mov [ebx], byte ' ' 
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
	mov dl,4			;muevo 4 a dl para multiplicar y asi obtener el valor de lines[line]
	mul dl				;multiplico por 4
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
	
	push dword 1
	push dword [ebp+4]
	call text.skipline

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
		mov eax,80				;cantidad de una linea
		imul dword [ebp+8]		;multiplico por la cantidad a mover, esto es: cuantas lineas quieres que mueva? 
		push  eax				;count 	
	
		push dword [ebp+4]  	;push a la linea desde la cual se quiere hacer el skip, para obtener el valor de donde comienza
		call text.startline		;eax = inciode la linea deseada
		push eax 				;start
		
		
		cmp eax,0				;si la linea esta en 
		jne .ok 
		
		pop eax	
		pop eax
		jmp .end

		.ok:  					;esta acotado en zero

		push dword 1;[lastline]	;push a la ultima linea para asi tener el valor de la linea mas abajo qe he creado y mover sin solapar
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
		push dword 1;[lastline]	;guardo en pila el valor de [lastline], esto es para calcular la ultima fila escrita en toda la matriz del texto
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


		mov ecx,2;[lastline]
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
;call
;push dword dir (1 abajo 0 -1 arriba: ebp + 4
;call cursor.canmoveV
;return: eax -> 0 o 1 si se puede mover o no
cursor.canmoveV:
	startSubR
		mov dx, [currentline]		;edx = linea actual
		add edx, [ebp+4]			;edx = linea actual + posicion a la que se mueve

		cmp edx, 0					;es la pos hacia la que se va a mover menor que 0?
		jl .no 						;si lo es, entonces no se puede mover
		cmp edx, 2 ;[lastline]		;es la pos mayor que la ultima linea?
		jg .no 						;si lo es, entonces no se puede mover
		mov eax, 1					;sino, se puede mover
		jmp .end 					;en caso contrario se puede mover
		.no:						;para cuando no se pueda mover
		xor eax, eax				;pone en eax 0
		.end:
	endSubR 4

;call
;push dword dir (1 derecha 0 -1 izquierda)
;call cursor.canmoveH
;return: eax -> 0 o 1 si se puede mover o no
cursor.canmoveH:
	startSubR
		mov ebx,[cursor]	;ebx = text + cursor
		add ebx, [ebp+4]	;simula el movimiento 

		push dword [currentline]	;pongo la linea actual como parametro
		call text.startline			;busco el principio de la linea
	  	break
	  	cmp ebx, eax				;comparo donde me quiero mover con el principio de la linea 
	    jb .no						;si la poscion a la que me voy a mover es menor, entonces se sale de la linea actual y no me muevo
		
		push dword[currentline]	 	;pongo la linea actual como parametro
		call text.endline 			;busco el final de la linea
		;mov eax, 170
	  	cmp ebx, eax				;se compara la posicion con el final de linea
	  	ja .no						;si es mayor, entonces no hay movimiento
	  	
	  	mov eax, 1					;por el contrario, el cursor se puede mover
	  	jmp .end 					;salta hacia el final
	  	.no:	  	
	  	xor eax, eax				;en caso de que no pueda mover el cursor, entonces pongo 0 en eax
	  	.end:
	endSubR 4

;call:
;push dword dir (1 derecha o -1 izquierda): ebp + 4
;call cursor.moveH
global cursor.moveH
cursor.moveH:
	startSubR
		push dword[ebp+4]			;guardo en la pila la direccion como parametro
		call cursor.canmoveH		;pregunto si me puedo mover hacia esa direccion
		cmp eax, 0				    ;me puedo mover?
		je .end 					;si no me puedo mover, entonces no hago nada

		mov byte[moveV], 0			;si se movio horizontal, entonces el valor anterior del desplazamiento vertical se quita

		
		push dword[currentline]		;pongo la linea actual como parametro
		call text.endline			;para preguntar por su fin de linea
		mov ebx, eax				;ebx = fin de linea
		;mov ebx, 170
		xor eax, eax				;limpio eax
		mov ax, [cursor]			;pongo la posicion del cursor	
		.lp:
			mov edx, text 			;guardo en edx el texto
			add ax, [ebp+4]			;adiciono la pos actual + la dir a la que me muevo
			add edx, eax			;para indexar text[cursor]
			cmp byte[edx], 0		;si no hay 0 en el texto
			jne .end1				;si no lo hay, entonces termino
			cmp ax, bx				;o si la posicion en la que estoy es el final de la linea
			je .end1				;entonces termino
			jmp .lp					;sino, continuo
		.end1:
		mov [cursor], ax			;pongo el cursor en la posicion calculada
		.end:
	endSubR 4

;call:
;push dword dir (1 abajo o -1 arriba): ebp + 4
;call cursor.

global cursor.moveV
cursor.moveV:
	startSubR
		push dword[ebp+4]			;pongo como parametro la direccion a la que me voy a mover
		call cursor.canmoveV		;pregunto si me puedo mover a la direccion dada
		cmp eax, 0					;me puedo mover?
		je .end 					;si no, entonces salto para el final
		;Procedo a mover el cursor:
		push dword[currentline]		;guardo la linea actual como parametro
		call text.startline			;y pregunto por su inicio de linea
		;mov eax, 0
		
		mov edx, [cursor]			;edx = cursor
		sub edx, eax				;resto la posicion del cursor menos el principio, para calcular la cantidad que se quiere mover

		cmp byte[moveV], 0			;el valor del movimiento horizontal esta actualizado?
		je .continue				;de no estarlo, continuo
		xor edx, edx				
		mov dl, [moveV]				;sino cambio el valor de la cantidad que se quiere mover
		.continue:
		push edx					;guardo cuanto se quiere mover en pila

		mov bx, [currentline]		;ebx = linea actual
		add ebx, [ebp+4]			;linea actual += 1 0 -1 dependiendo de hacia donde se mueve, para obtener la linea a la que me voy a mover 
		mov [currentline], ebx		;cambio la posicion de mi linea actual

		push ebx					;pongo la linea a la que me voy a mover como parametro
		call text.startline			;tengo en eax el principio de linea
		;mov eax, 80

		mov edx, [esp]				;busca en el tope de la pila cuanto se tiene que mover
		add edx, eax				;edx = principio de la linea + cantidad que se va a mover
		mov [cursor], edx			;se pone el cursor en la posicion calculada
		mov edx, eax				;guardo el principio de la linea
		 
		push ebx					;pongo la linea a la que me voy a mover como parametro
		call text.endline			;busco el final de esa linea
		;mov eax, 88
		sub eax, edx				;resto el final de linea menos el principio, para obtener la cant de caracteres

		pop ebx						;se recupera cuanto se quiere mover
		cmp eax, ebx 				;es la cantidad de caracteres de la linea mayor que lo que se quiere mover?
		ja .end 					;si lo es, entonces no se hace mas nada
		add eax, edx				;si no adiciono el principio con la cantidad de caracteres, para obtener el final de linea
		mov [cursor], eax			;pongo el cursor en el final de la linea
		mov al, [moveV]				;copio el valor del ultimo movimiento vertical
		cmp al, 0					;el valor esta actualizado?
		jne .end 					;si no lo esta, entonces finalizo
		mov [moveV], bl  			;sino, cambio su valor
		.end:
	endSubR 4

