:: Script para windows
flex Lexico.l
bison -dyv Sintactico.y

gcc.exe -std=gnu11 -fcommon lex.yy.c y.tab.c tabla_simbolos.c polaca.c -o compilador.exe

compilador.exe test.txt

@echo off
del compilador.exe
del lex.yy.c
del y.tab.c
del y.tab.h
del y.output

pause
