%include "tools.mac"

extern UpdateKeyboard, UpdateBuffer
extern text.startConfig
extern mode.normal,mode.insert, mode.replace
extern calibrate




section .text


global vim.start
  vim.start: ; Initialize game

  ;Calibrate the timing
    call calibrate
  ;Cofiguro el inicio de los estados de los ensamblados
    call text.startConfig
  ;llamo a la funsion especial que abre el comienzo de la pantalla inicial, y sus respectivas opciones.
    
    call mode.replace
  ;salida a modo normal  
    ;call mode.normal

ret



global vim.update
vim.update:
      startSubR
      call UpdateKeyboard
      ;call UpdateBuffer
      endSubR 0

