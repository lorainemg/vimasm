%include "tools.mac"
%include "keys.mac"

extern getChar, isKey1, checkKey1
extern video.Update, vim.update, videoflags, showpos, tabsize
extern text.find, text.size, text.substitute, text.findline, text.deletelines, copy.line, text.join, text.save
extern lines.starts, lines.current, ignoreCase, lines.last

section .bss
global ctext
ctext 	resb 80
string 	resb 80
pattern	resb 80
num 	resb 40

section .data
global ccursor
ccursor 		dd 0
global top
top 			dd 0
numLen			dd 0		;la cantidad de digitos de un numero

;Comandos a machear:
worddelete   	db 'delete ', 0
wordyank 		db 'yank ', 0
wordjoin		db 'join ', 0
wordset 		db 'set ', 0
wordhlsearch 	db 'hlsearch', 0
wordignorecase	db 'ignorecase', 0
wordruler		db 'ruler', 0
wordno 			db 'no ', 0
wordtabstop		db 'tabstop=', 0

;Para parsear el reemplazado del texto
;El parametro indica (0 en la linea actual, 1 en todo el documento)
%macro substitute 1
	xor edx, edx
	cld
	%%.lp:
		lodsb						;al = caracter del texto actual
		cmp al, '/'					;si al = '/', entonces ya se llego al caracter final de la palabra
		je %%.cont					;asi que continuo parseando la expresion
		cmp ecx, [top]				;si la pos acutual es mayor que el tope
		ja %%.false					;entonces ya llegue a la ultima pos del texto y no es un comando valido xq falta el substituto
		inc edx
		inc ecx						;en otro caso, incremento el contador actual
		stosb						;guardo el caracter del texto actual en la variable de busqueda
		jmp %%.lp						;repito el ciclo
	%%.cont:							;Continuando copiando el string para reemplazar el patron
	inc ecx
	lea esi, [ctext+ecx]			;empiezo desde la pos actual + 1 a copiar el string
	mov edi, string					;copio hacia el string
	%%.lp1:
		lodsb						;cargo: al = caracter actual del texto
		cmp al, '/'					;si al == '/'
		je %%.all						;entonces ya termine de copiar el patron, y voy a proceder a copiar todas las ocurrencias del patron
		cmp ecx, [top]				;si la pos actual es mayor que el tope
		ja %%.end						;entonces ya termine de copiar la palabra
		inc ecx						;en otro caso incremento ecx
		stosb						;copio el caracter para reemplazar
		jmp %%.lp1					;repito el ciclo
	%%.end:
	;Llamar a buscar el texto y reemplazar la primera ocurrencia de la linea actual
	mov dword[edi], 0
	push %1
	push edx
	push pattern
	call text.findline
		
	push 0
	push string
	call text.substitute
	mov eax, 1
	jmp %%.return	
	%%.all:							;Para cambiar todas las ocurrencias:
	mov dword[edi], 0
	inc ecx							;incremento la pos actual
	mov al, [ctext+ecx]
	cmp al, 'g'						;lo que hay siguiente es 'g'
	jne %%.false						;si no lo es, entonces no es un comando valido
	;Llamo a buscar el texto y reemplazar todas las ocurrencias de la linea actual:
	push %1
	push edx
	push pattern
	call text.findline
	push 1
	push string
	call text.substitute
	mov eax, 1
	jmp %%.return
	%%.false:
	xor eax, eax
	%%.return:
%endmacro

;Macro para determinar si una palabra es match con otra
;call: ismatch match (palabra a machear), pos (la posicion desde la cual se quiere empezar a leer en el texto), label (etiqueta a la cual se salta si es match)
%macro ismatch 3
	push dword %1
	push dword %2
	call match					;busco si el patron machea con 'yank'
	cmp eax, 1					;si machea, salto a la etiqueta
	je %3
%endmacro

section .text
global start.command
start.command:
    startSubR
		call ctext.erase
        mov dword[top], 1
		mov byte[ctext], 0
		mov dword[ccursor], 0
    endSubR 0


