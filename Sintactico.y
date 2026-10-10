%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "tabla_simbolos.h"
#include "polaca.h"

extern FILE *yyin;
extern char *yytext;
extern int yylineno;

#define MAX_IDS_DECL 100

static char *ids_pendientes[MAX_IDS_DECL];
static int cant_ids_pendientes = 0;

void yyerror(const char *mensaje);
int yylex(void);

static void regla(const char *nombre)
{
    printf("Regla: %s\n", nombre);
}

static void agregar_id_pendiente(char *nombre)
{
    if (cant_ids_pendientes >= MAX_IDS_DECL)
    {
        fprintf(stderr, "\nError: demasiadas variables en una misma declaracion.\n");
        exit(EXIT_FAILURE);
    }
    ids_pendientes[cant_ids_pendientes++] = nombre;
}

static void error_semantico(const char *mensaje, const char *nombre)
{
    fprintf(stderr, "\nError Semantico en la línea %d: %s: %s.\n", yylineno, mensaje, nombre);
    exit(EXIT_FAILURE);
}

static void verificar_declarada(const char *nombre)
{
    if (ts_obtener_tipo(&tabla_simbolos, nombre) == TD_DESCONOCIDO)
    {
        error_semantico("Variable no declarada", nombre);
    }
}

static void error_semantico_msg(const char *mensaje) // Es necesaria ya que en verificar_numerico no se tiene un nombre de variable para mostrar
{
    fprintf(stderr, "\nError Semantico en la línea %d: %s.\n", yylineno, mensaje);
    exit(EXIT_FAILURE);
}

static void verificar_numerico(TipoDato tipo)
{
    if (tipo == TD_STRING)
    {
        error_semantico_msg("Una operacion aritmetica no admite operandos String");
    }
}

static TipoDato tipo_resultado(TipoDato a, TipoDato b)
{
    if (a == TD_FLOAT || b == TD_FLOAT)
    {
        return TD_FLOAT;
    }
    return TD_INT;
}

static const char *nombre_tipo_txt(TipoDato tipo)
{
    switch (tipo)
    {
    case TD_INT:
        return "Int";
    case TD_FLOAT:
        return "Float";
    case TD_STRING:
        return "String";
    default:
        return "desconocido";
    }
}

static int tipos_compatibles(TipoDato destino, TipoDato origen)
{
    if (destino == origen)
    {
        return 1;
    }
    return destino == TD_FLOAT && origen == TD_INT;
}

static void verificar_asignacion(const char *nombre, TipoDato origen)
{
    TipoDato destino = ts_obtener_tipo(&tabla_simbolos, nombre);

    if (!tipos_compatibles(destino, origen))
    {
        fprintf(stderr,
                "\nError Semantico en la línea %d: No se puede asignar un valor %s a la variable %s de tipo %s.\n",
                yylineno, nombre_tipo_txt(origen), nombre, nombre_tipo_txt(destino));
        exit(EXIT_FAILURE);
    }
}

static void verificar_comparacion(TipoDato izq, TipoDato der)
{
    int ok = (izq == der) ||
             (izq == TD_INT && der == TD_FLOAT) ||
             (izq == TD_FLOAT && der == TD_INT);

    if (!ok)
    {
        fprintf(stderr,
                "\nError Semantico en la línea %d: No se pueden comparar un valor %s con un valor %s.\n",
                yylineno, nombre_tipo_txt(izq), nombre_tipo_txt(der));
        exit(EXIT_FAILURE);
    }
}

static const char *salto_inverso(const char *op)
{
    if (strcmp(op, ">=") == 0) return "BLT";
    if (strcmp(op, ">")  == 0) return "BLE";
    if (strcmp(op, "<=") == 0) return "BGT";
    if (strcmp(op, "<")  == 0) return "BGE";
    if (strcmp(op, "==") == 0) return "BNE";
    if (strcmp(op, "!=") == 0) return "BEQ";

    fprintf(stderr, "Error interno: comparador desconocido %s.\n", op);
    exit(EXIT_FAILURE);
}

