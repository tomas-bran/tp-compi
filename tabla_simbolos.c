#include "tabla_simbolos.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define CAPACIDAD_INICIAL 16

TablaSimbolos tabla_simbolos;

static char *duplicar_cadena(const char *cadena)
{
    size_t longitud = strlen(cadena) + 1;
    char *copia = malloc(longitud);

    if (copia != NULL)
    {
        memcpy(copia, cadena, longitud);
    }

    return copia;
}

static int asegurar_capacidad(TablaSimbolos *tabla)
{
    Simbolo *nuevos_simbolos;
    size_t nueva_capacidad;

    if (tabla->cantidad < tabla->capacidad)
    {
        return 1;
    }

    nueva_capacidad = tabla->capacidad == 0
                          ? CAPACIDAD_INICIAL
                          : tabla->capacidad * 2;

    nuevos_simbolos = realloc(
        tabla->simbolos,
        nueva_capacidad * sizeof(Simbolo));

    if (nuevos_simbolos == NULL)
    {
        return 0;
    }

    tabla->simbolos = nuevos_simbolos;
    tabla->capacidad = nueva_capacidad;
    return 1;
}

static size_t buscar_identificador(
    const TablaSimbolos *tabla,
    const char *nombre)
{
    size_t i;

    for (i = 0; i < tabla->cantidad; i++)
    {
        const Simbolo *simbolo = &tabla->simbolos[i];

        if (simbolo->clase == CLASE_VARIABLE && strcmp(simbolo->nombre, nombre) == 0)
        {
            return i;
        }
    }

    return TS_INDICE_INVALIDO;
}

static size_t buscar_constante(
    const TablaSimbolos *tabla,
    TipoDato tipo,
    const char *valor)
{
    size_t i;

    for (i = 0; i < tabla->cantidad; i++)
    {
        const Simbolo *simbolo = &tabla->simbolos[i];

        if (simbolo->clase == CLASE_CONSTANTE && simbolo->tipo == tipo && simbolo->valor != NULL && strcmp(simbolo->valor, valor) == 0)
        {
            return i;
        }
    }

    return TS_INDICE_INVALIDO;
}

static const char *nombre_tipo(const Simbolo *simbolo)
{
    if (simbolo->clase == CLASE_VARIABLE && simbolo->tipo == TD_DESCONOCIDO)
    {
        return "";
    }

    if (simbolo->clase == CLASE_CONSTANTE)
    {
        switch (simbolo->tipo)
        {
        case TD_INT:
            return "Cte_Int";
        case TD_FLOAT:
            return "Cte_Float";
        case TD_STRING:
            return "Cte_String";
        default:
            return "";
        }
    }

    switch (simbolo->tipo)
    {
    case TD_INT:
        return "Int";
    case TD_FLOAT:
        return "Float";
    case TD_STRING:
        return "String";
    default:
        return "";
    }
}

void ts_inicializar(TablaSimbolos *tabla)
{
    tabla->simbolos = NULL;
    tabla->cantidad = 0;
    tabla->capacidad = 0;
}

void ts_destruir(TablaSimbolos *tabla)
{
    size_t i;

    for (i = 0; i < tabla->cantidad; i++)
    {
        free(tabla->simbolos[i].nombre);
        free(tabla->simbolos[i].valor);
    }

    free(tabla->simbolos);
    ts_inicializar(tabla);
}

size_t ts_insertar_identificador(
    TablaSimbolos *tabla,
    const char *nombre,
    int linea)
{
    size_t indice = buscar_identificador(tabla, nombre);
    Simbolo *nuevo;

    if (indice != TS_INDICE_INVALIDO)
    {
        return indice;
    }

    if (!asegurar_capacidad(tabla))
    {
        return TS_INDICE_INVALIDO;
    }

    nuevo = &tabla->simbolos[tabla->cantidad];
    nuevo->nombre = duplicar_cadena(nombre);
    nuevo->valor = NULL;

    if (nuevo->nombre == NULL)
    {
        return TS_INDICE_INVALIDO;
    }

    nuevo->clase = CLASE_VARIABLE;
    nuevo->tipo = TD_DESCONOCIDO;
    nuevo->longitud = -1;
    nuevo->linea = linea;

    tabla->cantidad++;
    return tabla->cantidad - 1;
}

