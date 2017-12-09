%include "tools.mac"

extern UpdateBuffer

section .edata
	
	text.length  dd 		65535   				;el tamano del texto

section .bss

	global text
	text			resb 	65535						;donde guardo el texto
	;trabajo con lineas
	global lines.starts
	lines.starts	resd 	800							;control de lineas :  <comienzo,cantidad> en funcion de bytes del text
	lines.lengths 	resd 800
section .data
	

	global cursor
	cursor 		dd		0			;la posicion del cursor
	
	text.size dd 0
	global lines.current
	lines.current	dd		0 		;la linea actual
	
	GLOBAL lines.lastline
	lines.lastline 	dd 		0		;la ultima linea que se ha escrito
	moveV		dd		0		;el ultimo movimiento vertical

section .text



global text.startConfig
text.startConfig:
	startSubR
		
	; section .data:
		mov byte [text],ASCII.enter
	; section .bss:
		mov word [lines.lengths],1 		;valor inicial del texto 
		mov dword[text.size], 1

	endSubR 0

;HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
;HHHHHHHHHHHHHHHHH TEXT CONTROL HHHHHHHHHHHHHHHHHH
;HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH 

;call:
;push ASCCII: ebp + 4
;call text.replace
global text.replace
text.replace:
	startSubR
		mov ebx,text  			;ebx =text
		add ebx,[cursor]		;ebx = text + cursor
		cmp dword[ebx], 0x0d	;el caracter q voy a reemplazar es el de fin de linea?
		jne .normal				;si no lo es, muevo el texto normal
		
		push dword[cursor]		;sino, pongo la posicion del cursor como parametro
		call text.moveforward	;y llamo a desplazar el texto a partir de esa posicion
		mov eax, [lines.current]
		inc dword[lines.lengths+4*eax]
		inc dword[text.size]
		
		.normal:
		xor eax, eax
		mov al,[ebp+4]   		;guardo 
		mov [ebx],al			;[text + cursor] = ASCII
		mov dword[moveV], 0		;desactualizo el valor de mover vertical
	    inc dword [cursor]		;incremento la posicion del cursor

	endSubR 4

;call:
;push ASCII: ebp + 4
;call text.insert
global text.insert
text.insert:
	startSubR
		push dword[cursor]
		call text.moveforward

		mov ebx,text  		;ebx =text
		add ebx,[cursor]	;ebx = text + cursor
		mov al,[ebp+4]   	;guardo 
		mov [ebx],al		;[text + cursor] = ASCII
	    
		mov eax, [lines.current]
		inc dword[lines.lengths+4*eax]
		inc dword[text.size]

		mov dword[moveV], 0	;desactualizo el valor de mover vertical
	    inc dword [cursor]	;incremento la posicion del cursor
	endSubR 4

;mueve todo el texto
;call 
;push dword start: ebp + 4
;call text.move 
global text.moveforward
text.moveforward:
	startSubR
	;creo espacio en texto
	mov eax,[lines.lastline]
	push eax
	call lines.endline

	mov ecx, [text.size]
	mov eax, [ebp+4]
	sub ecx,eax
	std
	lea edi,[text+eax+1]
	lea esi,[text+eax]
	rep movsb

	;actualizo lines
	mov edx, [lines.lastline]
	cmp edx, [lines.current]
	je .end
	
	push dword [ebp+4]
	call lines.line
	lea edi,[lines.starts + 4*(eax+1)]  
	lea esi,[lines.starts + 4*(eax+1)] 
	
	mov ecx,[lines.lastline]
	sub ecx,eax  
;break
	cld
	.lp:
		stosd
		inc eax
		lodsd
		loop .lp
	.end:
	endSubR 4

