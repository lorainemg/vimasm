%include "tools.mac"
%include "keys.mac"


;HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
;HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH			          MACROS				   HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH
;HHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH

	; SetFlags: Actualiza el valor de Keyflag segun alguna tecla de control
	; %1 =current scan code ,%2 = scan code ,%3 = bit flag 
	%macro SetFlags 3 
			mov dl,[keyflags]  	;copio la direccion de keyflag a dl para realizar operaciones logicas sobre el
		%%tryDown:
			mov	bx,%2         	;muevo el scan code down a ebx para operaciones
			cmp	%1,bl  		;comparo si el actual scan code es igual al scan code de la tecla
			jne	%%tryUp
			or 	dl,%3         	;activo flags 
			jmp %%end 		
		%%tryUp:
			cmp %1,bh		;comparo si el actual scan code es igual al scan code de la tecla
			jne %%end
			and dl,~%3   		;desactivo flag
		%%end:
			mov [keyflags],dl	;recupero flags
	%endmacro







section .edata 
 ;          	|SCAN CODE|   	|  ASCII   |  
 ;    			down   	up 		char	shift 
 keymatriz 	db  0x00,	0x00,	0x00,	0x00,		;empty
			db 	0x01,	0x81,	0x00,	0x00, 		;escape
			db 	0x02,	0x82,	0x31,	0x21,		;1
			db 	0x03,	0x83,	0x32,	0x40,		;2
			db 	0x04,	0x84,	0x33,	0x23,		;3
			db 	0x05,	0x85,	0x34,	0x24,		;4
			db 	0x06,	0x86,	0x35,	0x25,		;5
			db 	0x07,	0x87,	0x36,   0x5e,		;6
			db 	0x08,	0x88,	0x37,	0x26,		;7
			db 	0x09,	0x89,	0x38,	0x2a,		;8
			db 	0x0a,	0x8a,	0x39,	0x28,		;9
			db 	0x0b,	0x8b,	0x30,	0x29,		;0
			db 	0x0c,	0x8c,	0x2d,	0x5f,		;-_
			db 	0x0d,	0x8d,	0x3d,	0x2b,		;=+
			db 	0x0e,	0x8e,	0x00,	0x00,		;backspace
			db 	0x0f,	0x8f,	0x00,	0x00,		;tab
			db 	0x10,	0x90,	0x71,	0x51,		;q
			db 	0x11,	0x91,	0x77,	0x57,		;w
			db 	0x12,	0x92,	0x65,	0x45,		;e
			db 	0x13,	0x93,	0x72,	0x52,		;r
			db 	0x14,	0x94,	0x74,	0x54,		;t
			db 	0x15,	0x95,	0x79,	0x59,		;y
			db 	0x16,	0x96,	0x75,	0x55,		;u
			db 	0x17,	0x97,	0x69,	0x49,		;i
			db 	0x18,	0x98,	0x6f,	0x4f,		;o
			db 	0x19,	0x99,	0x70,	0x50,		;p
			db 	0x1a,	0x9a,	0x5b,	0x7b,		;[{
			db 	0x1b,	0x9b,	0x5d,	0x7d,		;]}
			db 	0x1c,	0x9c,	0x00,	0x00,		;enter
			db 	0x1d,	0x9d,	0x00,	0x00,		;ctrl
			db 	0x1e,	0x9e,	0x61,	0x41,		;a
			db 	0x1f,	0x9f,	0x73,	0x53,		;s
			db 	0x20,	0xa0,	0x64,	0x44,		;d
			db 	0x21,	0xa1,	0x66,	0x46,		;f
			db 	0x22,	0xa2,	0x67,	0x47,		;g
			db 	0x23,	0xa3,	0x68,	0x48,		;h
			db 	0x24,	0xa4,	0x6a,	0x4a,		;j
			db 	0x25,	0xa5,	0x6b,	0x4b,		;k
			db 	0x26,	0xa6,	0x6c,	0x4c,		;l
			db 	0x27,	0xa7,	0x3b,	0x3a,		;;
			db 	0x28,	0xa8,	0x27,	0x22,		;'"
			db 	0x29,	0xa9,	0x60,	0x7e,		;`~
			db 	0x2a,	0xaa,	0x00,	0x00,		;left shift
			db 	0x2b,	0xab,	0x5c,	0x7c,		;\|
			db 	0x2c,	0xac,	0x7a,	0x5a,		;z
			db 	0x2d,	0xad,	0x78,	0x58,		;x
			db 	0x2e,	0xae,	0x63,	0x43,		;c
			db 	0x2f,	0xaf,	0x76,	0x56,		;v
			db 	0x30,	0xb0,	0x62,	0x42,		;b
			db 	0x31,	0xb1,	0x6e,	0x4e,		;n
			db 	0x32,	0xb2,	0x6d,	0x4d,		;m
			db 	0x33,	0xb3,	0x2c,	0x3c,		;,<
			db 	0x34,	0xb4,	0x2e,	0x3e,		;.>
			db 	0x35,	0xb5,	0x2f,	0x3f,		;/?
			db 	0x36,	0xb6,	0x00,	0x00,		;right shift
			db 	0x37,	0xb7,	0x00,	0x00,		;print screen
			db 	0x38,	0xb8,	0x00,	0x00,		;alt
			db 	0x39,	0xb9,	0x20,	0x20,		;space
			db 	0x3a,	0xba,	0x00,	0x00,		;caps lock
			db 	0x3b,	0xbb,	0x00,	0x00,		;f1
			db 	0x3c,	0xbc,	0x00,	0x00,		;f2
			db 	0x3d,	0xbd,	0x00,	0x00,		;f3
			db 	0x3e,	0xbe,	0x00,	0x00,		;f4
			db 	0x3f,	0xbf,	0x00,	0x00,		;f5
			db 	0x40,	0xc0,	0x00,	0x00,		;f6
			db 	0x41,	0xc1,	0x00,	0x00,		;f7
			db 	0x42,	0xc2,	0x00,	0x00,		;f8
			db 	0x43,	0xc3,	0x00,	0x00,		;f9
			db 	0x44,	0xc4,	0x00,	0x00,		;f10
			db 	0x45,	0xc5,	0x00,	0x00,		;num lock
			db 	0x46,	0xc6,	0x00,	0x00,		;scrl lk
			db 	0x47,	0xc7,	0x00,	0x00,		;home
			db 	0x48,	0xc8,	0x00,	0x00,		;up arrow
			db 	0x49,	0xc9,	0x00,	0x00,		;pg up
			db 	0x4a,	0xca,	0x00,	0x00,		;-(num)
			db 	0x4b,	0xcb,	0x00,	0x00,		;4 left arrow
			db 	0x4c,	0xcc,	0x00,	0x00,		;5 (num)
			db 	0x4d,	0xcd,	0x00,	0x00,		;6 right arrow
			db 	0x4e,	0xce,	0x00,	0x00,		;+ (num)
			db 	0x4f,	0xcf,	0x00,	0x00,		;1 end
			db 	0x50,	0xd0,	0x00,	0x00,		;2 down arrow
			db 	0x51,	0xd1,	0x00,	0x00,		;3 pg down
			db 	0x52,	0xd2,	0x00,	0x00,		;0 ins
			db 	0x53,	0xd3,	0x00,	0x00		;del .
	
 ;control bits 
	%define _shiftBit 	0001b
	%define _ctrlBit  	0010b
	%define _altBit		0100b
	%define _capsBit 	1000b
	%define _capsBit2	0x10

section .data
	keyflags 	db 0 ;control flag var 
   	lastScan 	db 0

section .text


;call:
;call cashcaps
SetCapsFlag:
	startSubR
		mov al,[lastScan]
		mov bx,key.capslock	
		mov dl,[keyflags]
    	cmp al,bl			;down?
    	jne .tryUp				;else
    	or dl,_capsBit			;active flag
    	jmp .end
	.tryUp:
    	cmp al,bh 			;up?
    	jne .end 				;else
    	xor dl,_capsBit2
    	test dl,_capsBit2		;estaba apagado?
    	jnz .end
 		and dl,~_capsBit
	.end:
		mov [keyflags],dl
endSubR 0



;Esta sub-rutina actualiza el valor del teclado, activado y desactivando flags de control y la ultima tecla  
;call:
;call UpdateKeyboard
;no return
GLOBAL UpdateKeyboard
UpdateKeyboard:
	startSubR
		in al,0x64								;al= buffer status
		test al,0x2								;ver bit 1 del status para garantizar un in
		jnz .end
		in al,0x60								;al= scan
		mov [lastScan],al						;actualizamos lastScan
	;<<	control 
		SetFlags al, key.ctrl,_ctrlBit
		SetFlags al, key.alt,_altBit
		SetFlags al, key.shiftL,_shiftBit
		SetFlags al, key.shiftR,_shiftBit
    	call SetCapsFlag 						;subrutina especial para la tecla caps
    	mov al,[lastScan]
    	in al,0x64								;al= buffer status
    	test al,0x01							;ver bit 0 del status para garantizar un out
    	jnz .end
    	xor al,al
    	out 0x60,al								;limpiamos 0x60
    	.end:
endSubR 0 



;call:
;call getChar
;return: valor ASCII de la tecla presionada
GLOBAL getChar
getChar:
	startSubR
    	mov al,[lastScan] 	;recupero el valor del scan
	;rectificacion de rango de scan down
    	cmp al,0x53			
    	ja .exit 			;exit
    	cmp al,0
    	je .exit
	;		down correcto
		mov ebx,keymatriz 	;guardo en bx la direccion de keys
    	add ebx,2   		;scan => ASCII
    	mov dl,4			;el factor de la matriz
		mul dl		 		;guardo en eax el index = lastScan * 4 
		add ebx,eax			;indexo en bx[ax]
	; 	<<  logic to Upper: (shift && !(letter && caps) || (!shift && (letter && caps)) then ah=1 else ah=0  (ah is Upper factor) 
		xor edx,edx 
		mov dl,[ebx]		;recupero en valor ASCII en ax
		cmp dl,0
		je .exit
   		push edx			;Guarddo el ASCII en la pila			
    	call isLetterChar  	;al = letter
    	mov dl,[keyflags]  	;retomo valor de flags
    	shr dl,3  			;pongo en el bit 1 el estado de caps
    	and al,dl 			;al = (letter && caps) 
    	mov dl,[keyflags]   ;retomo valor de flags
   		test dl,_shiftBit   ;is shift down?  
		clean edx			;limpia edx sin alterar flags
		jnz .shift      	;if shift try 
	; 		!(letter && caps)
		test al,1			;if al==1
		jz .end 			;else
 		mov edx,1			;edx=1
 		jmp .end			;salto al final
	.shift:
	;		letter && caps
		test al,1			;si al=0 entonces upper
		jnz .end			;else
		mov edx,1			;edx=1
	.end:
		xor eax,eax
    	add ebx,edx			; el valor ebx =keys + index +2  ... ahora sumado con 0 o 1 si es Upper
		mov eax,[ebx]		;return
	endSubR 0
	.exit:
		xor eax,eax
endSubR 0



;call:
;push dword ASCII 
;call isLetterChar
;return in eax
GLOBAL isLetterChar
isLetterChar:
	startSubR
  		mov edx,[ebp + 4]
		inRange 0x61,0x7a,edx
endSubR 4 



;call
;push dword control scan
;call isControl
GLOBAL isControl
isControl: 
	startSubR
	mov eax,[ebp+4]
	cmp eax, key.shiftR
	je .isShift
	cmp eax, key.shiftL
	je .isShift
	cmp eax, key.ctrl
	je .isCtrl
	cmp eax, key.alt
	je .isAlt

	jmp .any

	.isShift:
 	mov eax,_shiftBit
 	and eax,[keyflags]
	jmp .end
	
	.isCtrl:
	mov eax,_ctrlBit
 	and eax,[keyflags]
 	shr eax,1
	jmp .end
	
	.isAlt:
	mov eax,_altBit
 	and eax,[keyflags]
 	shr eax,3
	jmp .end

	.any:
	xor eax,eax
	.end:
endSubR 4



;Determina si una non-control tecla esta presionada o no
;call:
;push dword non-control-scan
;call isKey1
;return in eax
GLOBAL isKey1
isKey1:
startSubR
	mov ax,[ebp+4]				;se accede a la tecla que se quiere comprobar
	mov ebx,lastScan 			
	cmp ax,[ebx]				;es la ultima que se presiono?
	jne .ne						;si no lo es, entonces salta
	mov eax, 1					;si lo es, guarda en ax que se presiono una tecla
	jmp .end  					;y termina
	.ne:						;si no lo es
	xor eax, eax				;pone en ax 0
	.end:
endSubR 4



;Determina si dos tecla [ control + non-control ] estan presionadas
;call:
;push dword control-scan: ebp+8
;push dword non-contrl-scan: ebp +4
;call isKey2
;return in eax
GLOBAL isKey2
isKey2:
	startSubR
	push dword [ebp+8]
	call isControl
	mov edx,eax
	push dword [ebp+4]
	call isKey1 
	and eax,edx
endSubR 8



;Determina si las teclas : [ control + control +  non-control ] estan presionadas
;call:
;push dword control-scan: ebp+12
;push dword control-scan: ebp+8
;push dword non-contrl-scan: ebp +4
;call isKey2
;return in eax
GLOBAL isKey3
isKey3:
	startSubR
	push dword [ebp+12]
	call isControl 
	mov edx,eax
	push dword [ebp+8]
	push dword [ebp+4]
	call isKey2
	and eax,edx
endSubR 12