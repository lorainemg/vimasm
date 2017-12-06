

extern UpdateKeyboard, UpdateBuffer
extern mode.normal
extern calibrate




section .text


global vim.start
  vim.start: ; Initialize game

  ;Calibrate the timing
    call calibrate
  ;Cofiguro el inicio de los estados de los ensamblados
    call text.startConfig
  ;llamo a la funsion especial que abre el comienzo de la pantalla inicial, y sus respectivas opciones.

  ;  
    call 
ret





global vim.update
vim.update:
      call UpdateKeyboard
      call UpdateBuffer
      endSubR 0

