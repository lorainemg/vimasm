%include "tools.mac"

extern UpdateBuffer,pointC

section .edata
	
	text.length  dd 		65535   				;el tamano del texto

section .bss

	pRecord.cache   resb 	400
	var             resd 	10	
	global text
	text			resb 	65535						;donde guardo el texto
	;trabajo con lineas
	global lines.starts
	lines.starts	resd 	800							;control de lineas :  <comienzo,cantidad> en funcion de bytes del text
	
	global lines.lengths
	lines.lengths 	resd 	800

	undo 			resd     899200						;cincuenta reservaciones

	select.cache		resb	65535
	global search
	search 				resd	800			;posiciones de las busquedas
	
	
	section .data
	global pRecord.mode
	pRecord.mode 	dd 		0
	global pRecord.top
	pRecord.top 	dd 		0

	global undopivot
	undopivot		dd      0
	global cursor
	cursor 			dd		0			;la posicion del cursor
	
	movCursor		db 		0		;para indicar cuando el cursor se mueve, para guardar
	global text.size
	text.size 		dd 		0
	global lines.current
	lines.current	dd		0 		;la linea actual
	
	GLOBAL lines.last
	lines.last 	dd 		0		;la ultima linea que se ha escrito
	moveV		dd		0		;el ultimo movimiento vertical
	global patternLen
	patternLen 	dd 		0		;el tamano del patron de la busqueda actual
	global matchLen
	matchLen	dd 		0		;la cantidad de macheos hechos en la busqueda actual 

	;######################################################################3
	;######################################################################3
	global select.start
	select.start 	dd  	0
	global select.mode
	select.mode  	dd  	0

	copy.start 		dd 		0
	copy.mode 		dd		0
	copy.length		dd		0	

	global ignoreCase			
	ignoreCase		db		0
	%define select.mode.normal 	0
	%define select.mode.line 	1
	%define select.mode.block 	2
section .text



global text.startConfig
text.startConfig:
	startSubR
		
	; section .data:
		mov byte [text],ASCII.enter
	; section .bss:
		mov word [lines.lengths],1		;valor inicial del texto 
		mov dword[text.size], 1
		mov dword[cursor], 0
		call text.save
endSubR 0

global text.restart
text.restart:
	startSubR
	mov dword[undopivot], 3004
	call text.load
	call text.startConfig
	endSubR 0

;HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
;HHHHHHHHHHHHHHHHH TEXT CONTROL HHHHHHHHHHHHHHHHHH
;HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH 

;call:
;push ASCII: ebp + 4
;call text.replace
global text.replace
text.replace:
	startSubR
		mov ebx,text  			;ebx =text
		add ebx,[cursor]		;ebx = text + cursor
		
		cmp byte[ebx], ASCII.enter	;el caracter q voy a reemplazar es el de fin de linea?
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

		fillPointC pastepRecord
		mov eax,[pRecord.top]
		mov edx,[ebp+4]
		mov [pRecord.cache+eax],dl
		mov byte [pRecord.cache+eax+1],0
		inc dword[pRecord.top]
		mov dword [pRecord.mode],text.replace
endSubR 4

;call:
;push ASCII: ebp + 4
;call text.insert
global text.insert
text.insert:
	startSubR

		push dword[cursor]
		call text.moveforward

		cmp byte[movCursor], 0
		je .cont

		mov byte[movCursor], 0
		call text.save

		.cont:
		mov ebx,text  					;ebx =text
		add ebx,[cursor]				;ebx = text + cursor
		mov al,[ebp+4]   				;guardo 
		mov [ebx],al					;[text + cursor] = ASCII
	    
		mov eax, [lines.current]
		inc dword[lines.lengths+4*eax]	;incremento el tamano de la linea actual
		inc dword[text.size]			;incremento el tamano del text

		mov dword[moveV], 0				;desactualizo el valor de mover vertical
	    inc dword [cursor]				;incremento la posicion del cursor

		fillPointC pastepRecord
		mov eax,[pRecord.top]
		mov edx,[ebp+4]
		mov [pRecord.cache+eax],dl
		mov byte [pRecord.cache+eax+1],0		
		inc dword[pRecord.top]
	endSubR 4

global pastepRecord
pastepRecord:
startSubR
		cld
		mov esi, pRecord.cache			;copio desde el select cache, donde esta el texto copiado
		mov ecx,[pRecord.top]
		mov edx,ecx  
		.lp:
			lodsb						;entonces ya termine de copiar
			cmp al, ASCII.enter			;al == enter?
			je .newline					;si lo es, tengo que crear una nueva linea
			push dword eax					;sino pongo el caracter actual
			call [pRecord.mode]			;y lo inserto en el texto
			 
			xor eax,eax 
			loop  .lp
			jmp .end 
			.newline:					;para crear una nueva linea
				call lines.newline		;llamo  a crear linea
			loop .lp
		.end: 
		 mov [pRecord.top],edx 
		  
endSubR 0
;mueve todo el texto
	;call 
	;push dword start: ebp + 4
	;call text.move 
