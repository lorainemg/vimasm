%include "tools.mac"
%include "keys.mac"

extern getChar, checkKey1, isKey1
extern video.Update, vim.update
extern text.find, text.size, text.substitute, text.findline

section .bss
global ctext
ctext 	resb 80
string 	resb 80
pattern	resb 80

section .data
global ccursor
ccursor 		dd 0
global top
top 		dd 0

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
		jmp %%.return
		%%.false:
		xor eax, eax
		%%.return:
%endmacro

section .text
global start.command
start.command:
    startSubR
		call ctext.erase
        mov dword[top], 0
		mov dword[ccursor], 0
        ; mov byte[text], ':'
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
		jmp .end        
        .enter:
        ;Logica para presionar enter
        call stringCmd
		ret
        ;Busca un comando valido, si lo es, lo ejecuta, si no emite un mensaje de comando no valido
        ;Despues sale al modo normal
        .exitmode:
        call ctext.erase
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
<<<<<<< HEAD
	    inc dword [cursor]				;incremento la posicion del cursor
=======
	
	    inc dword [ccursor]				;incremento la posicion del ccursor
>>>>>>> 309ef9730b892c0b68b6e97b814212318967b793
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
        inc dword[top]
	endSubR 4


;call:
	;push dword start: ebp + 4
	;call text.move
ctext.movebackward:
	startSubR
	mov eax, [ebp+4]						;eax = pos a partir de la cual voy a copiar
	dec eax	

	cmp eax, 0								;si estoy en el primer caracter
	jl .end									;entonces no borro

	;mov dl, [ctext+eax]
	;push edx								;guardo el caracter que voy a borrar para analizarlo luego
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
    .end:
	endSubR 4

;Mueve el ccursor horizontalmente
;call:
;push dword dir (1 derecha, -1 izquierda): ebp + 4
global ccursor.move
ccursor.move:
	startSubR
		mov eax, [ccursor]
		add eax, [ebp+4]

		cmp eax, 0
		jl .end
		cmp eax, [top]
		jg .end
		mov [ccursor], eax
	.end:
	endSubR 4

;Para buscar si lo escrito en el text es un comando valido
;call:
;call stringCmd
stringCmd:
    startSubR		
        cmp byte[ctext+1], '/'				;si empieza por /, entonces se esta buscando texto
        jne .n1
        call find
		.n1:
		cmp byte[ctext+1], 's'				;si comienza por 's', entonces se intentara reemplazar
		jne .n2
		call replace
		.n2:
		cmp byte[ctext+1], '%'
		call replaceAll
        .end:
    endSubR 0

;Comando para buscar un patron en el texto
;call find
find:
    startSubR
        lea esi, [ctext+2]				;comienzo desde la pos 2, para saltar ':/'
        mov edi, pattern				;lo copio en la variable busqueda
        mov ecx, [top]					;cuento cuanto tengo que copiar:
        sub ecx, 2						;todo los caracteres del texto - 2, para saltar ':/'
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
		
		substitute 0
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
		
		substitute 1
		.false:
		xor eax, eax
		jmp .end
		.end:
	endSubR 0