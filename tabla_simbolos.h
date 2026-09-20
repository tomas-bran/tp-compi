#ifndef TABLA_SIMBOLOS_H
#define TABLA_SIMBOLOS_H

#include <stddef.h>

typedef enum {
    CLASE_VARIABLE,
    CLASE_CONSTANTE,
    CLASE_AUXILIAR
} ClaseSimbolo;

typedef enum {
    TD_DESCONOCIDO,
    TD_INT,
    TD_FLOAT,
    TD_STRING
} TipoDato;

typedef struct {
    char *nombre;
    ClaseSimbolo clase;
    TipoDato tipo;
    char *valor;
    int longitud;
    int linea;
} Simbolo;

typedef struct {
    Simbolo *simbolos;
    size_t cantidad;
    size_t capacidad;
} TablaSimbolos;

#define TS_INDICE_INVALIDO ((size_t)-1)

extern TablaSimbolos tabla_simbolos;

void ts_inicializar(TablaSimbolos *tabla);
void ts_destruir(TablaSimbolos *tabla);

size_t ts_insertar_identificador(
    TablaSimbolos *tabla,
    const char *nombre,
    int linea
);

size_t ts_insertar_constante(
    TablaSimbolos *tabla,
    TipoDato tipo,
    const char *valor,
    int longitud,
    int linea
);

int ts_guardar_archivo(const TablaSimbolos *tabla, const char *ruta);

#endif