global text.moveforward
text.moveforward:
	startSubR
	;creo espacio en texto
	mov eax,[lines.last]
	push eax
	call lines.endline					;busco la ultima posicion de la ultima linea

	mov ecx, eax						;cuento cuanto me voy a mover:
	sub ecx,[ebp+4]						;la ultima pos del texto - la posicion actual
	inc ecx
	dec eax								;decremento eax porque es antes de la pos que me dan (antes del cursor)
	std
	lea edi,[text+eax+1]				;voy a copiar hacia la ultima pos del texto+1
	lea esi,[text+eax]					;desde la ultima pos del texto
	rep movsb							;repito ese movimiento
	
	;Actualizo los starts de las lineas anteriores:
	push dword [ebp+4]
	call lines.line						;pregunto por la linea de la posicion preguntada
	
	mov eax, [lines.current]
	lea edi,[lines.starts + 4*(eax+1)]	;copio hacia la linea modificada + 1
	lea esi,[lines.starts + 4*(eax+1)] 	;desde el mismo lugar, lo unico que voy a hacer es incrementar su valor
	
	mov ecx,[lines.last]				;cuento cuanto me muevo:
	sub ecx,eax  						;ultima linea-linea actual+1
	inc ecx
	cld
	.lp:
		lodsd							;eax = [esi], (principio de la linea a analizar)
		inc eax							;incremento su valor
		stosd							;y lo vuelvo a guardar
		loop .lp						;repito el ciclo las veces contadas
	.end:
	endSubR 4

;call:
	;push dword start: ebp + 4
	;call text.move
global text.movebackward
text.movebackward:
	startSubR
	mov eax, [ebp+4]						;eax = pos a partir de la cual voy a copiar
	dec eax	

	cmp eax, 0								;si estoy en el primer caracter
	jl .end									;entonces no borro

	push eax
	cmp byte[movCursor], 0
	je .cont
	mov byte[movCursor], 0
	call text.save
	.cont:
	pop eax

	mov dl, [text+eax]
	push edx								;guardo el caracter que voy a borrar para analizarlo luego
	lea edi, [text+eax]						;mi destino es la posicion actual						
	lea esi, [text+eax+1]					;mi origen es la posicion actual mas 1

	cld								
	mov ecx, [text.size]
	sub ecx, eax							;calculo las veces que voy a moverme: el tamano del text-pos
	cmp ecx, 1								;si estoy en la posicion final del texto
	jbe .end								;entonces no borro
	rep movsb 								;voy moviendo las palabras
	
	dec dword[cursor]						;decremento la posicion del cursor
	dec dword[text.size]					;decremento el tamano del texto

	;Actualizar las posiciones de lines.starts:
	push dword[ebp+4]						;pongo la linea actual como parametro
	call lines.line	
	mov ecx, [lines.last]					;para calcular cuato me tengo que mover
	sub ecx, eax							;la ultima linea - pos
	inc ecx

	mov eax, [lines.current]				;eax = linea actual
	pop edx									;edx = caracter que borre
	cmp edx, ASCII.enter					;el caracter que borre es fin de linea?
	jne .normal								;sino lo es, actualizo los valores normal
	jmp .eraseline							;de serlo, elimino la linea

	;Logica para borrar una linea:
	.eraseline:								;de serlo, elimino la linea
	push eax								;guardo la linea actual
	mov ebx, eax							;ebx = linea actual
	dec ebx									;ebx= la linea anterior a la actual
	push ebx
	call lines.endline						;pregunto por el final de esa linea
	dec eax
	mov [cursor], eax						;pongo el cursor en el final de la linea
	dec dword[lines.current]				;decremento mi linea actual (la linea actual es la que estoy borrando)
	pop eax									;recupero cual era mi linea actual
	
	dec dword[lines.last]					;decremento el valor de la ultima linea
	mov edx, [lines.lengths+4*eax]			;guardo la cantidad de caracteres de la linea q elimine	mov ebx, [lines.lengths]
	dec edx									;menos 1 porque voy a quitar el caracter de linea
	add [lines.lengths+4*(eax-1)], edx		;y a la linea anterior se le adiciona la cant de caracteres de la otra linea

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
	
	;Logica para el caso estandar, en el que no borro una linea
	.normal:								
	dec dword[lines.lengths+4*eax]			;decremento el tamano de la linea actual
	
	cld
	lea edi, [lines.starts+4*(eax+1)]		;copio hacia el principio de las lineas despues de la linea actual
	lea esi, [lines.starts+4*(eax+1)]		;desde el mismo lugar, lo unico que hago es aumentar el caracter en 1

	.lp:									;copio los valores
		lodsd								;busco cual valor tenia el inicio de linea
		dec eax								;decremento el inicio de las lineas
		stosd								;y lo vuelvo a guardar
		loop .lp							;repito el ciclo las veces calculadas


		mov eax,[pRecord.top]
		cmp eax,0
		je .changeP
		dec dword[pRecord.top]
		jmp .end 
		.changeP:
		cmp dword [pointC],1
		jne .changeM
		cmp dword [pointC + 8], erasetimes
		jne .changeM
		inc dword [pointC+4]
		jmp .end 
		.changeM:
		fillPointC 1,erasetimes 
		;logica para cambio de modo de pointC
	.end:
endSubR 4

