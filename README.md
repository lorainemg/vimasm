# Vimasm

Integrantes:
Loraine Monteagudo Garcia C211
Tony Raul Blanco Fernandez C211

Funcionalidades implementadas:
Ademas de las funcionalidades basicas que requieren 3ptos se implementaron las siguientes funcionalidades optativas:

(0.75):Operadores+repeticiones+movimiento
(0.75):comando punto
(0.5):insercion en modo bloque  
(0.5):seleccion en bloque
(0.5):reemplazar texto
(0.25):ir al inicio, final y una linea especifica del fichero
(0.25):entrar en modo sobreescribir
(0.25):borrar utilizando operadores de movimiento
(0.25):mover el rango de seleccion con operadores de movimiento
(0.25):especificar preferencias
(0.25):las operaciones: delete, yank, join, move de la linea de comando
(0.25):buscar texto y moverse con n y N
(0.25):deshacer una accion
(0.25):deshacer infinito
(0.25):blinking cursor
(0.25):pegar desde registro

Estructura del proyecto:
vimasm/
    ├──	src/
    │	├──	multiboot.asm
    │	├──	boot.asm
    │	├──	main.asm
    │	├──	startConfig.asm
    │	├──	keyboard.asm
    │	├──	keys.mac
    │	├──	video.asm
    │	├──	video.mac
    │	├──	command.asm
    │	├──	normal.asm
    │	├──	replace.asm
    │	├──	text.asm
    │	├──	tools.mac
    │	├──	visual.asm
    │	└──	timing.asm
    ├──	Makefile
    ├──	README.md
    ├──	ORIENTACIÓN.md
    ├──	linker.ld
    ├──	menu.lst
    └──	stage2_eltorito