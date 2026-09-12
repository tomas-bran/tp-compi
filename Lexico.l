%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "y.tab.h"
#include "tabla_simbolos.h"
char *yyltext;

typedef struct {
    char *palabra;
    int   token;
} PalabraReservada;

PalabraReservada tabla_reservadas[] = {
    {"init",   INIT},
    {"Float",  TIPO_FLOAT},
    {"Int",    TIPO_INT},
    {"String", TIPO_STRING},
    {"AND",    AND},
    {"OR",     OR},
    {"NOT",    NOT},
    {"if",     IF},
    {"else",   ELSE},
    {"while",  WHILE},
    {"read",   READ},
    {"write",  WRITE},
    {"when",   WHEN},
    {"is",     IS},
    {"in",     IN},
};

int buscar_reservada(char *lexema) {
    int i;
    int ce = sizeof(tabla_reservadas) / sizeof(tabla_reservadas[0]);
    for (i = 0; i < ce ; i++) {
        if (strcmp(lexema, tabla_reservadas[i].palabra) == 0)
            return tabla_reservadas[i].token;
    }
    return -1; 
}

int yyerror(void);

%}

%option noyywrap  
%option yylineno 

DIGITO			[0-9]
LETRA			[a-zA-Z]
ESPACIO         [ \t\n]+

CTE_INT_POSITIVA	{DIGITO}+
CTE_FLOAT_POSITIVA	{DIGITO}+"."{DIGITO}+
CTE_STRING		\"({LETRA}|{DIGITO}|{ESPACIO})*\"
ID			{LETRA}({LETRA}|{DIGITO})*

OP_SUM			"+"
OP_MUL			"*"
OP_RES			"-"
OP_DIV			"/"
PAR_AP			"("
PAR_CI			")"
DOS_PUNTOS		":"
COMA			","
LLAVE_AP		"{"
LLAVE_CI		"}"
OP_IGUAL		"=="
OP_ASIG			":="
OP_MENOR		"<"
OP_MAYOR		">"
OP_MEN_IG		"<="
OP_MAY_IG		">="
OP_DIF			"!="
OP_POT			"**"
OP_SPACESHIP	"<=>"
OP_RANGO		".."

%%

