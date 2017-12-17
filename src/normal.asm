%include "keys.mac"
%include "tools.mac"

;keyboad externs
extern isKey1,isKey2, isNum, getChar
;text externs
extern cursor.moveH, cursor.moveV, cursor.moveline, cursor, cursor.search, matchLen,  text, text.deletelines
extern lines.last, lines.endword, lines.current, lines.starts, lines.endline, erasetimes, eraseline
extern select.copy.normal, copy.line, text.size
;modes externs
extern mode.insert, mode.replace, mode.visual, start.visual, select.paste, mode.command, start.command, getNumberFromASCII
;main externs
extern vim.update, video.Update, videoflags
extern undopivot,text.load ,text.save 

section .bss
repit	resb 8					;se ponen los digitos que se escriben

section .data
lastkey 	db 0, 0					;para llevar el control de la secuencia de teclas que se han presionado
count 		dd 0					;cuenta cuantos digitos se han escrito

global mode.current 
mode.current dd 0 

;Para realizar las repeticiones de los operadores:
;Tine como parametros una funcion que recibe 2 parametros:primero las veces
;que se repite una operacion y luego el modo en que se realiza la operacion
;call: operator parameter, function
%macro repetition 2
	cmp dword[count], 0
	jne %%.findnum
	xor eax, eax
	jmp %%.start
	%%.findnum:
	push repit
	push dword[count]
	call getNumberFromASCII			;convierto el numero a entero
	dec eax
	%%.start:
		push eax					;1er parametro: cantidad de repeticiones
		push dword %1				;2do parametro: modo de la funcion
		call %2						;luego llamo a la funcion
%endmacro

;Macro para limpiar los valores de lastKey
%macro clean 0
	mov byte [lastkey], 0
	mov byte [lastkey+1], 0
	mov dword[count], 0
%endmacro

;Para simplificar los operadores de copiar y borrar
;call: letra del operador (identifica el operador), funcion (relacionado con el operador)
%macro operator 2
	cmp byte[lastkey], %1			;si la tecla del operador fue la ultima que se presiono
	je %%.line						;entonces realizo la operacion en modo linea
	mov byte[lastkey], %1			;si no, entonces guardo en lastKey el caracter de la tecla que se presiono
	jmp %%.end						;y termino
	%%.line:
		repetition 1, %2			;busco las repeticiones que pudiera tener el operador, y llamo a la funcion en modo linea
	%%.end:
%endmacro

;Para simplificar los movimientos de mover al final de palabra y mover al final de linea
;call: moveEnd mode (modo que se realiza)
%macro moveEnd 1
	cmp byte[lastkey], 'y'			;si la tecla que se presiono fue y, entonces copio
	je %%.yank
	cmp byte[lastkey], 'd'			;si fue d borro
	je %%.delete
	cmp byte[lastkey], 'c'			;y de ser c borro tambien, pero luego entro en modo insercion
	je %%.delete
	jmp %%.end
	%%.yank:						;Para copiar:
		repetition %1, copyOperator	;busco las repeticiones que pudieran haber y entro en el modo correspondiente a copiar
		jmp %%.end
	%%.delete:						;Para eliminar:
		call text.save
		repetition %1, eraseOperator ;busco las repeticiones que pudieran haber y entro en el modo correspondient a borrar
		cmp byte[lastkey], 'c'		;se entro en modo reemplazar?
		jne %%.end					;si no se hizo, entonces termino
		clean						;sino, limpio lastkey
		call mode.insert			;y entro en modo insetar
	%%.end:
	clean							;limpio lastkey
%endmacro


section .text