size_t ts_insertar_constante(
    TablaSimbolos *tabla,
    TipoDato tipo,
    const char *valor,
    int longitud,
    int linea)
{
    size_t indice = buscar_constante(tabla, tipo, valor);
    size_t longitud_nombre;
    Simbolo *nuevo;

    if (indice != TS_INDICE_INVALIDO)
    {
        return indice;
    }

    if (!asegurar_capacidad(tabla))
    {
        return TS_INDICE_INVALIDO;
    }

    nuevo = &tabla->simbolos[tabla->cantidad];
    nuevo->valor = duplicar_cadena(valor);
    longitud_nombre = strlen(valor) + 2;
    nuevo->nombre = malloc(longitud_nombre);

    if (nuevo->valor == NULL || nuevo->nombre == NULL)
    {
        free(nuevo->valor);
        free(nuevo->nombre);
        nuevo->valor = NULL;
        nuevo->nombre = NULL;
        return TS_INDICE_INVALIDO;
    }

    nuevo->nombre[0] = '_';
    memcpy(nuevo->nombre + 1, valor, longitud_nombre - 1);
    nuevo->clase = CLASE_CONSTANTE;
    nuevo->tipo = tipo;
    nuevo->longitud = longitud;
    nuevo->linea = linea;

    tabla->cantidad++;
    return tabla->cantidad - 1;
}

TipoDato ts_obtener_tipo(const TablaSimbolos *tabla, const char *nombre)
{
    size_t indice = buscar_identificador(tabla, nombre);

    if (indice == TS_INDICE_INVALIDO)
    {
        return TD_DESCONOCIDO;
    }

    return tabla->simbolos[indice].tipo;
}

int ts_asignar_tipo(TablaSimbolos *tabla, const char *nombre, TipoDato tipo)
{
    size_t indice = buscar_identificador(tabla, nombre);

    if (indice == TS_INDICE_INVALIDO)
    {
        return 0;
    }

    tabla->simbolos[indice].tipo = tipo;
    return 1;
}

int ts_guardar_archivo(const TablaSimbolos *tabla, const char *ruta)
{
    FILE *archivo;
    size_t i;
    size_t ancho_nombre = strlen("NOMBRE");
    size_t ancho_tipo = strlen("TIPODATO");
    size_t ancho_valor = strlen("VALOR");
    size_t ancho_longitud = strlen("LONGITUD");
    char texto_longitud[32];

    for (i = 0; i < tabla->cantidad; i++)
    {
        const Simbolo *simbolo = &tabla->simbolos[i];
        const char *valor = simbolo->valor == NULL ? "" : simbolo->valor;

        if (strlen(simbolo->nombre) > ancho_nombre)
        {
            ancho_nombre = strlen(simbolo->nombre);
        }
        if (strlen(nombre_tipo(simbolo)) > ancho_tipo)
        {
            ancho_tipo = strlen(nombre_tipo(simbolo));
        }
        if (strlen(valor) > ancho_valor)
        {
            ancho_valor = strlen(valor);
        }

        if (simbolo->longitud >= 0)
        {
            snprintf(texto_longitud, sizeof(texto_longitud), "%d", simbolo->longitud);
            if (strlen(texto_longitud) > ancho_longitud)
            {
                ancho_longitud = strlen(texto_longitud);
            }
        }
    }

    archivo = fopen(ruta, "wt");
    if (archivo == NULL)
    {
        fprintf(stderr, "No se pudo generar el archivo %s.\n", ruta);
        return 0;
    }

    fprintf(
        archivo,
        "%-*s | %-*s | %-*s | %-*s\n",
        (int)ancho_nombre, "NOMBRE",
        (int)ancho_tipo, "TIPODATO",
        (int)ancho_valor, "VALOR",
        (int)ancho_longitud, "LONGITUD");

    for (i = 0; i < ancho_nombre + ancho_tipo + ancho_valor + ancho_longitud + 9; i++)
    {
        fputc('-', archivo);
    }
    fputc('\n', archivo);

    for (i = 0; i < tabla->cantidad; i++)
    {
        const Simbolo *simbolo = &tabla->simbolos[i];

        texto_longitud[0] = '\0';
        if (simbolo->longitud >= 0)
        {
            snprintf(texto_longitud, sizeof(texto_longitud), "%d", simbolo->longitud);
        }

        fprintf(
            archivo,
            "%-*s | %-*s | %-*s | %-*s\n",
            (int)ancho_nombre, simbolo->nombre,
            (int)ancho_tipo, nombre_tipo(simbolo),
            (int)ancho_valor, simbolo->valor == NULL ? "" : simbolo->valor,
            (int)ancho_longitud, texto_longitud);
    }

    if (fclose(archivo) != 0)
    {
        fprintf(stderr, "No se pudo cerrar correctamente el archivo %s.\n", ruta);
        return 0;
    }

    return 1;
}