"#+"([^+]|"+"[^#])*"+#"	{ /* comentario: se descarta, no genera token */ }

{CTE_FLOAT_POSITIVA}	{
                    double valor = atof(yytext);

                    if (valor > 3.4028235e38) {
                        printf("\nError Léxico: Constante Float fuera de cota: %s en la línea %d\n", yytext, yylineno);
                        exit(0);
                    }
                    if (ts_insertar_constante(&tabla_simbolos, TD_FLOAT, yytext, -1, yylineno) == TS_INDICE_INVALIDO) {
                        fprintf(stderr, "\nError: no hay memoria para guardar la constante %s\n", yytext);
                        exit(EXIT_FAILURE);
                    }
                    printf("\nConstante Float: %s en la línea %d\n", yytext, yylineno);
                    return CTE_FLOAT_POSITIVA;
                }
{CTE_INT_POSITIVA}	{
                    long valor = atoi(yytext);

                    if (valor > 32767) {
                        printf("\nError Léxico: Constante Int fuera de cota (min -32768, max 32767): %s en la línea %d\n", yytext, yylineno);
                        exit(0);
                    }
                    if (ts_insertar_constante(&tabla_simbolos, TD_INT, yytext, -1, yylineno) == TS_INDICE_INVALIDO) {
                        fprintf(stderr, "\nError: no hay memoria para guardar la constante %s\n", yytext);
                        exit(EXIT_FAILURE);
                    }
                    printf("\nConstante Int: %s en la línea %d\n", yytext, yylineno);
                    return CTE_INT_POSITIVA;
                }
{CTE_STRING}		{
                    int longitud = strlen(yytext) - 2;
                    char *valor;
                    if (longitud > 50) {
                        printf("\nError Léxico: Constante String excede 50 caracteres: %s en la línea %d\n", yytext, yylineno);
                        exit(0);
                    }
                    valor = malloc((size_t)longitud + 1);
                    if (valor == NULL) {
                        fprintf(stderr, "\nError: no hay memoria para guardar la constante %s\n", yytext);
                        exit(EXIT_FAILURE);
                    }
                    memcpy(valor, yytext + 1, (size_t)longitud);
                    valor[longitud] = '\0';
                    if (ts_insertar_constante(&tabla_simbolos, TD_STRING, valor, longitud, yylineno) == TS_INDICE_INVALIDO) {
                        free(valor);
                        fprintf(stderr, "\nError: no hay memoria para guardar la constante %s\n", yytext);
                        exit(EXIT_FAILURE);
                    }
                    free(valor);
                    printf("\nConstante String: %s en la línea %d\n", yytext, yylineno);
                    return CTE_STRING;
                }

{ID}			{int tok = buscar_reservada(yytext);
                    if (tok != -1) {
                printf("\nPalabra reservada: %s en la línea %d\n", yytext, yylineno);
                return tok;
                     } else {
                if (ts_insertar_identificador(&tabla_simbolos, yytext, yylineno) == TS_INDICE_INVALIDO) {
                    fprintf(stderr, "\nError: no hay memoria para guardar el identificador %s\n", yytext);
                    exit(EXIT_FAILURE);
                }
                printf("\nIdentificador: %s en la línea %d\n", yytext, yylineno);
                return ID;
                    }}

{OP_SPACESHIP}		{printf("\nSpaceship: %s en la línea %d\n", yytext, yylineno);return OP_SPACESHIP;}
{OP_MEN_IG}		{printf("\nMenorIgual: %s en la línea %d\n", yytext, yylineno);return OP_MEN_IG;}
{OP_MAY_IG}		{printf("\nMayorIgual: %s en la línea %d\n", yytext, yylineno);return OP_MAY_IG;}
{OP_IGUAL}		{printf("\nIgual: %s en la línea %d\n", yytext, yylineno);return OP_IGUAL;}
{OP_DIF}		{printf("\nDistinto: %s en la línea %d\n", yytext, yylineno);return OP_DIF;}
{OP_MENOR}		{printf("\nMenor: %s en la línea %d\n", yytext, yylineno);return OP_MENOR;}
{OP_MAYOR}		{printf("\nMayor: %s en la línea %d\n", yytext, yylineno);return OP_MAYOR;}

{OP_ASIG}		{printf("\nAsignacion: %s en la línea %d\n", yytext, yylineno);return OP_ASIG;}
{OP_SUM}		{printf("\nSuma: %s en la línea %d\n", yytext, yylineno);return OP_SUM;}
{OP_MUL}		{printf("\nMultiplicacion: %s en la línea %d\n", yytext, yylineno);return OP_MUL;}
{OP_RES}		{printf("\nResta: %s en la línea %d\n", yytext, yylineno);return OP_RES;}
{OP_DIV}		{printf("\nDivision: %s en la línea %d\n", yytext, yylineno);return OP_DIV;}
{OP_POT}		{printf("\nPotencia: %s en la línea %d\n", yytext, yylineno);return OP_POT;}
{OP_RANGO}		{printf("\nRango: %s en la línea %d\n", yytext, yylineno);return OP_RANGO;}

{PAR_AP}		{printf("\nParAbre: %s en la línea %d\n", yytext, yylineno);return PAR_AP;}
{PAR_CI}		{printf("\nParCierra: %s en la línea %d\n", yytext, yylineno);return PAR_CI;}
{DOS_PUNTOS}		{printf("\nDosPuntos: %s en la línea %d\n", yytext, yylineno);return DOS_PUNTOS;}
{COMA}			{printf("\nComa: %s en la línea %d\n", yytext, yylineno);return COMA;}
{LLAVE_AP}		{printf("\nLlaveAbre: %s en la línea %d\n", yytext, yylineno);return LLAVE_AP;}
{LLAVE_CI}		{printf("\nLlaveCierra: %s en la línea %d\n", yytext, yylineno);return LLAVE_CI;}

"\n"      		
"\t"
"\n\t"
" "             		
"\r\n"
.			 { printf( "\nError Léxico : Caracter no reconocido: %s en la línea %d\n", yytext, yylineno ); exit (0);}
