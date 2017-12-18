%include "tools.mac"

extern UpdateKeyboard, UpdateBuffer
extern text.startConfig
extern mode.normal,mode.insert, mode.replace, mode.visual
extern calibrate
extern video.paintIcon
extern video.invalidate, videoflags,video.presentation

section .text


global vim.start
  vim.start: ; Initialize game
    or byte[videoflags], 1 << 2
    or byte[videoflags], 1 << 1

    call video.paintIcon
    call calibrate
  ;Calibrate the timing
    call video.presentation

  ;Cofiguro el inicio de los estados de los ensamblados
    call text.startConfig
  ;llamo a la funcion especial que abre el comienzo de la pantalla inicial, y sus respectivas opciones.
    call mode.normal
  ;salida a modo normal  
   

ret



global vim.update
vim.update:
      startSubR
      call UpdateKeyboard
      call video.invalidate
      endSubR 0