static const char *invertir_salto(const char *salto)
{
    if (strcmp(salto, "BGE") == 0) return "BLT";
    if (strcmp(salto, "BLT") == 0) return "BGE";
    if (strcmp(salto, "BLE") == 0) return "BGT";
    if (strcmp(salto, "BGT") == 0) return "BLE";
    if (strcmp(salto, "BNE") == 0) return "BEQ";
    if (strcmp(salto, "BEQ") == 0) return "BNE";

    fprintf(stderr, "Error interno: salto desconocido %s.\n", salto);
    exit(EXIT_FAILURE);
}

//desapila 'cantidad' saltos pendientes y los completa con el mismo destino 
static void completar_saltos(int cantidad, size_t destino)
{
    int i;

    for (i = 0; i < cantidad; i++)
    {
        polaca_escribir_en(pila_desapilar(), destino);
    }
}

static void asignar_tipo_pendientes(TipoDato tipo)
{
    int i;

    for (i = 0; i < cant_ids_pendientes; i++)
    {
        if (ts_obtener_tipo(&tabla_simbolos, ids_pendientes[i]) != TD_DESCONOCIDO)
        {
            error_semantico("Variable declarada mas de una vez", ids_pendientes[i]);
        }
        ts_asignar_tipo(&tabla_simbolos, ids_pendientes[i], tipo);
        free(ids_pendientes[i]);
    }
    cant_ids_pendientes = 0;
}
%}

%union {
    char *str;
    int tipo;
    int cant;

}

%token <str> CTE_INT_POSITIVA CTE_FLOAT_POSITIVA CTE_STRING ID
%token OP_ASIG OP_SUM OP_MUL OP_RES OP_DIV
%token PAR_AP PAR_CI

/* Declaracion de variables */
%token INIT TIPO_FLOAT TIPO_INT TIPO_STRING
%token DOS_PUNTOS COMA LLAVE_AP LLAVE_CI

/* Comparadores */
%token OP_IGUAL OP_MENOR OP_MAYOR OP_MEN_IG OP_MAY_IG OP_DIF

/* Logicos y control */
%token AND OR NOT IF ELSE WHILE READ WRITE

/* TE1 - matchPatterns */
%token WHEN IS IN OP_RANGO

/* TE3 - powerSpaceship */
%token OP_POT OP_SPACESHIP