;Borra lineas a partir de una posicion especifica
;call:
;push dword start: ebp + 8
;push dword times: ebp + 4
global text.deletelines
text.deletelines:
	startSubR
		push dword[ebp+8]
		call lines.line
		mov [lines.current], eax
		mov edx, eax
		add edx, [ebp + 4]			;le adiciono a la linea actual la cantidad de lineas que voy a copiar

		cmp edx, [lines.last]
		jbe .cont
		mov edx, [lines.last]
		.cont:
		mov [lines.current], edx
		push edx					;para acceder a la linea final
		call lines.endline			;busco el final de esa linea
		dec eax						;lo decremento en 1 por ser una posicion
		mov [cursor], eax			;pongo el cursor en el final de esa linea
		mov ecx, eax				;ecx = pos final
		mov eax, [ebp+8]			;eax = pos inicial
		sub ecx, eax				;ecx = pos final - pos inicial
		inc ecx						
		push ecx					;pongo las veces que se tiene que borrar como parametro
		call erasetimes				;y llamo para borrar las veces contadas
	endSubR 8

;push dword start: ebp + 16
;push dword end: ebp + 12
;push dword length: ebp + 8
;push dword dir pattern: ebp + 4
global text.find
text.find:
	startSubR
		mov eax, [ebp + 16]
		lea esi, [text+eax]					;comparo a partir del patron
		xor eax, eax						;limpio eax
		xor ecx, ecx  						;para indexar en el texto
		mov ecx, [ebp+16]
		xor edx, edx						;para indexar en el patron
		xor edi, edi
		cld
		.lp:
			lodsb							;al = caracter actual
			cmp ecx, [ebp+12]			    ;si ya se ha llegado al final del texto
			jae .end						;se termina
			.wh:
        		mov ebx, [ebp+4]			;indexar patron[edx]
        		add ebx, edx
				cmp byte[ignoreCase], 0			;esta activado el bit de ignorar las mayusculas?
				je .comp					;si no lo esta, hago la comparacion normal
				or al, 1 << 5				;si lo esta, el texto y el patron los pongo en minuscula
				or byte[ebx], 1<<5
				.comp:
        		cmp al, [ebx]				;el texto y el patron en la posicion actual son iguales?
        		je .cont					;si son iguales, continuo
        		cmp edx, 0					;es el indice 0?
        		jle .cont				    ;si es menor o igual que 0, entonces no puedo seguir la busqueda
        		dec edx						;si no, decremento edx
        		jmp .wh					    ;si es mayor que 0, entonces puedo seguir la busqueda
			.cont:
			mov ebx, [ebp+4]				;indexo patron[edx]
			add ebx, edx
			cmp byte[ignoreCase], 0			;esta activado el bit de ignorar las mayusculas?
			je .comp1					;si no lo esta, hago la comparacion normal
			or al, 1 << 5				;si lo esta, el texto y el patron los pongo en minuscula
			or byte[ebx], 1<<5
			.comp1:
			cmp al, [ebx]					;son el texto y el patron en las posiciones actuales iguales?
			jne .last						;si no lo son, salto a la ultima comparacion
			inc edx							;si lo son, incremento edx
			.last:
			inc ecx							;se incrementa las posiciones analizadas
			cmp edx, dword[ebp+8]			;se llego al final del patron?
			jne .lp							;si no se ha llegado, continuo el ciclo
			;Se macheo por completo el patron:
			mov edx, 0						;la posicion del patron se pone en 0
			push ecx						;se guarda temporalmente la posicion actual del texto
			sub ecx, [ebp+8]				;se le substrae a la posicion actual el tamano del patron, para guardar en donde empieza
			mov [search+4*edi], ecx			;en la posicion del macheo se pone la posicion actual
			pop ecx							;se recupera la posicion en la que se iba
			inc edi							;incremento el numero de macheos hasta ahora
			jmp .lp							;regreso hasta el principio del loop
		.end:
		mov eax, [ebp+8]					;eax = tamano del patron
		mov [patternLen], eax 				;se guarda en patternLen el tamano del patron
		mov [matchLen], edi					;guardo en matchLen la cantidad de macheos que hubo
	endSubR 16


;call:
;push dword mode: ebp + 12 (0 en la linea actual, 1 en todo el documento)
;push dword patternLen: ebp + 8
;push dword pattern: ebp + 4
global text.findline
text.findline:
	startSubR
		cmp dword[ebp + 12], 0
		je .modeline
		mov edx, [text.size]
		mov eax, 0
		jmp .find
		.modeline:
		mov ebx, dword[lines.current]		;copio en ebx la linea actual
		push ebx
		call lines.endline					
		mov edx, eax						;edx = final de linea de la linea actual
		mov eax, [lines.starts+4*ebx]		;eax = inicio de lina linea actual
		.find:
		push eax							
		push edx
		push dword[ebp+8]
		push dword[ebp+4]
		call text.find						;busco el patron en el texto desde el inicio de la linea hasta su final
	endSubR 12

