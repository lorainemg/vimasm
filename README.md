# Vimasm

## Integrantes:
Loraine Monteagudo García
Tony Raúl Blanco Fernández

## Funcionalidades implementadas:
Además de las funcionalidades básicas que requieren 3ptos se implementaron las siguientes funcionalidades optativas:

(0.75): Operadores+repeticiones+movimiento.

(0.75): Comando punto.

(0.5): Inserción en modo bloque .

(0.5): Selección en bloque.

(0.5): Reemplazar texto.

(0.25): Ir al inicio, final y una línea especifica del fichero.

(0.25): Entrar en modo sobrescribir.

(0.25): Borrar utilizando operadores de movimiento.

(0.25): Mover el rango de selección con operadores de movimiento.

(0.25): Especificar preferencias.

(0.25): Las operaciones: *delete*, *yank*, *join*, *move* de la línea de comando.

(0.25): Buscar texto y moverse con `n` y `N`.

(0.25): Deshacer una acción.

(0.25): Deshacer infinito.

(0.25): *Blinking* cursor.

(0.25): Pegar desde registro.

Estructura del proyecto:

```vimasm/
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
```

## Más información

Más información sobre los detalles del proyecto, se puede encontrar en [ORIENTACIÓN.md](https://github.com/lorainemg/vimasm/blob/main/ORIENTACI%C3%93N.md)