%type <tipo> tipo expresion exp_aritmetica termino unario potencia atomo
%type <str> comparador
%type <cant> condicion cond_compuesta
%%

    programa
    : bloque_declaracion
    | bloque_declaracion lista_sentencias
    ;

    bloque_declaracion
    : INIT LLAVE_AP lista_declaraciones LLAVE_CI { regla("bloque_declaracion"); }
    ;

    lista_declaraciones
    : declaracion
    | lista_declaraciones declaracion
    ;

    declaracion
    : lista_ids DOS_PUNTOS tipo { asignar_tipo_pendientes($3); regla("declaracion"); }
    ;

    lista_ids
    : ID { agregar_id_pendiente($1); }
    | lista_ids COMA ID { agregar_id_pendiente($3); }
    ;

    tipo
    : TIPO_INT { $$ = TD_INT; regla("tipo_int"); }
    | TIPO_FLOAT { $$ = TD_FLOAT; regla("tipo_float"); }
    | TIPO_STRING { $$ = TD_STRING; regla("tipo_string"); }
    ;

    lista_sentencias
    : sentencia
    | lista_sentencias sentencia
    ;

    bloque
    : LLAVE_AP lista_sentencias LLAVE_CI
    ;

    sentencia
    : asignacion
    | lectura
    | escritura
    | seleccion
    | iteracion
    | seleccion_patrones
    ;

    asignacion
    : ID OP_ASIG expresion {  verificar_declarada($1); verificar_asignacion($1, $3); polaca_insertar($1); polaca_insertar(":="); free($1); regla("asignacion"); }
    ;

    lectura
    : READ PAR_AP ID PAR_CI { verificar_declarada($3); polaca_insertar($3); polaca_insertar("READ"); free($3); regla("lectura"); }
    ;

    escritura
    : WRITE PAR_AP expresion PAR_CI { polaca_insertar("WRITE"); regla("escritura"); }
    ;

    seleccion
    : IF PAR_AP condicion PAR_CI bloque
      {
          completar_saltos($3, polaca_actual());
          regla("seleccion_if");
      }
    | IF PAR_AP condicion PAR_CI bloque
      {
          // Fin del bloque verdadero 
          polaca_insertar("BI");                        // salto incondicional para saltear el else
          completar_saltos($3, polaca_actual() + 1);
          pila_apilar(polaca_avanzar());                // reserva la celda del destino del BI
      }
      ELSE bloque
      {
          // Fin del bloque falso
          size_t x = pila_desapilar();                  // celda del BI
          polaca_escribir_en(x, polaca_actual());       // primera celda posterior al else
          regla("seleccion_if_else");
      }
    ;

    iteracion
    : WHILE
      {
          pila_apilar(polaca_actual());     // nº de celda donde va a estar el ET
          polaca_insertar("ET");            // etiqueta de inicio del ciclo
      }
      PAR_AP condicion PAR_CI bloque
      {
          size_t et;
          size_t celda_destino;

          polaca_insertar("BI");                          // salto incondicional al inicio
          completar_saltos($4, polaca_actual() + 1); 

          et = pila_desapilar();                          // celda del ET
          celda_destino = polaca_avanzar();               // celda que lleva el destino del BI
          polaca_escribir_en(celda_destino, et);          // vuelve al ET

          regla("iteracion_while");
      }
    ;

    condicion
    : cond_simple                   { $$ = 1; }
    | cond_compuesta                { $$ = $1; }
    | PAR_AP cond_compuesta PAR_CI  { $$ = $2; }
    ;

    cond_compuesta
    : cond_simple AND cond_simple
      {
          $$ = 2;                                   //los dos saltos van al falso 
          regla("condicion_and");
      }
    | cond_simple OR cond_simple
      {
          size_t segundo = pila_desapilar();
          size_t primero = pila_desapilar();

          // la celda del mnemonico es la anterior a la del destino
          polaca_reemplazar(primero - 1, invertir_salto(polaca_obtener(primero - 1)));
          polaca_escribir_en(primero, polaca_actual());   // si se cumple la 1ra, va al bloque verdadero
          pila_apilar(segundo);                           // queda pendiente solo el salto al falso
          $$ = 1;
          regla("condicion_or");
      }
    | NOT cond_simple
      {
          size_t celda = pila_desapilar();

          polaca_reemplazar(celda - 1, invertir_salto(polaca_obtener(celda - 1)));
          pila_apilar(celda);
          $$ = 1;
          regla("condicion_not");
      }
    ;

    cond_simple
    : expresion comparador expresion
      {
          verificar_comparacion($1, $3);
          polaca_insertar("CMP");
          polaca_insertar(salto_inverso($2));
          pila_apilar(polaca_avanzar());   // reserva la celda del destino y guarda su nº 
          regla("condicion_simple");
      }
    | PAR_AP cond_simple PAR_CI
    ;

    comparador
    : OP_IGUAL  { $$ = "=="; regla("comparador_igual"); }
    | OP_DIF    { $$ = "!="; regla("comparador_distinto"); }
    | OP_MENOR  { $$ = "<";  regla("comparador_menor"); }
    | OP_MAYOR  { $$ = ">";  regla("comparador_mayor"); }
    | OP_MEN_IG { $$ = "<="; regla("comparador_menor_igual"); }
    | OP_MAY_IG { $$ = ">="; regla("comparador_mayor_igual"); }
    ;

    seleccion_patrones
    : WHEN PAR_AP expresion PAR_CI LLAVE_AP lista_ramas LLAVE_CI { regla("when_sin_defecto"); }
    | WHEN PAR_AP expresion PAR_CI LLAVE_AP lista_ramas rama_defecto LLAVE_CI { regla("when_con_defecto"); }
    ;

    lista_ramas
    : rama
    | lista_ramas rama
    ;

    rama
    : patron bloque { regla("rama_when"); }
    ;

    rama_defecto
    : ELSE bloque { regla("rama_defecto"); }
    ;

    patron
    : IS constante { regla("patron_valor_exacto"); }
    | IN constante OP_RANGO constante { regla("patron_rango"); }
    | IS comparador constante { regla("patron_guarda"); }
    ;

    constante
    : cte_numerica
    | OP_RES cte_numerica { regla("constante_negativa"); }
    | OP_SUM cte_numerica { regla("constante_positiva"); }
    | CTE_STRING
    ;

    cte_numerica
    : CTE_INT_POSITIVA
    | CTE_FLOAT_POSITIVA
    ;

    expresion
    : exp_aritmetica
    | exp_aritmetica OP_SPACESHIP exp_aritmetica { verificar_numerico($1); verificar_numerico($3); $$ = TD_INT; regla("spaceship"); }
    ;

    exp_aritmetica
    : termino
    | exp_aritmetica OP_SUM termino { verificar_numerico($1); verificar_numerico($3); $$ = tipo_resultado($1, $3); polaca_insertar("+"); regla("suma"); }
    | exp_aritmetica OP_RES termino { verificar_numerico($1); verificar_numerico($3); $$ = tipo_resultado($1, $3); polaca_insertar("-"); regla("resta"); }
    ;

    termino
    : unario
    | termino OP_MUL unario { verificar_numerico($1); verificar_numerico($3); $$ = tipo_resultado($1, $3); polaca_insertar("*"); regla("multiplicacion"); }
    | termino OP_DIV unario { verificar_numerico($1); verificar_numerico($3); $$ = tipo_resultado($1, $3); polaca_insertar("/"); regla("division"); }
    ;

    unario
    : potencia
    | OP_RES unario { verificar_numerico($2); $$ = $2; polaca_insertar("NEG"); regla("negacion"); }
    | OP_SUM unario { verificar_numerico($2); $$ = $2; regla("positivo"); }
    ;

    potencia
    : atomo
    | atomo OP_POT unario { verificar_numerico($1); verificar_numerico($3); $$ = $1; regla("potencia"); }
    ;

    atomo
    : ID { verificar_declarada($1); $$ = ts_obtener_tipo(&tabla_simbolos, $1); polaca_insertar($1); free($1); }
    | CTE_INT_POSITIVA { $$ = TD_INT; polaca_insertar($1); free($1); }
    | CTE_FLOAT_POSITIVA { $$ = TD_FLOAT; polaca_insertar($1); free($1); }
    | CTE_STRING { $$ = TD_STRING; polaca_insertar($1); free($1); }
    | PAR_AP expresion PAR_CI { $$ = $2; }
    ;