global mode.normal
mode.normal:
	mov dword[mode.current],mode.fnormal				;modo normal
	;Controles de movimiento:
		checkKey1 key.left,  .moveleft			;si se presiono la tecla izq 
		checkKey1 key.right, .moveright			;si se presiono la tecla der 
		checkKey1 key.up, 	 .moveup			;si se presiono la tecla arriba 
		checkKey1 key.down,  .movedown			;si se presiono la tecla abajo 

	;Controles basicos
		checkKey1 key.p, .paste					;si se presiono p
		
	;Cambiar de modo:
		checkKey1 key.i, .insertmode			;si se presiono i
		checkKey2 key.shiftL, key.v, .visualLinemode	;si se presiono shift+v
		checkKey2 key.ctrl, key.v, .visualBlockmode	;si se presiono ctrl+v
		checkKey1 key.v, .visualmode 			;si se presiono v
		checkKey1 key.r, .replacemode			;si se presiono r
		checkKey2 key.shiftL, key.ptCom, .commadmode	;si se presiono shift+;

	;Controles optativos:
		checkKey1 key.u, .undo					;si se presiono u
		checkKey1 key.s, .save 					;si se presiono u
		checkKey1 key.point, .point				;si se presiono .

	;Moverse por el fichero:
		checkKey2 key.shiftL, key.g, .goLine	;si se presiono shift+g
		checkKey1 key.g, .goStart				;si se presiono 2 vecer g

	;Operadores:
		checkKey1 key.y, .copy
		checkKey1 key.d, .erase
		checkKey1 key.c, .replace
	;Operadores de movimiento
    	checkKey2 key.shiftL, key.4, .endline    
    	checkKey2 key.shiftL, key.6, .startline
    	checkKey1 key.w, .endword

	;Controles relacionados con el modo comando
		checkKey2 key.shiftL, key.n, .prevsearch
		checkKey1 key.n, .nextsearch

		checknum .num

			jmp .end
	;##########################################################################################################################################################
	;##########################################################################################################################################################


	;Comandos de movimientos:
		.moveright:					;mueve el cursor a la derecha
			clean
			push dword 1
			call cursor.moveH			
			jmp .end
		.moveleft:					;mueve el cursor a la izquierda
			clean
			push dword -1
			call cursor.moveH
			jmp .end
		.moveup:					;mueve el cursor hacia arriba
			clean
			push dword -1
			call cursor.moveV
			jmp .end
		.movedown:					;mueve el cursor para abajo
			clean
			push dword 1
			call cursor.moveV
			jmp .end

	;Cambiar de modo:
		.insertmode:
		;Logica para cambiar al modo insertar
			mov dword[mode.current],mode.finsert
			clean
			call mode.insert
			jmp .end
		.visualmode:
		;Logica para cambiar al modo visual con seleccion estandar
			clean
			mov dword[mode.current],mode.fvisual
			push dword 0
			call start.visual
			call mode.visual
			jmp .end
		.visualLinemode:
		;Logica para cambiar al modo visual con seleccion en modo linea
			clean
			mov dword[mode.current],mode.fvisual
			push dword 1
			call start.visual
			call mode.visual
			jmp .end
		.visualBlockmode:
		;Logica para cambiar al modo visual con seleccion en modo bloque
			clean
			mov dword[mode.current],mode.fvisual
			push dword 2
			call start.visual
			call mode.visual
			jmp .end
		.replacemode:
		;Logica para cambiar al modo reemplazar
			mov dword [mode.current],mode.freplace
			clean
			call mode.replace
			jmp .end
		.commadmode:
		;Logica para cambiar al modo de comando
			clean
			mov dword[mode.current],mode.fcommand
			call start.command
			call mode.command
			jmp .end

	;Comandos especiales:
		.paste:						
		;Logica para pegar
			clean
			call select.paste
			call text.save
			jmp .end
		.undo:						
		;Logica para deshacer una accion
			cmp dword [undopivot],0
			je .end 
			call text.load  
			clean
			jmp .end
		.save:
			call text.save   
			clean
			jmp .end
		.goStart:
		;Logica para ir al pricipio del text
			cmp byte[lastkey], 'g'			;el ultimo caracter presionado fue 'g'?
			jne .no							;si no lo fue, entonces no realizo ninguna accion
			push dword 0					;si lo fue:
			call cursor.moveline			;muevo el cursor hacia el inicio de la preimera linea
			clean							;reestablezco el valor de la ultima tecla
			.no:
			mov byte[lastkey], 'g'			;si no hice ninguna accion, entonces pongo como caracter de mi ultima tecla g
			jmp	.end
		.goLine:
		;Logica para ir hacia una linea del text del text
			call goNumLine
			jmp .end
		.point:
		;Logica para el comando punto
			jmp .end

		.copy:
		;Logica para copiar con repeticion + operadores de movimiento
			operator 'y', copyOperator
			jmp .end
		.erase:
		;Logica para borrar con repeticion + operadores de movimiento
			operator 'd', eraseOperator
			jmp .end			
		.replace:
		;Logica para reemplazar con repeticion + operadores de movimiento
			cmp byte[lastkey], 'c'			;si el ultimo caracter analizado fue c
			je .line						;entonces, realizo la operacion
			mov byte[lastkey], 'c'			;si no, cambio el valor de la ultima tecla
			jmp .end						;y voy al final
			call text.save
			.line:							;Para realizar la operacion:
				repetition 1, eraseOperator	;busco las repeticiones y entro en modo linea a eraseOperator
				clean						;limpio los valores de lastKey
				call mode.insert			;y llamo al modo insertar
			jmp .end			

		.endline:
		;Logica para realizar la operacion hasta el final de una linea
			moveEnd 3						
			jmp .end  
		.startline:
		;Logica para realizar la operacion hacia el inicio de una linea
			call moveStartLine
			jmp .end
		.endword:
		;Logica para realizar la operacion hacia el final de una palabra
			moveEnd 0
			jmp .end

		.nextsearch:
		;Logica para mostrar la siguiente busqueda
			push dword 1					;le digo al cursor que se mueva a la siguiente busqueda
			call cursor.search				;y lo llamo
			jmp .end		
		.prevsearch:
		;Logica para mostrar la busqueda anterior
			push dword -1					;para que el cursor se mueva a la busqueda anterior
			call cursor.search
			jmp .end

		.num:
		;Control intermedio para decidir que se hace cuando se presiona un numero
			cmp byte[lastkey], 'y'			;si se presiono y para pegar
			je .tryop						;intento realizar una operacion
			cmp byte[lastkey], 'c'			;si se presiono c para reemplazar
			je .tryop						;intento realizar una operacion
			cmp byte[lastkey], 'd'			;si se presiono d para borrar
			je .tryop						;intento realizar una operacion
			mov ebx, [count]
			mov [repit+ebx], al
			inc dword[count]			
			jmp .end
			.tryop:							;si no, es una operacion lo que esta en lastkey
				mov ebx, [count]
				mov [repit+ebx], al
				inc dword[count]
			jmp .end

	.end:
	call video.Update						;y se actualiza el video
	.end2:
	call vim.update
	jmp mode.normal
