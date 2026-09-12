%{
#include <stdio.h>
#include <stdlib.h>

// Se utiliza extern para usar una variable que fue creada en otro archivo (y no volver a declararla)
extern FILE* yyin;
extern char* yytext;
extern int yylineno;

int yyerror();
int yylex();

// Se utiliza static para quitar visibilidad de la funcion a otros archivos, ya que solo se utiliza en este archivo
static void regla(const char* nombre)
{
    printf("Regla: %s\n", nombre);
}
%}

%token CTE_INT_POSITIVA
%token CTE_INT_NEGATIVA
%token CTE_FLOAT_POSITIVA
%token CTE_FLOAT_NEGATIVA
%token CTE_STRING
%token ID
%token OP_ASIG
%token OP_SUM
%token OP_MUL
%token OP_RES
%token OP_DIV
%token PAR_AP
%token PAR_CI

// Declaracion de variables
%token INIT
%token TIPO_FLOAT
%token TIPO_INT
%token TIPO_STRING
%token DOS_PUNTOS
%token COMA
%token LLAVE_AP
%token LLAVE_CI

// Comparadores
%token OP_IGUAL
%token OP_MENOR
%token OP_MAYOR
%token OP_MEN_IG
%token OP_MAY_IG
%token OP_DIF

// Logicos y control
%token AND
%token OR
%token NOT
%token IF
%token ELSE
%token WHILE
%token READ
%token WRITE

// TE1 - matchPatterns
%token WHEN
%token IS
%token IN
%token OP_RANGO

// TE3 - powerSpaceship
%token OP_POT
%token OP_SPACESHIP

%%

    programa
    : bloque_declaracion lista_sentencias;

    bloque_declaracion
    : INIT LLAVE_AP lista_declaraciones LLAVE_CI { regla("bloque_declaracion"); };

    lista_declaraciones
    : declaracion | lista_declaraciones declaracion;

    declaracion
    : lista_ids DOS_PUNTOS tipo { regla("declaracion"); };

    lista_ids
    : ID | lista_ids COMA ID;

    tipo
    : TIPO_INT { regla("tipo_int"); }
    | TIPO_FLOAT { regla("tipo_float"); }
    | TIPO_STRING { regla("tipo_string"); };

    lista_sentencias
    : sentencia
    | lista_sentencias sentencia;

    bloque
    : LLAVE_AP lista_sentencias LLAVE_CI;

    sentencia
    : asignacion
    | lectura
    | escritura
    | seleccion
    | iteracion
    | seleccion_patrones
    ;

    asignacion
    : ID OP_ASIG expresion { regla("asignacion"); };

    lectura
    : READ PAR_AP ID PAR_CI { regla("lectura"); };

    escritura
    : WRITE PAR_AP expresion PAR_CI { regla("escritura"); };

    seleccion
    : IF PAR_AP condicion PAR_CI bloque { regla("seleccion_if"); }
    | IF PAR_AP condicion PAR_CI bloque ELSE bloque { regla("seleccion_if_else"); };

    iteracion
    : WHILE PAR_AP condicion PAR_CI bloque { regla("iteracion_while"); };

    condicion
    : cond_simple
    | cond_compuesta
    | PAR_AP cond_compuesta PAR_CI;

    cond_compuesta
    : cond_simple AND cond_simple { regla("condicion_and"); }
    | cond_simple OR cond_simple { regla("condicion_or"); }
    | NOT cond_simple { regla("condicion_not"); };

    cond_simple
    : expresion comparador expresion { regla("condicion_simple"); }
    | PAR_AP cond_simple PAR_CI;

    comparador
    : OP_IGUAL { regla("comparador_igual"); }
    | OP_DIF { regla("comparador_distinto"); }
    | OP_MENOR { regla("comparador_menor"); }
    | OP_MAYOR { regla("comparador_mayor"); }
    | OP_MEN_IG { regla("comparador_menor_igual"); }
    | OP_MAY_IG { regla("comparador_mayor_igual"); };

    seleccion_patrones
    : WHEN PAR_AP expresion PAR_CI LLAVE_AP lista_ramas LLAVE_CI
        { regla("when_sin_defecto"); }
    | WHEN PAR_AP expresion PAR_CI LLAVE_AP lista_ramas rama_defecto LLAVE_CI
        { regla("when_con_defecto"); };

    lista_ramas
    : rama
    | lista_ramas rama;

    rama
    : patron bloque { regla("rama_when"); };

    rama_defecto
    : ELSE bloque { regla("rama_defecto"); };

    patron
    : IS constante { regla("patron_valor_exacto"); }
    | IN constante OP_RANGO constante { regla("patron_rango"); }
    | IS comparador constante { regla("patron_guarda"); };

    constante
    : cte_numerica
    | OP_RES cte_numerica { regla("constante_negativa"); }
    | OP_SUM cte_numerica { regla("constante_positiva"); }
    | CTE_STRING;

    cte_numerica
    : CTE_INT_POSITIVA
    | CTE_INT_NEGATIVA
    | CTE_FLOAT_POSITIVA
    | CTE_FLOAT_NEGATIVA;

    expresion
    : exp_aritmetica
    | exp_aritmetica OP_SPACESHIP exp_aritmetica { regla("spaceship"); };

    exp_aritmetica
    : termino
    | exp_aritmetica OP_SUM termino { regla("suma"); }
    | exp_aritmetica OP_RES termino { regla("resta"); };

    termino
    : unario
    | termino OP_MUL unario { regla("multiplicacion"); }
    | termino OP_DIV unario { regla("division"); };

    unario
    : potencia
    | OP_RES unario { regla("negacion"); }
    | OP_SUM unario { regla("positivo"); };

    potencia
    : atomo
    | atomo OP_POT unario { regla("potencia"); };

    atomo
    : ID
    | CTE_INT_POSITIVA
    | CTE_INT_NEGATIVA
    | CTE_FLOAT_POSITIVA
    | CTE_FLOAT_NEGATIVA
    | CTE_STRING
    | PAR_AP expresion PAR_CI;

%%

#undef yyerror

int main(int argc, char *argv[])
{
    if((yyin = fopen(argv[1], "rt"))==NULL)
    {
        printf("\nNo se puede abrir el archivo de prueba: %s\n", argv[1]);
    }
    else
    { 
        yyparse();
    }

    fclose(yyin);
    return 0;
}

int yyerror(void)
{
    fprintf(stderr, "\nError Sintactico en la línea %d\n.", yylineno);
    exit(1);
}