;call:
;push dword start: ebp + 4
;call text.move
global text.movebackward
text.movebackward:
	startSubR
	push dword[ebp+4]						;pongo la linea actual como parametro
	call lines.line							;busco la linea de la posicion actual
	
	mov eax, [ebp+4]					
	lea edi, [text+eax]						;mi destino es la posicion actual						
	lea esi, [text+eax+1]					;mi origen es la posicion actual mas 1

	cld								
	mov ecx, [text.size]
	sub ecx, eax							;calculo las veces que voy a moverme: el tamano del text-pos
	rep movsb 								;voy moviendo las palabras

	;Actualizar las posiciones de lines.starts:
	mov eax, [ebp+4]
	mov ecx, [lines.lastline]				;para calcular cuato me tengo que mover
	sub ecx, eax							;la ultima linea - pos
	
	cmp eax, 0x0d							;el caracter que borre es fin de linea?
	jne .normal								;sino lo es, actualizo los valores normal
	jmp .eraseline							;de serlo, elimino la linea

	.eraseline:
	dec dword[lines.lastline]				;decremento el valor de la ultima linea
	mov edx, [lines.lengths+4*eax]			;guardo la cantidad de caracteres de la linea q elimine
	add [lines.lengths+4*(eax-1)], edx		;y a la linea anterior se le adiciona la cant de caracteres de la otra linea
	
	cmp eax, dword[lines.lastline]
	je .end
	;Correr las lineas por lines.lengths:
	cld
	lea esi, [lines.lengths+4*(eax+1)]		;mi origen es la linea actual +1
	lea edi, [lines.lengths+4*eax]			;mi destino es la linea actual

	push ecx								;guardo las repeticiones de movimiento
	rep movsd								;muevo los valores
	pop ecx									;recupero la cantidad

	lea esi, [lines.starts+4*(eax+1)]		;mi origen es la linea actual + 1
	lea edi, [lines.starts+4*eax]			;mi destino la linea actual

	jmp .lp									;y procedo a copiar los valores

	.normal:								;si no borre un fin de linea
	cmp eax, dword[lines.lastline]
	je .end
	
	cld
	lea edi, [lines.starts+4*(eax+1)]		
	lea esi, [lines.starts+4*(eax+1)]

	.lp:									;copio los valores
		stosd
		dec eax								;decrementando el inicio de las lineas
		lodsd
		loop .lp
	.end:
	endSubR 4


;HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
;HHHHHHHHHHHHHHHHH LINE CONTROL HHHHHHHHHHHHHHHHHH
;HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH 



;Recibe una linea y determina en donde empieza la linea y la cantidad de caracteres
	;call:
	;push dword line: ebp + 4
	;call text.lineindex
	;return: ax -> posicion en donde empieza la linea, dx -> cantidad de caracteres
global lines.startsline
lines.startsline:
	startSubR	
	mov eax,[ebp+4]
	lea ebx,[lines.starts + 4*eax]
	mov eax,[ebx]
	endSubR 4



;Determina la posicion en donde se acaba una linea (solo haya ceros a la der)
	;call:
	;push dword line: ebp + 4
	;call text.endline
	;return: ax -> posicion donde esta el final de la linea
global lines.endline
lines.endline:
	startSubR
	;cantidad de caracteres
	mov eax,[ebp+4]
	lea ebx,[lines.lengths + 4*eax]
	mov edx,[ebx]
	;donde empieza la linea
	push dword [ebp +4]
	call lines.startsline
	add eax,edx
	endSubR 4


;Determina la linea que ocupa una posicion determinada
	;call:
	;push dword posicion: ebp + 4
	;call text.line
	;return: eax -> numero de linea
global lines.line
lines.line:
	startSubR
		mov edx, [lines.lastline]				;guardo un contador de las lineas que voy a analinzar
		;mov ebx, lines.starts
		.lp:
			mov eax, [lines.starts+4*edx]
			cmp eax, [ebp+4]
			jbe .end

			dec edx
			cmp edx, 0
			jae .lp
		.end:
		mov eax, edx					;guardo en ax la ultima linea que analice, que es en donde esta la posiciom
	endSubR 4



;Crea, si es posible, la linea en una posicion determinada
	;call: 
	;push dword position: ebp + 4
	;call text.newline
global text.newline
text.newline:
	startSubR
	;rectifico si la linea a crear es, a lo sumo, inmediata a la ultima creada
		push dword[ebp+4]
		call lines.line
		mov edx,[lines.lastline]