global mode.command
mode.command:
    	;Veo si escribo una palabra
		call getChar				;obtiene el caracter de la tecla que se presiono
		cmp eax, 0 					;si no se presiona ninguna tecla
		je .command				    ;entonces se salta hasta el final
		push eax				    ;se guarda el caracter en la pila como parametro de text.write
		call ctext.insert	        ;se procede a escribir el caracter en el texto	call UpdateBuffer
		jmp .end

        .command:
        ;Otros  comandos:
		checkKey1 key.left,  .moveleft			;Comprueba si se presiono la tecla izq 
		checkKey1 key.right, .moveright			;Comprueba si se presiono la tecla der 

        checkKey1 key.backspace, .erase
		checkKey1 key.enter, 	 .enter 		;Comprueba si se presiono enter
		checkKey1 key.esc,       .exitmode 	

        jmp .end2
        ;---------------------------------------------------------------------------------------------------
		.moveright:					;mueve el ccursor a la derecha
			push dword 1
			call ccursor.move		
			jmp .end
		.moveleft:					;mueve el ccursor a la izquierda
			push dword -1
			call ccursor.move
			jmp .end

        .erase:
        ;Logica para borrar
		push dword[ccursor]			;para borrar mueve el texto hacia la izq desde la posicion del ccursor
		call ctext.movebackward
		cmp eax, 0
		je .exitmode
		jmp .end        
        .enter:
        ;Logica para presionar enter
        call stringCmd
		ret
        ;Busca un comando valido, si lo es, lo ejecuta, si no emite un mensaje de comando no valido
        ;Despues sale al modo normal
        .exitmode:
        ret

    .end:
    call video.Update
    .end2:
	call vim.update
    jmp mode.command
ret

;Para borrar lo que esta guardado en el text del modo comando
;call:
;call ctext.erase
ctext.erase:
    startSubR
        mov ecx, [top]          ;la cantidad de movimientos es la cantidad de caracteres insertados
        mov edi, ctext           ;mi destino es el texto
        mov al, 0               ;en al pongo 0
		cld
        rep stosb               ;y repito ese movimiento las veces calculadas
        mov dword[top], 0       ;el tope es ahora 0
        mov dword[ccursor], 0    ;y el ccursor esta en la posicion 0
    endSubR 0


;call:
;push dword ascii: ebp + 4
;call text.insert
ctext.insert:
	startSubR
		push dword[ccursor]
		call ctext.moveforward

		mov ebx,ctext  					;ebx =text
		add ebx,[ccursor]				;ebx = text + ccursor
		mov al,[ebp+4]   				;guardo 
		mov [ebx],al					;[text + ccursor] = ASCII
	    
		mov ebx, [ccursor]
		mov edx, [ctext]
	
	    inc dword [ccursor]				;incremento la posicion del ccursor
	endSubR 4

;mueve todo el texto
	;call 
	;push dword start: ebp + 4
	;call text.move 
ctext.moveforward:
	startSubR
	    ;creo espacio en texto
        mov eax, [top]
		mov ebx, [ebp+4]

	    mov ecx, eax						;cuento cuanto me voy a mover:
	    sub ecx,[ebp+4]						;la ultima pos del texto - la posicion actual
	    inc ecx
	    dec eax								;decremento eax porque es antes de la pos que me dan (antes del ccursor)
	    std
	    lea edi,[ctext+eax+1]				;voy a copiar hacia la ultima pos del texto+1
	    lea esi,[ctext+eax]					;desde la ultima pos del texto
	    rep movsb							;repito ese movimiento
        inc dword[top]						;incremento el tope del texto
	endSubR 4


;call:
	;push dword start: ebp + 4
	;call text.move
ctext.movebackward:
	startSubR
	mov eax, [ebp+4]						;eax = pos a partir de la cual voy a copiar
	dec eax	

	cmp eax, 1		 						;si estoy en el primer caracter
	jl .exit								;entonces no borro

	lea edi, [ctext+eax]					;mi destino es la posicion actual						
	lea esi, [ctext+eax+1]					;mi origen es la posicion actual mas 1

	cld								
	mov ecx, [top]
	sub ecx, eax							;calculo las veces que voy a moverme: el tamano del text-pos
	cmp ecx, 0								;si estoy en la posicion final del texto
	jl .end									;entonces no borro
	rep movsb 								;voy moviendo las palabras
	
	dec dword[ccursor]						;decremento la posicion del ccursor
	dec dword[top]				        	;decremento el tamano del texto
	jmp .end
	.exit:
	xor eax, eax
	jmp .return
    .end:
	mov eax, 1
	.return:
	endSubR 4

;Mueve el ccursor horizontalmente
;call:
;push dword dir (1 derecha, -1 izquierda): ebp + 4
global ccursor.move
ccursor.move:
	startSubR
		mov eax, [ccursor]
		add eax, [ebp+4]

		cmp eax, 1
		jl .end
		cmp eax, [top]
		jge .end
		mov [ccursor], eax
	.end:
	endSubR 4

