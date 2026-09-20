%{
#include <errno.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "y.tab.h"
#include "tabla_simbolos.h"

#define LIMITE_FLOAT 3.4028235e38

typedef struct {
    const char *palabra;
    int token;
} PalabraReservada;

static PalabraReservada tabla_reservadas[] = {
    {"init", INIT},
    {"Float", TIPO_FLOAT},
    {"Int", TIPO_INT},
    {"String", TIPO_STRING},
    {"AND", AND},
    {"OR", OR},
    {"NOT", NOT},
    {"if", IF},
    {"else", ELSE},
    {"while", WHILE},
    {"read", READ},
    {"write", WRITE},
    {"when", WHEN},
    {"is", IS},
    {"in", IN}
};

static int espera_operando = 1;
static int signo_unario_pendiente = 1;

static int buscar_reservada(const char *lexema)
{
    int cantidad = sizeof(tabla_reservadas) / sizeof(tabla_reservadas[0]);

    for (int i = 0; i < cantidad; i++) {
        if (strcmp(lexema, tabla_reservadas[i].palabra) == 0) {
            return tabla_reservadas[i].token;
        }
    }

    return -1;
}

static int retornar_valor(int token)
{
    espera_operando = 0;
    signo_unario_pendiente = 1;
    return token;
}

static int retornar_inicio_operando(int token)
{
    espera_operando = 1;
    signo_unario_pendiente = 1;
    return token;
}

static int retornar_suma_resta(int token)
{
    if (espera_operando) {
        if (token == OP_RES) {
            signo_unario_pendiente = -signo_unario_pendiente;
        }
    } else {
        signo_unario_pendiente = 1;
    }

    espera_operando = 1;
    return token;
}
%}

%option noyywrap
%option yylineno

DIGITO              [0-9]
LETRA               [a-zA-Z]
ESPACIO             [ \t\n]+
CTE_INT_POSITIVA    {DIGITO}+
CTE_FLOAT_POSITIVA  {DIGITO}+"."{DIGITO}+
CTE_STRING          \"({LETRA}|{DIGITO}|{ESPACIO})*\"
ID                  {LETRA}({LETRA}|{DIGITO})*
OP_SUM              "+"
OP_MUL              "*"
OP_RES              "-"
OP_DIV              "/"
PAR_AP              "("
PAR_CI              ")"
DOS_PUNTOS          ":"
COMA                ","
LLAVE_AP            "{"
LLAVE_CI            "}"
OP_IGUAL            "=="
OP_ASIG             ":="
OP_MENOR            "<"
OP_MAYOR            ">"
OP_MEN_IG           "<="
OP_MAY_IG           ">="
OP_DIF              "!="
OP_POT              "**"
OP_SPACESHIP        "<=>"
OP_RANGO            ".."

%%