%%

int main(int argc, char *argv[])
{
    int resultado_parser;

    if (argc < 2) {
        fprintf(stderr, "Uso: %s <archivo-fuente>\n", argv[0]);
        return EXIT_FAILURE;
    }

    ts_inicializar(&tabla_simbolos);
    polaca_inicializar();

    if (!ts_guardar_archivo(&tabla_simbolos, "symbol-table.txt")) {
        ts_destruir(&tabla_simbolos);
        polaca_destruir();
        return EXIT_FAILURE;
    }

    yyin = fopen(argv[1], "rt");

    if (yyin == NULL) {
        fprintf(stderr, "\nNo se puede abrir el archivo de prueba: %s\n", argv[1]);
        ts_destruir(&tabla_simbolos);
        polaca_destruir();
        return EXIT_FAILURE;
    }

    resultado_parser = yyparse();
    fclose(yyin);

    if (resultado_parser == 0 &&
        (!ts_guardar_archivo(&tabla_simbolos, "symbol-table.txt") ||
         !polaca_guardar_archivo("intermediate-code.txt"))) {
        ts_destruir(&tabla_simbolos);
        polaca_destruir();
        return EXIT_FAILURE;
    }

    ts_destruir(&tabla_simbolos);
    polaca_destruir();
    return resultado_parser == 0 ? EXIT_SUCCESS : EXIT_FAILURE;
}

void yyerror(const char *mensaje)
{
    fprintf(stderr, "\nError Sintactico en la línea %d cerca de \"%s\": %s.\n", yylineno, yytext, mensaje);
    exit(EXIT_FAILURE);
}