;Para buscar si lo escrito en el text es un comando valido
;call:
;call stringCmd
stringCmd:
    startSubR		
		ismatch wordset, 1, .set			;intento machear un comando set
		xor edx, edx
		mov dl, [ctext+1]					;dl = caracter despues de ':'
		inRange 48, 57, dl					;si le sigue un numero
		cmp eax, 1							;entonces hago las operaciones delete, yank o join a partir de una pos
		je .operation
		cmp dl, '/'							;si dl = '/', entonces se hace una busqueda
		je .find
		cmp dl, 's'							;si dl = 's', entonces se llama para reemplazar texto
		je .replace
		cmp dl, '%'							;si dl = '%', entonces se reemplazan las ocurrencias en todo el documento
		je .replaceAll
		ismatch worddelete, 1, .delete		;intento machear la palabra 'delete '
		ismatch wordyank, 1, .yank			;intento machear la palabra 'yank '
		ismatch wordjoin, 1, .join			;intento machear la palabra 'join '

		jmp .end

		.find:
		;Para buscar un patron en el texto
        call find
		jmp .end
		.replace:
		;Para reemplazar un patron en la linea actual
		call replace
		jmp .end
		.replaceAll:
		;Para reemplazar un patron en todo el texto
		call replaceAll
		jmp .end
		.delete:		
		;Para eliminar una cantidad especifica de lineas en todo el texto a partir de la linea actual
		push dword 8
		push dword[lines.current]
		call delete
		jmp .end
		.yank:
		;Para copiar una cantidad especifica de lineas a partir de la linea actual 
		push dword 6
		push dword[lines.current]
		call yank
		jmp .end
		.join:
		;Para juntar una cantidad especifica de lineas a partir de la linea actual
		push dword 6
		push dword[lines.current]
		call join
		jmp .end
		.operation:
		;Para realizar las operaciones de delete, yank o join a partir de una linea especifica
		call initOp
		jmp .end
		.set:
		;Para setear preferencias
		call set
		jmp .end
        .end:
    endSubR 0

;Comando para buscar un patron en el texto
;call find
find:
    startSubR
        lea esi, [ctext+2]				;comienzo desde la pos 2, para saltar ':/'
        mov edi, pattern				;lo copio en la variable busqueda
        mov ecx, [top]					;cuento cuanto tengo que copiar:
        sub ecx, 3						;todo los caracteres del texto - 2, para saltar ':/'
		mov eax, ecx					;eax = la longitud del patron
		rep movsb						;empiezo a copiar las palabras
		
		push dword 0
		push dword[text.size]
		push eax						;pongo la longitud del patron como parametro
		push pattern					;pongo la direccion del patron
		call text.find  				;llamo para buscar el patron en el texto
    endSubR 0
 
;Comando para reemplazar un patron en el texto
;call replace
replace:
	startSubR
		cmp byte[ctext+2], '/'			;si lo que le sigue a ':s' no es '/', entonces no es un comando valido			
		jne .false						;asi que salto para false
		lea esi, [ctext+3]				;empiezo a copiar desde el 3er caracter (saltando ':s/')
		mov edi, pattern				;hacia la variable de busqueda
		mov ecx, 3						;la pos actual es 3
		
		substitute 0					;llamo a substituir el texto en la linea actual
		cmp eax, 0
		je .end
		call text.save
		jmp .end
		.false:
		xor eax, eax
		jmp .end
		.end:
	endSubR 0

;Comando para reemplazar un patron en todo el texto
;call replaceAll
replaceAll:
	startSubR
		cmp byte[ctext+2], 's'			;si lo que le sigue a ':%' no es 's', entonces no es un comando valido			
		jne .false						;asi que salto para false
		cmp byte[ctext+3], '/'			;si lo que le sigue a ':/%s' no es '/', entonces no es un comando valido
		jne .false
		lea esi, [ctext+4]				;empiezo a copiar desde el 4to caracter (saltando ':%s/')
		mov edi, pattern				;hacia la variable de busqueda
		mov ecx, 4						;la pos actual es 3

		substitute 1					;llamo a substituir el texto en todo el documento
		cmp eax, 0
		je .end
		call text.save
		jmp .end
		.false:
		xor eax, eax
		jmp .end
		.end:
	endSubR 0

;Comando para eliminar a partir de una linea 
;call:
;push dword pos: ebp + 8	(posicion a partir del texto del cual se va a empezar a parsear el numero)
;push dword start: ebp + 4	(linea a partir del cual se va eliminar)
delete:
	startSubR
		push dword[ebp+8]
		call getNum					;llamo para obtener un numero despues de la posicion 8 en el texto
		push eax
		call text.save	
		pop eax
		mov edx, eax				;edx = cantidad de lineas que se quieren eliminar
		dec edx						
		mov ebx, [ebp+4]
		mov eax, [lines.starts+4*ebx]	;eax = inicio de la linea a partir de la cual quiero eliminar
		push eax
		push edx
		call text.deletelines		;elimino desde la pos inicial la cantidad de lineas determinada
		.end:
	endSubR 8