;		push lines.endline
		cmp eax,edx
		jb .end       				;si: line > lines.lastline+1 => no tiene sentido alguno crearla
		je .onEnd					;si: line == lines.lastline+1, me salto el corrimiento de lineas o
		 
		;crear una linea dentro de otra
		
		;calculo diferenciales
		
		mov eax,[ebp+4]
		push eax
		call lines.line				;eax = linea en la que se desea particionar
		
		push eax					;salvo linea en ebp-4
		push eax
		call lines.endline
		mov edx,eax
		call lines.startsline
		


		;muevo el text para crear espacio al fin de linea
		mov eax,[ebp+4] 
		push eax
		call text.moveforward
									
		


		jmp .end

		.onEnd:
		;calculo la fila en la que comenzara la linea creada
		 mov eax,[lines.lastline]
		 push eax
		 call lines.endline
		 inc eax								;incremento para  
		 mov edx,eax							;salvo endline
		 
		 inc dword [lines.lastline]				;incremento ultima linea
		 mov eax,[lines.lastline]			
		 mov [lines.startsline +4*eax],edx		;muevo a la ultima linea el valor de el fin de la anterior mas 1
		
		 mov eax,[ebp+4]
		 mov [text + eax],byte ASCII.enter
		 mov eax,[lines.lastline]
		 inc dword [lines.lengths + 4*eax]		;incremento valor de cantidad de caracteres ya que annadi enter
		 
		.end:
	endSubR 4


;HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
;HHHHHHHHHHHHHHHHH CURSOR CONTROL HHHHHHHHHHHHHHHH
;HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH 
;call
;push dword dir (1 abajo 0 -1 arriba: ebp + 4
;call cursor.canmoveV
;return: eax -> 0 o 1 si se puede mover o no
cursor.canmoveV:
	startSubR
		mov dx, [lines.current]		;edx = linea actual
		add edx, [ebp+4]			;edx = linea actual + posicion a la que se mueve

		cmp edx, 0					;es la pos hacia la que se va a mover menor que 0?
		jl .no 						;si lo es, entonces no se puede mover
		cmp edx, [lines.lastline]	;es la pos mayor que la ultima linea?
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
		mov ebx,[cursor]			;ebx = text + cursor
		add ebx, [ebp+4]			;simula el movimiento 

		push dword [lines.current]	;pongo la linea actual como parametro
		call lines.startsline		;busco el principio de la linea
	  	cmp ebx, eax				;comparo donde me quiero mover con el principio de la linea 
	    jb .no						;si la poscion a la que me voy a mover es menor, 
									;entonces se sale de la linea actual y no me muevo
		push dword[lines.current]	 ;pongo la linea actual como parametro
		call lines.endline 			;busco el final de la linea
	;	break
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
		
		push dword[lines.current]	;pongo la linea actual como parametro
		call lines.endline			;para preguntar por su fin de linea
		mov ebx, eax				;ebx = fin de linea
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
		push dword[lines.current]		;guardo la linea actual como parametro
		call lines.startsline			;y pregunto por su inicio de linea
		
		mov edx, [cursor]			;edx = cursor
		sub edx, eax				;resto la posicion del cursor menos el principio, para calcular la cantidad que se quiere mover

		cmp byte[moveV], 0			;el valor del movimiento horizontal esta actualizado?
		je .continue				;de no estarlo, continuo
		xor edx, edx				
		mov dl, [moveV]				;sino cambio el valor de la cantidad que se quiere mover
		.continue:
		push edx					;guardo cuanto se quiere mover en pila

		mov ebx, [lines.current]	;ebx = linea actual
		add ebx, [ebp+4]			;linea actual += 1 0 -1 dependiendo de hacia donde se mueve, para obtener la linea a la que me voy a mover 
		mov [lines.current], ebx	;cambio la posicion de mi linea actual

		push ebx					;pongo la linea a la que me voy a mover como parametro
		call lines.startsline		;tengo en eax el principio de linea

		mov edx, [esp]				;busca en el tope de la pila cuanto se tiene que mover
		add edx, eax				;edx = principio de la linea + cantidad que se va a mover
		mov [cursor], edx			;se pone el cursor en la posicion calculada
		mov edx, eax				;guardo el principio de la linea
		 
		push ebx					;pongo la linea a la que me voy a mover como parametro
		call lines.endline			;busco el final de esa linea
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

