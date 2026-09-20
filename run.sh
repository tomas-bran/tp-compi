## Script para Unix
flex Lexico.l
bison -dyv Sintactico.y
gcc -std=gnu17 -fcommon lex.yy.c y.tab.c tabla_simbolos.c -o compilador
./compilador test.txt
rm lex.yy.c
rm y.tab.c
rm y.output
rm y.tab.h
rm compilador