;Comando para copiar a partir de una linea
;call:
;push dword pos: ebp + 8	(posicion a partir del texto del cual se va a empezar a parsear el numero)
;push dword start: ebp + 4	(linea a partir del cual se va eliminar)
yank:
	startSubR
		push dword[ebp+8]
		call getNum					;busco un numero despues de la posicion 6		
		mov edx, eax				;edx = cantidad de lineas a copiar
		dec edx
		;Llamando a copiar lineas:
		add edx, [ebp+4]			;edx = linea final a copiar
		push edx
		push dword[ebp+4]
		call copy.line				;llamo a copiar desde la linea inicial hasta la final
		.end:
	endSubR 8

;Comando para juntar dos lineas
;call:
;push dword pos: ebp + 8	(posicion a partir del texto del cual se va a empezar a parsear el numero)
;push dword start: ebp + 4	(linea a partir del cual se va eliminar)
join:
	startSubR
		push dword[ebp+8]					
		call getNum					;obtengo un numero desde la pos del texto para obtener la cantidad de lineas que tengo que juntar
		push eax
		call text.save
		pop eax
		mov edx, eax
		;Llamando a copiar lineas:
		add edx, [ebp+4]			;edx = ultima linea que tengo que juntar
		push dword[ebp+4]
		push edx
		call text.join
		.end:	
	endSubR 8

;Para obtener el inicio de las operaciones delete, join y yank
initOp:
	startSubR
		push dword 1
		call getNum							;llamo para obtener un numero a partir de la pos 1
		dec eax
		cmp eax, [lines.last]
		jae .end2
		push eax							;guardo el numero en pila

		mov edx, [numLen]
		cmp byte[ctext+edx], ' ' 			;es lo que le sigue al numero un espacio?
		jne .end							;si no lo es, entonces no es un comando valido, asi que termino

		inc edx					
		ismatch worddelete, edx, .delete	;intento machear la palabra 'delete '
		ismatch wordyank, edx, .yank		;intento machear la palabra 'yank '
	;	ismatch wordjoin, edx, .join		;intento machear la palabra 'join '

		jmp .end
		.delete:
		;Elimina a partir de una pos en especifica (la pos ya esta en la pila)
			pop eax							;recupero el numero
			add edx, 7 						;a la pos donde termino el numero le sum el len de 'delete '
			push edx						;parseo el resto de la expresion a partir de la pos
			push eax						;y pongo la linea a partir de la cual se empieza a eliminar
			call delete						;y llamo a eliminar	
			jmp .end2
		.yank:
		;Copia a partir de una pos en especifica
			pop eax
			add edx, 5
			push edx
			push eax
			call yank
			jmp .end2
		.join:
		;Junta una cantidad especifica de linea a partir de una pos
			pop eax
			add edx, 5
			push edx
			push eax
			call join
			jmp .end2
		.end:
			pop eax
		.end2:
	endSubR 0

;call:
;push dword start: ebp + 4 (comienzo con respecto a ctext donde se quiere empezar a obtener el numero)
getNum:
	startSubR
		mov eax, [ebp+4]			
		lea esi, [ctext+eax]		;copio desde el texto a partir del principio dado
		mov edi, num				;hacia la variable num
		mov ecx, eax				;el contador empieza a partir de la posicion de inicio
		xor eax, eax
		cld
		.lp:
			lodsb					;al = caracter actual
			mov edx, eax			;edx = caracter actual (inRange no funciona con eax)
			inc ecx	
			inRange 48, 57, dl		;pregunto si el caracter es un numero
			cmp eax, 0				;si no es un numero
			je .end					;entonces termino la ejecucion
			mov eax, edx			;eax = caracter numerico actual
			cmp ecx, [top]			;si ya llegue a mi tope
			jge .end				;entonces igualmente termino la ejecucion
			stosb					;pongo en num el numero actual
			jmp .lp					;repito el ciclo
		.end:
		dec ecx						;resto ecx menos el principio menos 1 porque incrementa 1 vez de mas
		mov [numLen], ecx
		sub ecx, [ebp+4]			;para obtener en ecx la cantidad de digitos del numero
		push num					;pongo el numero escrito con caracteres como parametro
		push ecx					;pongo la cantidad de digitos
		call getNumberFromASCII		;y obtengo en eax el numero a partir de dicho string
	endSubR 4

