%include "video.mac"
%include "keyboard.mac"
section .data
current dw 0
section .text

extern clear
extern getChar
extern calibrate
extern UpdateKeyboard
; Bind a key to a procedure
%macro bind 2
  cmp byte [esp], %1
  jne %%next
  call %2
  %%next:
%endmacro

; Fill the screen with the given background color
%macro FILL_SCREEN 1
  push word %1
  call clear
  add esp, 2
%endmacro

global game
game:
  ; Initialize game

  FILL_SCREEN BG.BLACK

  ; Calibrate the timing
  call calibrate

  ; Snakasm main loop
  game.loop:
    .input:
      call UpdateKeyboard
      call get_input

    ; Main loop.

    ; Here is where you will place your game logic.
    ; Develop procedures like paint_map and update_content,
    ; declare it extern and use here.

    jmp game.loop


get_input:
call getChar
mov ah,0x03
FILL_SCREEN ax 
ret
