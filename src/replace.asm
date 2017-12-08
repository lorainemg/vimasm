%include "keys.mac"
%include "tools.mac"

;keyboard externs
	extern isKey1,isKey2,isKey3, getChar 

;text externs
	extern cursor.moveH, cursor.moveV, cursor
	extern text.write,text.newline, text.endline, text.move
	extern lastline, lines, currentline
	extern text

;main externs
	extern vim.update,UpdateBuffer

section .text
global mode.replace 
mode.replace:

		call getChar				;obtiene el caracter de la tecla que se presiono
		cmp ax, 0 					;si no se presiona ninguna tecla
		je .commad					;entonces se salta hasta el final

		push eax					;se guarda el caracter en la pila como parametro de text.write
		call text.write				;se procede a escribir el caracter en el texto	call UpdateBuffer
     
        mov edx, [currentline]
        push edx                    ;pongo la linea actual como parametro
        call text.endline           ;llamo para buscar el final de linea de la linea actual
        cmp [cursor], eax           ;si la posicion del cursor es menor que el final
        jb .end                     ;entonces termino
        inc word [lines+4*edx]      ;sino, aumento el valor de cantidad de caracteres de la linea actual
		jmp .end                    

	.commad:

	;Para comprobar las teclas de movimientos
		checkKey1 key.left,  .moveleft			;Comprueba si se presiono la tecla izq 
		checkKey1 key.right, .moveright			;Comprueba si se presiono la tecla der 
		checkKey1 key.up, 	 .moveup			;Comprueba si se presiono la tecla arriba 
		checkKey1 key.down,  .movedown			;Comprueba si se presiono la tecla abajo 
	
	;para comprobar acciones especiales
		checkKey1 key.tab, 		 .tab 			;Comprueba si se presiono tab
		checkKey1 key.backspace, .backspace 	;Comprueba si se presiono backspace
		checkKey1 key.enter, 	 .enter 		;Comprueba si se presiono enter

	;commandos especiales
		checkKey1 key.esc, .exitmode 	        ;Si se presiono escape

	jmp .end2
	;movimientos del cursor

		.moveright:					;mueve el cursor a la derecha
			push dword 1
			call cursor.moveH			
			jmp .end
	
		.moveleft:					;mueve el cursor a la izquierda
			push dword -1
			call cursor.moveH
			jmp .end
	
		.moveup:					;mueve el cursor hacia arriba
			push dword -1
			call cursor.moveV
			jmp .end
	
		.movedown:					;mueve el cursor para abajo
			push dword 1
			call cursor.moveV
			jmp .end
	
	;acciones especiales

		.tab:
		;Logica de tab
			jmp .end
	
		.backspace:
			jmp .end
	
		.enter:
		;Logica del enter
            push dword[cursor]                  ;guardo la posicion actual del cursor
            mov eax, [currentline]              ;eax = linea actual
            inc eax                             ;incremento para empezar a desplazar a partir de la otra linea
			push eax                            ;pongo la linea como parametro
			call text.newline                   ;y creo una nueva linea en esa posicion
            
            xor edx, edx
            xor ebx, ebx
            mov eax, [esp]                      ;eax = posicion del cursor
            mov ebx, 80                         ;ebx = 80
            div ebx                             ;divido la posicion del cursor entre 80, guardo el resto en edx
            sub ebx, edx                        ;termino de calcular el desplazamiento: 80-cursor%80
            
            mov edx, [currentline]         
            dec edx                             ;edx = la linea que esta antes de la linea actual
            push edx                            ;la pongo como parametro   
            call text.endline                   ;y pregunto por su final de linea, guardado en eax
            
            pop ecx                             ;recupero la posicion del cursor
            sub eax, ecx                        ;resto el final de linea menos la posicion del cursor,  
            sub [lines+4*edx], ax               ;actualizo lines restando la cantidad de caracteres q voy a desplazar
        	mov [lines+4*(edx+1)], ax           ;la nueva linea va a tener igual cant de caracteres q los q voy a desplazar
            add eax, ecx                        ;regreso el valor de eax de fin de linea

            push ebx                            ;pongo la cantidad que me tengo que desplazar como parametro
            push ecx                            ;pongo la posicion del cursor como parametro (inicio)
            push eax                            ;pongo el final de linea como parametro (final)
            call text.move                      ;llamo para mover el texto
			jmp .end    
	
		.exitmode:
		;Logica para salir del modo
			jmp .end

	.end:
	;Update
	call UpdateBuffer
	.end2:
	call vim.update

	jmp mode.replace
	ret