;Para reemplazar texto
;call:
;push dword times: ebp + 8	(0 se substituye una sola ocurrencia, 1 se substituyen todas)
;push dword string: ebp + 4
global text.substitute
text.substitute:
	startSubR
		cmp dword[matchLen], 0				;si no hay ningun macheo
		je .end								;entonces no hago nada

		cld
		push dword[cursor]					;se guarda el lugar del cursor
		push dword[lines.current]			;se guarda la linea actual
		cmp dword[ebp+8], 0					;se quiere substituir una sola ocurrencia?
		jne .all							;si no, entonces se substituyen todas
		mov ecx, 1							;si se substituye una sola ocurrencia, entonces se pone el contador en 1
		jmp .wh								;se salta al principio del ciclo
		.all:								;para substituir todas las ocurrencias:
		mov ecx, [matchLen]					;se pone el contador en el total de macheos
		.wh:
			mov eax, [search+4*(ecx-1)]		;accedo al inicio de la busqueda actual
			mov [cursor], eax				;pongo el cursor en la pos de busqueda

			push eax
			call lines.line					;pregunto por la linea en la que se encuentra la busqueda
			mov [lines.current], eax		;y cambio la linea actual para dicha linea

			.cont:
			mov eax, [patternLen]
			add [cursor], eax				;ubico el cursor al final del patron
			push dword[patternLen]
			call erasetimes					;borro todos los caracteres del patron

			mov esi, [ebp+4]				;Empiezo a insertar la palabra en el texto
			xor eax, eax
			.lp:
				lodsb						;al = caracter del string
				cmp al, 0					;si al == 0
				je .continue				;entonces ya llegue al final del string
				push eax					;si no pongo el caracter
				call text.insert			;y llamo a insertar el caracter en el texto
				jmp .lp						;repito el ciclo hasta llegar al final del string
			.continue:
			loop .wh						;sigo con los otros macheos
		.end:
		pop dword[lines.current]			;recupero el valor de la inea actual
		pop dword[cursor]					;se vuelve a poner el cursor en su lugar
		mov dword[matchLen], 0
	endSubR 8

;Une una cantidad especifica de lineas
;call:
;push dword startline: ebp + 8
;push dword endline: ebp + 4
global text.join
text.join:
	startSubR
		mov ecx, [ebp+4]
		cmp ecx, [lines.last]
		jbe .lp
		mov ecx, [lines.last]
		.lp:
			mov edx, [lines.starts+4*ecx]
			mov [cursor], edx

			push edx
			call lines.line
			mov [lines.current], eax

			push dword[cursor]
			call text.movebackward

			push dword ' '
			call text.insert
			
			dec ecx
			cmp ecx, [ebp+8]
			jg .lp
	endSubR 8

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

;Determina la posicion donde se acaba la palabra sobre la cual esta el cursor
	;call:
	;push dword pos: ebp + 4
	;call lines.endword
	;return: eax -> posicion donde esta el final de palabra
global lines.endword
lines.endword:
	startSubR
		mov eax, [ebp+4]				
		lea esi, [text+eax]				;empiezo a analizar el texto desde lo que esta en la poscion del cursor
		mov ecx, eax					;llevo un contador de las veces que he adelantado, desde la pos de cursor
		xor eax, eax
		cld
		.lp:
			lodsb						;al = lo q esta en el text
			cmp al, ' '					;si es un caracter vacio, entonces ya es el final de la palabra
			je .end
			cmp al, ASCII.enter			;si el caracter es enter, entonces tambien es el final
			je .end
			cmp al, ASCII.tab			;si es tab termino tambien
			je .end
			inc ecx						;incremento si no he terminado la palabra
			jmp .lp
		.end:
		mov eax, ecx					;guardo para retornar la posicion del final
endSubR 4


;Borra desde el cursor hasta el principio de su linea
 ;push dword position: ebp + 4
 ;call eraseline
global eraseline
eraseline:
	startSubR
		push dword[lines.current]		
		call lines.startsline			;pregunto por el principio de mi linea actual
		mov ecx, [cursor]				;guardo la posicion del cursor
		sub ecx, eax					;las veces q me voy a mover: cursor-start
		push ecx
		call erasetimes					;llamo para borrar las veces calculadas
endSubR 4

;Borra en el texto a partir del cursor un numero determinado de veces
 ;call:
 ;push dword times: ebp + 4
global erasetimes
erasetimes:
	startSubR
		mov ecx, [ebp+4]				;pongo como contador lo especificado
		.lp:
			push dword[cursor]			
			call text.movebackward		;elimino desde la posicion del cursor
			loop .lp					;repito el ciclo tantas veces como las especificadas
			.end:
endSubR 4

;Determina la linea que ocupa una posicion determinada
	;call:
	;push dword posicion: ebp + 4
	;call text.line
	;return: eax -> numero de linea
global lines.line
lines.line:
	startSubR
		mov edx, [lines.last]			;empiezo a analizar desde la ultima linea
		.lp:
			mov eax, [lines.starts+4*edx]	;eax = principio de la linea a analizar
			cmp eax, [ebp+4]				;es la posicion del principio menor que la que estoy buscando?
			jbe .end						;si lo es, entonces ya determino que mi linea es la que analizo	

			dec edx							;sino decremento de linea
			cmp edx, 0						;si la linea es mayor o igual a 0
			jae .lp							;puedo continuar mi busqueda
		.end:
		mov eax, edx						;guardo en ax la ultima linea que analice, que es en donde esta la posiciom