"#+"([^+]|"+"[^#])*"+#" {
    /* El comentario se descarta. */
}

{CTE_FLOAT_POSITIVA} {
    char *fin;
    double valor;
    int es_negativa;

    errno = 0;
    valor = strtod(yytext, &fin);
    es_negativa = signo_unario_pendiente < 0;

    if (fin == yytext || *fin != '\0' || !isfinite(valor) || valor > LIMITE_FLOAT) {
        fprintf(stderr, "\nError Léxico: Constante Float fuera de cota: %s%s en la línea %d. El rango permitido es aproximadamente -3.4028235e38 a 3.4028235e38.\n", es_negativa ? "-" : "", yytext, yylineno);
        exit(EXIT_FAILURE);
    }

    if (ts_insertar_constante(&tabla_simbolos, TD_FLOAT, yytext, -1, yylineno) == TS_INDICE_INVALIDO) {
        fprintf(stderr, "\nError: no hay memoria para guardar la constante %s\n", yytext);
        exit(EXIT_FAILURE);
    }

    printf("\nConstante Float: %s%s en la línea %d\n", es_negativa ? "-" : "", yytext, yylineno);
    return retornar_valor(CTE_FLOAT_POSITIVA);
}

{CTE_INT_POSITIVA} {
    char *fin;
    long long valor;
    long long limite;
    int es_negativa;

    errno = 0;
    valor = strtoll(yytext, &fin, 10);
    es_negativa = signo_unario_pendiente < 0;
    limite = es_negativa ? 32768LL : 32767LL;

    if (errno == ERANGE || fin == yytext || *fin != '\0' || valor > limite) {
        if (!es_negativa && errno != ERANGE && fin != yytext && *fin == '\0' && valor == 32768LL) {
            fprintf(stderr, "\nError Léxico: Constante Int positiva fuera de cota: %s en la línea %d. El máximo positivo permitido es 32767. La magnitud 32768 solo es válida con un signo menos unario, formando -32768.\n", yytext, yylineno);
        } else if (es_negativa) {
            fprintf(stderr, "\nError Léxico: Constante Int negativa fuera de cota: -%s en la línea %d. El mínimo permitido es -32768.\n", yytext, yylineno);
        } else {
            fprintf(stderr, "\nError Léxico: Constante Int positiva fuera de cota: %s en la línea %d. El máximo permitido es 32767.\n", yytext, yylineno);
        }

        exit(EXIT_FAILURE);
    }

    if (ts_insertar_constante(&tabla_simbolos, TD_INT, yytext, -1, yylineno) == TS_INDICE_INVALIDO) {
        fprintf(stderr, "\nError: no hay memoria para guardar la constante %s\n", yytext);
        exit(EXIT_FAILURE);
    }

    printf("\nConstante Int: %s%s en la línea %d\n", es_negativa ? "-" : "", yytext, yylineno);
    return retornar_valor(CTE_INT_POSITIVA);
}

{CTE_STRING} {
    int longitud = strlen(yytext) - 2;
    char *valor;

    if (longitud > 50) {
        fprintf(stderr, "\nError Léxico: Constante String excede 50 caracteres: %s en la línea %d\n", yytext, yylineno);
        exit(EXIT_FAILURE);
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
    return retornar_valor(CTE_STRING);
}

{ID} {
    int token = buscar_reservada(yytext);

    if (token != -1) {
        printf("\nPalabra reservada: %s en la línea %d\n", yytext, yylineno);
        return retornar_inicio_operando(token);
    }

    if (ts_insertar_identificador(&tabla_simbolos, yytext, yylineno) == TS_INDICE_INVALIDO) {
        fprintf(stderr, "\nError: no hay memoria para guardar el identificador %s\n", yytext);
        exit(EXIT_FAILURE);
    }

    printf("\nIdentificador: %s en la línea %d\n", yytext, yylineno);
    return retornar_valor(ID);
}

{OP_SPACESHIP} {
    printf("\nSpaceship: %s en la línea %d\n", yytext, yylineno);
    return retornar_inicio_operando(OP_SPACESHIP);
}

{OP_MEN_IG} {
    printf("\nMenorIgual: %s en la línea %d\n", yytext, yylineno);
    return retornar_inicio_operando(OP_MEN_IG);
}

{OP_MAY_IG} {
    printf("\nMayorIgual: %s en la línea %d\n", yytext, yylineno);
    return retornar_inicio_operando(OP_MAY_IG);
}

{OP_IGUAL} {
    printf("\nIgual: %s en la línea %d\n", yytext, yylineno);
    return retornar_inicio_operando(OP_IGUAL);
}

{OP_DIF} {
    printf("\nDistinto: %s en la línea %d\n", yytext, yylineno);
    return retornar_inicio_operando(OP_DIF);
}

{OP_MENOR} {
    printf("\nMenor: %s en la línea %d\n", yytext, yylineno);
    return retornar_inicio_operando(OP_MENOR);
}

{OP_MAYOR} {
    printf("\nMayor: %s en la línea %d\n", yytext, yylineno);
    return retornar_inicio_operando(OP_MAYOR);
}

{OP_ASIG} {
    printf("\nAsignacion: %s en la línea %d\n", yytext, yylineno);
    return retornar_inicio_operando(OP_ASIG);
}

{OP_SUM} {
    printf("\nSuma: %s en la línea %d\n", yytext, yylineno);
    return retornar_suma_resta(OP_SUM);
}

{OP_RES} {
    printf("\nResta o negacion: %s en la línea %d\n", yytext, yylineno);
    return retornar_suma_resta(OP_RES);
}

{OP_MUL} {
    printf("\nMultiplicacion: %s en la línea %d\n", yytext, yylineno);
    return retornar_inicio_operando(OP_MUL);
}

{OP_DIV} {
    printf("\nDivision: %s en la línea %d\n", yytext, yylineno);
    return retornar_inicio_operando(OP_DIV);
}

{OP_POT} {
    printf("\nPotencia: %s en la línea %d\n", yytext, yylineno);
    return retornar_inicio_operando(OP_POT);
}

{OP_RANGO} {
    printf("\nRango: %s en la línea %d\n", yytext, yylineno);
    return retornar_inicio_operando(OP_RANGO);
}

{PAR_AP} {
    printf("\nParAbre: %s en la línea %d\n", yytext, yylineno);
    return retornar_inicio_operando(PAR_AP);
}

{PAR_CI} {
    printf("\nParCierra: %s en la línea %d\n", yytext, yylineno);
    return retornar_valor(PAR_CI);
}

{DOS_PUNTOS} {
    printf("\nDosPuntos: %s en la línea %d\n", yytext, yylineno);
    return retornar_inicio_operando(DOS_PUNTOS);
}

{COMA} {
    printf("\nComa: %s en la línea %d\n", yytext, yylineno);
    return retornar_inicio_operando(COMA);
}

{LLAVE_AP} {
    printf("\nLlaveAbre: %s en la línea %d\n", yytext, yylineno);
    return retornar_inicio_operando(LLAVE_AP);
}

{LLAVE_CI} {
    printf("\nLlaveCierra: %s en la línea %d\n", yytext, yylineno);
    return retornar_inicio_operando(LLAVE_CI);
}

[ \t\r\n]+ {
    /* Los espacios en blanco se descartan. */
}

. {
    fprintf(stderr, "\nError Léxico: Caracter no reconocido: %s en la línea %d\n", yytext, yylineno);
    exit(EXIT_FAILURE);
}

%%