;Para ver si un comando machea con una palabra a partir de una posicion
;call:
;push dword word: ebp + 8
;push dword start: ebp + 4
match:
	startSubR
		mov eax, [ebp+4]
		lea esi, [ctext+eax]		;empiezo a copiar desde el inicio del texto
		xor ecx, ecx				;ecx = contador para ver en que posicion esta
		xor edx, edx				;edx = estara ubicado la direccion de caracter actual a analizar
		xor eax, eax				;eax = caracter del texto actual a analizar
		mov ebx, [ebp+8]			;ebx = dir de la palabra a copiar
		cld
		.lp:
			lodsb					;accedo al proximo caracter y lo pongo en eax
			lea edx, [ebx+ecx]		;edx = dir del caracter de la posicion actual a analizar 
			cmp byte[edx], 0		;si lo que hay en edx es 0, entonces ya llegue al final
			je .true				;y termino el ciclo, la palabra macheo por completo
			cmp al, [edx] 			;se compara el caracter del texto actual con el del patron
			jne .false				;si no son iguales, entonces las 2 palabras no son iguales
			inc ecx					;incremento la pos actual
			jmp .lp					;vuelvo al ciclo
		.true:
		mov eax, 1					;si se macheo dejo en eax true
		jmp .end					;y termino
		.false:
			xor eax, eax				;si no macheo, en eax dejo 0
	.end:
	endSubR 8


;Para parsear una expresion con set
set:
	startSubR
		ismatch wordhlsearch, 5, .hlsearch	;busco si a partir de la pos 5 del txt machea 'hlsearch ', y si lo hace salto para la etiqueta
		ismatch wordignorecase, 5, .igncase	;busco si a partir de la pos 5 del txt machea 'ignorecase '
		ismatch wordruler, 5, .ruler		;busco si a partir de la pos 5 del txt machea 'ruler '
		ismatch wordtabstop, 5, .tabs		;busco si a partir de la pos 5 del txt machea 'tabstop '

		ismatch wordno, 5, .no				;busco si a partir de la pos 5 del txt machea 'no '
		jmp .end

		.hlsearch:
		;Desactivo el bit de esconder la busqueda
			and byte[videoflags], ~1<<2	
			or byte[videoflags], 1<<1
			jmp .end
		.igncase:
		;Activo la ignoracion de las mayusculas en el macheo del patron
			mov byte[ignoreCase], 1
			jmp .end
		.ruler:
		;Poner las posiciones del cursor
			mov	byte[showpos], 1
			jmp .end
		.tabs:
		;Cambiar el tamano de los tabs
			mov eax, 13
			push eax
			call getNum						;A partir de la pos 13 intento obtener un numero
			mov [tabsize], eax				;y cambio el tamano de los tab por el especificado
			jmp .end
		
		.no:
		;Para desactivar los comandos:
			ismatch wordhlsearch, 8, .nohlsearch	;busco si a partir de la pos 5 del txt machea 'hlsearch '
			ismatch wordignorecase, 8, .nocase		;busco si a partir de la pos 5 del txt machea 'ignorecase '
			ismatch wordruler, 8, .noruler			;busco si a partir de la pos 5 del txt machea 'ruler '

			jmp .end
			.nohlsearch:
			;Activar el bit para esconder las busquedas:
				or byte[videoflags], 1<<2
				jmp .end
			.nocase:
			;Desactivar el bit para ignorar las mayusculas en la busqueda
				mov byte[ignoreCase], 0
				jmp .end
			.noruler:
			;Desactivar el muestreo de las posiciones del cursor
				mov byte[showpos], 0
				jmp .end
		.end:
	endSubR 0

%macro power 2
	push ecx
	push edx  

	mov ecx,%2
	mov eax,%1
	
	mov edx,%1
	cmp ecx,0
	jne %%.cal
	mov eax,1
	jmp %%.end
	%%.cal:  
	cmp ecx,1
	je %%.end
	mul dl
	loop %%.cal

	%%.end:
	pop edx 
	pop ecx 
%endmacro


;push dword adress: ebp + 8
;push dword size: ebp + 4
global getNumberFromASCII
getNumberFromASCII:
	startSubR
		mov esi,[ebp+8]
		mov ecx,[ebp+4]
		.lp:
		lodsb

		mov dl,al
		sub dl,'0'
		dec ecx 
		power 10,ecx 

		inc ecx 
		mul dl

		add ebx,eax
		loop .lp
		mov eax,ebx
endSubR 8