ret

;Movimiento para realizar operaciones en el principio de una linea
moveStartLine:
	startSubR
		cmp byte[lastkey], 'y'				
		je .yank
		cmp byte[lastkey], 'd'
		je .delete
		cmp byte[lastkey], 'c'
		je .delete
		jmp .end
		.yank:							;Copiar:
			push dword 0				;ninguna repeticion
			push dword 2				;copio en modo principio de linea
			call copyOperator			;llamo para copiar
			jmp .end
		.delete:						;Eliminar:
			push dword 0				;ninguna repeticion
			push dword 2				;copio en modo principio de linea
			call eraseOperator			;llamo para borrar
			cmp byte[lastkey], 'c'		;se esta en modo reemplazar?
			jne .end					;si no se esta, entonces termino
			clean						;si se esta en modo reemplazar limpio lastkey
			call mode.insert			;y llamo a modo insertar
		.end:
		clean
	endSubR 0

;Va a un numero de linea especifico
;call:
;call goNumLine
goNumLine:	
	startSubR
		cmp dword[count], 0					;para moverme en una linea en especifica:
		je .goEnd						;si no se ha presionado un num entonces voy al final del texto
		push repit
		push dword[count]
		call getNumberFromASCII
		dec eax
		push eax
		call cursor.moveline			;y muevo el cursor en el principio de esa linea
		jmp .end
		.goEnd:
		push dword[lines.last]			;para ir al final del texto:
		call cursor.moveline			;pongo el cursor en el primer caracter de la primera linea
		.end:
		clean							;desactualizo el valor de la ultima tecla	
	endSubR 0

;Copia 
;call:
;push dword times: ebp + 8
;push dword mode: ebp + 4	(0 palabra, 1 linea, 2 principio de linea, 3 final de linea)
copyOperator:
	startSubR
		mov eax, [ebp+4]				;accedo al modo en que voy a copiar
		cmp eax, 1						;si es modo linea
		je .modeline					;voy a copiar en modo linea
		cmp eax, 2						;si es modo principio de linea
		je .modestart				
		cmp eax, 3						;si es modo final de linea
		je .modeend
	.modeword:							;Para copiar hasta el final de una palabra:
		push dword[ebp+8]				;pongo la cantidad de veces que voy a copiar como parametro
		call copyOperator.word			;y copio las veces contadas
		jmp .end
	.modeline:							;Para copiar en modo linea:
		push dword[ebp+8]				;guardo las veces que tengo que copiar
		call copyOperator.line			;y llamo para copiar lineas
		jmp .end
	.modestart:							;Para copiar en modo principio de linea:
		call copyOperator.start			;llamo para copiar
		jmp .end
	.modeend:							;Para copiar en modo final de linea
		push dword[ebp+8]				;guardo las veces que quiero copiar
		call copyOperator.endline		;y llamo para copiar
	.end:
	endSubR 8

;El operador de copiar en modo final de palabra
;call:
;push dword times: ebp + 4
copyOperator.word:
	startSubR
		mov edx, [ebp+4]				;edx + 1 = catidad de palabras que voy a copiar
		inc edx					
		push edx					
		call posWords					;busco la hasta donde esta el final de las palabrass
		dec eax
		push eax						;pongo la pos final de la palabra como parametro
		push dword[cursor]				;pongo la pos inicial como parametro
		call select.copy.normal			;copio desde mi posicion hasta el final de la palabra
	endSubR 4

