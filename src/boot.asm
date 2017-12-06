%define stack.SIZE 0x100

section .bss

stack resb stack.SIZE

section .text
extern vim.start
; Set up stack pointers, initialize the FPU and jump to main.
global boot
boot:
  mov esp, stack + stack.SIZE
  mov ebp, esp
  fninit

 ; Move text mode cursor off screen.
  mov dx, 0x3D4
  mov al, 0x0E
  out dx, al
  inc dx
  mov al, 0xFF
  out dx, al

  jmp vim.start

; Divide by zero to cause a triple fault and reset.
global reset
reset:
  mov ax, 1
  xor dl, dl
  div dl
  jmp reset

; Halt.
global halt
halt:
  hlt
  jmp halt