endSubR 4

;Crea, si es posible, la linea en una posicion determinada
	;call: 
	;call lines.newline
global lines.newline
lines.newline:
	startSubR
		;1-calculo diferenciales: hago espacio para annadir valores nuevos
		
		;muevo lengths
		mov eax,[lines.last]				;empiezo desde la ultima linea
		lea edi,[lines.lengths + 4*(eax+1)]	;mi destino es la linea donde estoy +1
		lea esi,[lines.lengths + 4*eax]		;copio desde la linea actual
		std 
		mov ecx,eax							;calculo cuanto me voy a mover:ultima linea - actual
		mov eax,[lines.current]
		sub ecx,eax
		inc ecx
		rep movsd 							;empiezo a desplazar las lineas
		;muevo starts
		mov eax,[lines.last]			;hago lo mismo con los start
		lea edi, [lines.starts + 4*(eax+1)]
		lea esi, [lines.starts + 4*eax]
		std
		mov ecx,eax 
		mov eax,[lines.current] 
		sub ecx,eax 
		inc ecx
		rep movsd

		;ahora ya estan creados los espacios para escribir los nuevos valores, calculo  cursor-inicio y fin-cursor
		push dword ASCII.enter				;inserto el enter en el texto
		call text.insert

		push dword [lines.current]
		call lines.endline					;eax = fin de linea
		mov edx, eax						;salvo en edx
		push edx							;salvo fin de linea
		push dword [lines.current]
		call lines.startsline				;eax = inicio de linea
		
		mov edx,[cursor]
		sub edx,eax							;calculo cursor-inicio 
		pop eax 							;eax = fin de linea
		push edx 							;salvo cursor-inicio			
		mov edx ,[cursor]
		sub eax,edx							;calculo fin-cursor 
		mov edx, eax 						;salvo fin-cursor
		
		mov eax,[lines.current]
		mov [lines.lengths + 4*(eax+1)],edx	;tamanno de la nueva linea = fin-cursor
		pop edx								;recupero el tamano de la otra linea
		mov [lines.lengths +4*eax],edx 		;tamanno de la linea partida = cursor-linea +1 (mas uno lo que este se annade luego)	

		;Parche!!! Para decrementar el length de la ultima linea si no es donde se creo la nueva linea
		cmp eax, [lines.last]				;si cree la linea en la ultima linea, continuo
		je .continue
		
		mov eax, [lines.last]
		inc eax
		dec dword[lines.lengths+4*eax]		;si no, decremento el length de lo que sera la ultima linea

		.continue:
		;ajusto inicio de la linea nueva
		mov eax,[lines.current]
		push eax
		call lines.endline					;busco el final de la linea actual
		mov edx,eax							;edx = final
		mov eax,[lines.current]				;eax = linea actual
		mov dword[lines.starts + 4*(eax+1)],edx ;inicio de mi nueva linea:final de la otra + 1

		;muevo el text para crear espacio al fin de linea
		inc dword[lines.last]
		inc dword[lines.current]
endSubR 0

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
		jb .no 						;si lo es, entonces no se puede mover
		cmp edx, [lines.last]	;es la pos mayor que la ultima linea?
		ja .no 						;si lo es, entonces no se puede mover
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
		push dword[lines.current]	;pongo la linea actual como parametro
		call lines.endline 			;busco el final de la linea
	  	cmp ebx, eax				;se compara la posicion con el final de linea
	  	jae .no						;si es mayor, entonces no hay movimiento
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

		mov byte[movCursor], 1
		mov byte[moveV], 0			;si se movio horizontal, entonces el valor anterior del desplazamiento vertical se quita
		
		mov eax, [ebp+4]
		add dword[cursor], eax
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
		
		mov byte[movCursor], 1

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
		add eax, edx				;si no adiciono el principio con la cantidad de caracteres, 
		dec eax						;para obtener el final de linea, menos uno por ser la pos
		mov [cursor], eax			;pongo el cursor en el final de la linea
		mov al, [moveV]				;copio el valor del ultimo movimiento vertical
		cmp al, 0					;el valor esta actualizado?
		jne .end 					;si no lo esta, entonces finalizo
		mov [moveV], bl  			;sino, cambio su valor
		.end:
endSubR 4

;Para mover el cursor en el principio de una linea especifica
	;call:
	;push dword line: ebp + 4
	;call cursor.moveline
global cursor.moveline
cursor.moveline:
	startSubR
		mov eax, [ebp+4]
		cmp eax, [lines.last]
		jb .continue
		mov eax, [lines.last]
		.continue:
		mov edx, [lines.starts+4*eax]
		mov [cursor], edx
		mov [lines.current], eax
endSubR 4