;El operador de copiar en modo linea
;call:
;push dword time: ebp + 4
copyOperator.line:
	startSubR
		mov eax, [lines.current]		;eax = linea actual
		mov edx, eax				
		add edx, [ebp+4]				;edx = linea actual + cantidad de veces que se repite la accion
		push edx						;el final de la copia sera edx
		push eax						;el inicio eax
		call copy.line			
	endSubR 4

;El operador de copiar en modo principio de linea
;call:
copyOperator.start:
	startSubR
		mov eax, [lines.current]		;eax = linea actual
		mov edx, [lines.starts+4*eax]	;edx = principio de la linea actual
		push dword[cursor]				;el final de la copia es la posicion del cursor			
		push edx						;el principio es el inicio de linea
		call select.copy.normal			;copio en el rango especificado
	endSubR 0

;El operadore de copiar en modo final de linea
;call:
;push dword times: ebp + 4
copyOperator.endline:
	startSubR		
		mov edx, [lines.current]		
		add edx, [ebp+4]				;edx = linea actual + cantidad de lineas que se quieren copiar
		push edx						;es decir, edx es la ultima linea a copiar
		call lines.endline				;pregunto por el final de esa linea
		dec eax							;eax = final
		push eax						;pongo el final de mi copia
		push dword[cursor]				;la posicion del cursor es el principio de la copia
		call select.copy.normal			;llamo a copiar normal
	endSubR 4

;Busca la posicion final de un conjunto de palabras a partir de la posicion del cursor
;call:
;push dword times: ebp + 4
;return: eax -> pos del fin de palabra
posWords:
	startSubR
		mov ecx, [ebp+4]
		mov eax, [cursor]
	.lp1:							;para copiar varias palabras calculo el total de cuanto me voy a mover:
		cmp eax, [text.size]
		jae .end
		push eax					;pongo la posicion en la que estoy ahora como parametro
		call lines.endword			;y pregunto por la posicion final de esa palabra, eax se va incrementando
		inc eax
		loop .lp1					;repito el ciclo las veces contadas
	.end:
	endSubR 4

;Operador para borrar
;call:
;push dword times: ebp + 8
;push dword mode: ebp + 4 (0 palabra, 1 linea, 2 principio de linea, 3 final de linea)
eraseOperator:
	startSubR
		mov eax, [cursor]
		cmp byte[text+eax], ASCII.enter
		je .end
		mov eax, [ebp + 4]			;eax = modo
		cmp eax, 1					;si el modo es linea
		je .modeline
		cmp eax, 2					;si el modo es principio de linea
		je .modestart
		cmp eax, 3					;si el modo es final de linea
		je .modeend
	.modeword:						;Para modo palabra:
		push dword[ebp + 8]			;pongo las veces que se tienen que borrar las palabras
		call eraseOperator.word		;y llamo para borrar palabras
		jmp .end
	.modeline:						;Para modo linea:
		mov edx, [lines.current]	
		mov eax, [lines.starts+4*edx]	;eax = principio de la linea actual
		push eax					;el principio de la linea es donde se va a empezar a borrar
		push dword[ebp+8]			;la cantidad de veces es el parametro dado
		call text.deletelines		;llamo para borrar las veces calcualdas
		jmp .end
	.modestart:						;Para modo principio de linea:
		push dword[cursor]			;se empieza desde el principio del cursor
		call eraseline				;y se elimina desde alli hasta el principio de linea
		jmp .end
	.modeend:						;Para borrar hasta el final de una linea
		push dword[cursor]			;el principio es la posicion actual del cursor
		push dword[ebp+8]			;la cantidad de veces es el parametro pasado
		call text.deletelines		;y se elimina desde alli hasta la ultima posicion de la ultima linea senalada
		.end:
	endSubR 8

;Operador de borrar en modo palabra
;call:
;push dword times: ebp +4
eraseOperator.word:
	startSubR
		mov ecx, [ebp+4]
		inc ecx
		push ecx					;se saca la cuenta de cuantas palabras se tienen que borrar
		call posWords				;se llama para determinar la posicion de la ultima palabra a borrar
		dec eax						;se decrementa la ultima posicion (para no borrar el espacio)
		
		mov edx, [cursor]			;edx = pos del cursor
		mov [cursor], eax			;el cursor se pone en la ultima posicion que se va a copiar
		sub eax, edx				;cantidad de veces que se borran: ultima pos - pos del cursor anterior
		
		push eax					;pongo la cantidad de caracteres a borrar como parametro
		call erasetimes				;y llamo para borrar las veces contadas
	endSubR 4

;Borra lineas a partir de una posicion especifica
;call:
;push dword start: ebp + 8
;push dword times: ebp + 4
eraseOperator.lines:
	startSubR
		mov edx, [lines.current]
		add edx, [ebp + 4]			;le adiciono a la linea actual la cantidad de lineas que voy a copiar
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