%include "video.mac"
%include "keys.mac"
%include "tools.mac"
section .data




extern text.startConfig
extern text,lastline
extern text.write,text.newline,text.skipline
extern cursor

extern isKey1,isKey2,isKey3
extern UpdateKeyboard,getChar

extern calibrate

extern UpdateBuffer


section .text
global game
game: ; Initialize game

  ; Calibrate the timing
   call calibrate
   call text.startConfig
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
xor eax,eax
mov ax,[lastline]
push eax
call text.newline			;y se llama para mover el texto
;push dword 1
;push dword 0
;call text.skipline



call UpdateBuffer
.end2:
ret