;Para mover el cursor en la posicion de una busqueda
;call
;push dword dir: ebp + 4 (1 siguiente, -1 anterior con respecto a la pos de cursor)
global cursor.search
cursor.search:
	startSubR
		cmp dword[matchLen], 0				;si no hay ningun macheo
		je .end							;entonces no hace nada
		cmp dword[ebp+4], 0				;se compara el parametro para ver si se quiere ir a la derecha o hacia la izq
		jg .next						;si se quiere ir a la derecha, se mueve para la proxima busqueda
		.prev:							;si no, se mueve hacia la busqueda anterior
			dec dword[cursor]			;se decrementa temporalmente la pos de cursor para evitar moverse hacia la ocurrencia actual
			mov ecx, [matchLen]
			dec ecx						;eax sera ademas el contador de los macheos que se han visto
			lea esi, [search+4*ecx]		;se accede al ultimo elemento de la busqueda
			inc ecx
			std							;se empieaza a recorrer los principios de la busqueda de atras para adelante
			.lp1:
				lodsd					;eax = elemento actual
				cmp ecx, 0				;si ecx es 0, entonces se han visto todos los posibles macheos
				je .rest				;y se mueve hasta la ultima ocurrencia 
				dec ecx					;se decremente ecx
				cmp eax, [cursor]		;si la pos actual es mayor que la del cursor
				ja .lp1					;entonces no se ha encontrado la pos anterior y se continua el ciclo
			jmp .continue				;en eax queda la pos a la que moverse, se continua para setear los valores
			.rest:						;para reestablecer los valores:
			mov ebx, [matchLen]
			dec ebx
			mov eax, [search+4*ebx]		;eax = pos del ultimo macheo
			jmp .continue
		.next:
			inc dword[cursor]			;se incrementa la pos del cursor para no moverme sobre el mismo macheo
			cld		
			mov esi, search				;se empieza a analizar las posiciones desde el principio
			xor ecx, ecx				;ecx sera el contador para ver si se ha llegado al fin de linea
			.lp2:
				lodsd					;eax = pos actual
				cmp ecx, [matchLen]		;es ecx igual a la cantidad total de macheos?
				je .restart				;si lo es, entonces me muevo a la pos del primer macheo
				inc ecx					;incremento el contador
				cmp eax, [cursor]		;si la pos actual es menor a la del cursor
				jb .lp2					;entonces se continua el ciclo
			jmp .continue				;se pasa para setear los valores
		.restart:
		mov eax, [search]				;se pone la pos como la pos del primer macheo
		.continue:
		mov [cursor], eax
		push eax						;pongo la poscion como parametro
		call lines.line					;y pregunto por la linea de esa posicion
		mov [lines.current], eax		;la linea actual nueva es la buscada
		.end:
	endSubR 4

;HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
;HHHHHHHHHHHHHHHHH SELECT CONTROL HHHHHHHHHHHHHHHH
;HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH 

;Empieza una seleccion
	;call:
	;push dword mode (0 normal, 1 linea, 2 bloque)
global select.mark
select.mark:
	startSubR
		mov eax, [cursor]
		mov  [select.start], eax			;la posicion del cursor es el principio de mi seleccion
		mov eax, [ebp+4]			
		mov [select.mode], eax				;copio el modo que se pasa como parametro
	endSubR 4

;Para cambiar el modo de una seleccion
;call:
;push dword mode (0 normal, 1 linea, 2 bloque)
global select.changemode
select.changemode:
	startSubR
		mov eax, [ebp+4]
		mov [select.mode], eax
	endSubR 4

;Mueve el cursor en el principio de la seleccion
global select.movestart
select.movestart:
	startSubR
		mov eax, [select.start]
		mov [cursor], eax

		push eax
		call lines.line
		mov [lines.current],eax
	endSubR 0

;Para copiar una porcion del texto
	;call:
	;call select.copy
global select.copy
select.copy:
	startSubR
		mov eax,[select.start]				;eax = inicio de seleccion
		mov edx,[cursor]					;edx = pos del cursor
		cmp eax,edx							;es eax <= edx ?
		jbe .mode							;si lo es, ya empiezo a seleccionar
		
		push eax							;si eax > edx, entoces los intercambio 
		push edx							;para que el principio este en eax y el final en edx
		pop eax
		pop edx 

	.mode:
		push edx							;pongo los parametro de la seleccion independientemente del modo
		push eax							;en edx el final y en eax el principio
		cmp dword [select.mode],select.mode.normal	;el modo es normal?
		jne .tryline						;si no lo es, miro si es linea
		call select.copy.normal				;de serlo, copio en modo normal
		jmp .end							;y termino

	.tryline:
		cmp dword [select.mode],select.mode.line	;el modo es linea?
		jne .tryblock						;de no serlo, es bloque
		call select.copy.line				;si lo es, copio en modo linea
		jmp .end							;salto al final

	.tryblock:
		call select.copy.block 

	.end:
	;guardo los datos de la copia
	mov eax,[select.start]
	mov [copy.start],eax
	mov eax,[select.mode]
	mov [copy.mode],eax
endSubR 0

;copia en intervalo
	;call:
	;push dword end: ebp + 8
	;push dword start: ebp + 4
	;call select.copy.normals
