%include "video.mac"
%include "keys.mac"
section .data


extern text.skipline
extern text.move
extern isKey1,isKey2,isKey3
extern text
extern cursor
extern getChar
extern calibrate
extern UpdateKeyboard
extern text.write
extern UpdateBuffer
section .text
global game
game: ; Initialize game

  ; Calibrate the timing
   call calibrate
  
  game.loop:
    .input:
      call UpdateKeyboard
      call get_input
      ;call UpdateBuffer
    ; Main loop.

    ; Here is where you will place your game logic.
    ; Develop procedures like paint_map and update_content,
    ; declare it extern and use here.

    jmp game.loop

;call:
;call input
get_input:
call getChar				;obtiene el caracter de la tecla que se presiono
cmp ax,0 					;si no se presiona ninguna tecla
je .end						;entonces se salta hasta el final
push eax					;se guarda el caracter en la pila como parametro de text.write
call text.write				;se procede a escribir el caracter en el texto
call UpdateBuffer
jmp .end2					;entonces, se salta hasta el final
.end:
;Para probar el backspace:

mov eax, key.backspace
push eax	 				;se comprueba si se presiono backspace

call isKey1
cmp ax,1					;si no se presiono, salta hasta el final
jne .end2
push dword 1
push dword 0
;push dword 79
;mov ebx,cursor				;se pone la posicion del cursor en la pila, como posicion a partir de la cual se va a escribir				
;mov eax,[ebx]
;push eax
;dec eax				 		;se decrementa menos uno, porque es donde se va a terminar de borrar
;push eax					
call text.skipline				;y se llama para mover el texto
;dec word [cursor]  
call UpdateBuffer
.end2:
ret
