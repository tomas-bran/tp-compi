%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "y.tab.h"
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

CTE_INT			{DIGITO}+
CTE_FLOAT		{DIGITO}+"."{DIGITO}+
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
OP_SPACESHIP		"<=>"
OP_RANGO		".."

%%

"#+"([^+]|"+"[^#])*"+#"	{ /* comentario: se descarta, no genera token */ }

{CTE_FLOAT}		{
                    double valor = atof(yytext);
                    if (valor > 3.4028235e38) {
                        printf("\nERROR LEXICO: Constante Float fuera de cota: %s\n", yytext);
                        exit(0);
                    }
                    printf("\nConstante Float: %s\n", yytext);
                    return CTE_FLOAT;
                }
{CTE_INT}		{
                    long valor = atol(yytext);
                    if (valor > 32767) {
                        printf("\nERROR LEXICO: Constante Int fuera de cota (max 32767): %s\n", yytext);
                        exit(0);
                    }
                    printf("\nConstante Int: %s\n", yytext);
                    return CTE_INT;
                }
{CTE_STRING}		{
                    int longitud = strlen(yytext) - 2;
                    if (longitud > 50) {
                        printf("\nERROR LEXICO: Constante String excede 50 caracteres: %s\n", yytext);
                        exit(0);
                    }
                    printf("\nConstante String: %s\n", yytext);
                    return CTE_STRING;
                }

{ID}			{int tok = buscar_reservada(yytext);
                    if (tok != -1) {
                printf("\nPalabra reservada: %s\n", yytext);
                return tok;
                     } else {
                printf("\nIdentificador: %s\n", yytext);
                return ID;
                    }}

{OP_SPACESHIP}		{printf("\nSpaceship: %s\n", yytext);return OP_SPACESHIP;}
{OP_MEN_IG}		{printf("\nMenorIgual: %s\n", yytext);return OP_MEN_IG;}
{OP_MAY_IG}		{printf("\nMayorIgual: %s\n", yytext);return OP_MAY_IG;}
{OP_IGUAL}		{printf("\nIgual: %s\n", yytext);return OP_IGUAL;}
{OP_DIF}		{printf("\nDistinto: %s\n", yytext);return OP_DIF;}
{OP_MENOR}		{printf("\nMenor: %s\n", yytext);return OP_MENOR;}
{OP_MAYOR}		{printf("\nMayor: %s\n", yytext);return OP_MAYOR;}

{OP_ASIG}		{printf("\nAsignacion: %s\n", yytext);return OP_ASIG;}
{OP_SUM}		{printf("\nSuma: %s\n", yytext);return OP_SUM;}
{OP_MUL}		{printf("\nMultiplicacion: %s\n", yytext);return OP_MUL;}
{OP_RES}		{printf("\nResta: %s\n", yytext);return OP_RES;}
{OP_DIV}		{printf("\nDivision: %s\n", yytext);return OP_DIV;}
{OP_POT}		{printf("\nPotencia: %s\n", yytext);return OP_POT;}
{OP_RANGO}		{printf("\nRango: %s\n", yytext);return OP_RANGO;}

{PAR_AP}		{printf("\nParAbre: %s\n", yytext);return PAR_AP;}
{PAR_CI}		{printf("\nParCierra: %s\n", yytext);return PAR_CI;}
{DOS_PUNTOS}		{printf("\nDosPuntos: %s\n", yytext);return DOS_PUNTOS;}
{COMA}			{printf("\nComa: %s\n", yytext);return COMA;}
{LLAVE_AP}		{printf("\nLlaveAbre: %s\n", yytext);return LLAVE_AP;}
{LLAVE_CI}		{printf("\nLlaveCierra: %s\n", yytext);return LLAVE_CI;}

"\n"      		
"\t"
"\n\t"
" "             		
"\r\n"
.			 { printf( "ERROR LEXICO : Caracter no reconocido: %s\n", yytext ); exit (0);}