global select.copy.normal
select.copy.normal:
	startSubR
		mov eax,[ebp+4]					;eax = principio de la copia
		mov edx,[ebp+8]					;edx = final de la copia

		cmp edx, [text.size]
		jbe .cont
		mov edx, [text.size]
		.cont:
		;Se copiaria, desde el principio de la linea hasta el final de mi linea actual
		mov ecx, edx					;la cantidad de movimientos q hago:					
		sub ecx, eax					;el final - inicio de la copia
		inc ecx
		lea esi, [text+eax]				;copio desde el texto a partir del inicio
		mov edi, select.cache			;copio hacia el cache de la copia
		rep movsb						;voy moviendo de un lugar a otro las veces calculadas
		xor al,al
		stosb							;al final de la copia pongo 
endSubR 8
	
	;call:
	;push dword address ebp+12
	;push dword end: ebp + 8
	;push dword start: ebp + 4
	;call select.copy.normal
global copy.normal
copy.normal:
	startSubR
		cld 
		mov eax,[ebp+4]					;eax = principio de la copia
		mov edx,[ebp+8]					;edx = final de la copia
		;Se copiaria, desde el principio de la linea hasta el final de mi linea actual
		mov ecx, edx					;la cantidad de movimientos q hago:					
		sub ecx, eax					;el final - inicio de la copia
		inc ecx
		lea esi, [text+eax]				;copio desde el texto a partir del inicio
		mov edi, [ebp+12]			;copio hacia el cache de la copia
		rep movsb						;voy moviendo de un lugar a otro las veces calculadas
		xor al,al
		stosb							;al final de la copia pongo 
		mov eax,edi
endSubR 12

;Guarda la copia en modo linea
	;call:
	;push dword end ebp+8
	;push dword start ebp+4
	;call select.copy.line
select.copy.line:
	startSubR
		push dword[ebp+8]				;pongo mi la posicion final como parametro
		call lines.line					;pregunto por la linea de dicha seleccion
		mov edx, eax
		
		push dword[ebp+4]				;pongo donde empieza mi seleccion como parametro
		call lines.line					;pregunto por la linea de mi seleccion
	
		push edx
		push eax
		call copy.line
endSubR 8

;call:
;push dword endline: ebp + 8
;push dword startLine: ebp + 4
;call copy.line
global copy.line
copy.line:
	startSubR
		mov eax, [ebp+8]
		cmp eax, [lines.last]
		jbe .cont
		mov eax, [lines.last]
		.cont:
		push eax 						;pongo la linea como parametro
		call lines.endline				;busco el final de la linea final
		mov edx, eax					;edx = pos final de la linea final
		
		mov ebx, dword[ebp+4]
		mov eax, [lines.starts+4*ebx]	;eax principio de la linea actual

		;Se copiaria, desde el principio de la linea hasta el final de mi linea actual
		mov ecx, edx					;la cantidad de movimientos q hago:					
		sub ecx, eax					;la pos final - pos inicial
		lea esi, [text+eax]				;empiezo a copiar desde el texto en la posicion del principio
		mov edi, select.cache			;hacia el select cache
		rep movsb						;y copio desde un lugar a otro la cantidad de veces calculada
		xor al,al						
		stosb							;al final de mi copia pongo 0
endSubR 8


;push end ebp + 8
;push start ebp+4
select.copy.block:
	startSubR
	 
	mov edi,select.cache
	;calculo la cantidad de lineas que componen el bloque
	;calculo linea final
    push dword [ebp+8]
    call lines.line
    mov ecx,eax                	;calculo cual es la linea final  
    ;calculo caracter final
    push eax 					;salvo linea final
    call lines.startsline
    mov ebx,[ebp+8]
    sub ebx,eax					;ebx = caracter final
    ;calculo linea inicial
    push dword [ebp+4]
    call lines.line
    push eax 					;salvo linea inicial
    ;calculo caracter inicial
    push eax					;se consume con el llamado de abajo
    call lines.startsline		;donde empieza la inicial
    mov edx,[ebp+4]
    sub edx,eax    				;edx = comienza inicial
    pop eax
    

    sub ecx,eax					;ecx = cantidad de lineas del bloque
    inc ecx
    .lp:
    mov [var],eax
    push eax
    push eax
    call lines.startsline
    cmp ebx,edx                 ;veo si hay que invertir los valores para enviarselos a select.normal
    ja .invert
    add eax,edx
    push eax 
    sub eax,edx
    add eax,ebx
    push eax 
    jmp .normalcall
    .invert:            ;arreglo de orden de pushs. primero end luego start
    add eax,ebx
    push eax 
    sub eax,ebx
    add eax,edx
    push eax
    .normalcall:
    push dword[var]                                       ;dword[var] tiene la linea actual
    call lines.endline                            
    pop  dword[var +4]                                    ;dword[var +4] = inicio
    push dword[var +4]                                    ;para usar registro y salvar su valor
    cmp dword[var +4],eax                                 ;comparo el final de la linea con el inicio de la seleccion
    jb .trycutend                              ;intento ver que pasa con el final
    jmp .nextline                               ;salto de linea
    .trycutend:                                 ;limito si el final de linea es menor que el final entonces el final es el final de linea
    pop dword[var +4]                                     ;dword[var +4] = inicio
    pop dword[var]                                     ;dword[var] = final
	push edi 
	cmp [var],eax                                 
    jae .cutend 
    push dword[var]
    push dword[var +4]
    jmp .copyrange
    .cutend:
    mov [var],eax
    dec dword[var] 
    push dword[var]
    push dword[var +4]
    .copyrange:
    call copy.normal
    mov edi,eax
	jmp .endlp
    .nextline:
    pop eax
    pop eax
    .endlp:
    pop eax
    inc eax

	dec ecx 
    cmp ecx,0
	je .end 
	jmp .lp
	.end:
endSubR 8


select.paste.block:
	startSubR
	
	mov esi,select.cache

	;calculo caracter inicial
	push eax					;se consume con el llamado de abajo
	call lines.startsline		;donde empieza la inicial
	mov edx,[ebp+4]
	sub edx,eax    				;edx = comienza inicial
endSubR 8

;Pega lo guardado en select.cache en el texto desde la posicion del cursor
global select.paste
select.paste:
	startSubR
		mov esi, select.cache			;copio desde el select cache, donde esta el texto copiado
		.lp:
			lodsb						;al = caracter que va a ser copiado
			cmp al, 0					;si al = 0
			je .end						;entonces ya termine de copiar
			cmp al, ASCII.enter			;al == enter?
			je .newline					;si lo es, tengo que crear una nueva linea
			push eax					;sino pongo el caracter actual
			call text.insert			;y lo inserto en el texto
			jmp .lp
			.newline:					;para crear una nueva linea
				call lines.newline		;llamo  a crear linea
				jmp .lp
		.end: 
endSubR 0

;Inserta una palabra en cada linea de la seleccion en modo bloque
;push dword end: ebp + 16
;push dword start: ebp + 12				;cantidad de lineas que tiene que copiar
;push dword lenWord:ebp + 8
;push dword dirWord:ebp + 4
global block.insert
block.insert:
	startSubR		
		cmp dword[ebp+8], 0
		je .end
		
		push dword[ebp+16]					;Para obtener la cantidad de lineas que tengo que copiar:
		call lines.line
		mov ecx, eax
		push dword[ebp+12]
		call lines.line
		sub ecx, eax 						;ecx = linea del final de la seleccion - linea del principio de la seleccion
       
	   	mov edx, [lines.starts+4*eax]
		mov ebx, [ebp+12]
		sub ebx, edx						;ebx = posicion a partir del principio de linea en la cual tengo que insertar la palabra
		mov edx, eax						;edx = primera linea de seleccion
		inc edx								;en la primera linea ya esta insertada la palabra, asi que me la salto
		cld
		.lp:								;por cada linea:
			mov eax, [lines.lengths+4*edx]
			dec eax
			cmp eax, ebx					;es la longitud de mi linea actual menor que la posicion a partir de la cual voy a copiar?
			jb .continue					;si lo es, entonces continuo, no insertando la palabra en el texto
			;Insertando la palabra:
			mov eax, [lines.starts+4*edx]
			add eax,ebx						;busco la posicion en que tengo que empezar a insertar: principio de linea + movimiento de seleccion
			mov [cursor], eax				;pongo el cursor en la posicion de insercion
			mov [lines.current], edx		;y la linea actual en la linea en que se situa el cursor			
			push ecx						;guardo temporalmente la cantidad de movimientos que tenia contados
			mov ecx, [ebp+8]				;la cantidad de movimientos que hago ahora: la longitud de la palabra
			xor eax, eax
			mov esi, [ebp+4]				;copio desde mi palabra
			.wh:							;Inserto la palabra:
				lodsb						;al = caracter de la palabra actual
				push eax
				call text.insert			;inserto el caracter en el texto en la pos del cursor
				loop .wh					;repito el ciclo
			pop ecx							;recupero el valor de ecx
			.continue:						;continuo el loop:
			inc edx							;incremento la linea que estoy analizando
			loop .lp						;y repito el ciclo
		.end:
	endSubR 16


global text.save  
text.save:
startSubR
	;orden: cursor,current,last,size,starts,length,text 
	mov eax,[undopivot]
	lea edi,[undo + 4*eax] 
	cld
	mov eax,[cursor]  
	stosd 
	mov eax,[lines.current]  
	stosd
	mov eax,[lines.last]  
	stosd
	mov eax,[text.size]
	stosd 

	mov ecx,500
	mov esi,lines.starts
	rep movsd
	mov ecx,500
	mov esi,lines.lengths
	rep movsd

	mov ecx,2000
	mov esi,text 
	rep movsd
	
	add dword[undopivot],3004
endSubR 0

global text.load   
text.load:
startSubR
	;orden: cursor,current,last,size,starts,length,text 
	mov eax,[undopivot]
	sub eax,3004
	lea esi,[undo + 4*eax] 
	cld
	
	lodsd
	mov [cursor],eax  
	lodsd 
	mov [lines.current],eax   
	lodsd
	mov [lines.last],eax   
	lodsd
	mov [text.size],eax 
	 

	mov ecx,500
	mov edi,lines.starts
	rep movsd
	mov ecx,500
	mov edi,lines.lengths
	rep movsd

	mov ecx,2000
	mov edi,text 
	rep movsd

	cmp dword[undopivot], 3004
	je .end
	sub dword[undopivot],3004 
	.end:
endSubR 0