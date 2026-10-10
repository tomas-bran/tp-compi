#include "polaca.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define CAPACIDAD_INICIAL 64
#define CAPACIDAD_PILA_INICIAL 16

static char **celdas = NULL;
static size_t cantidad = 0;
static size_t capacidad = 0;

static size_t *pila = NULL;
static size_t tope = 0;
static size_t capacidad_pila = 0;

void polaca_inicializar(void)
{
    celdas = NULL;
    cantidad = 0;
    capacidad = 0;
    pila = NULL; 
    tope = 0; 
    capacidad_pila = 0;
}

void polaca_destruir(void)
{
    size_t i;

    for (i = 0; i < cantidad; i++)
    {
        free(celdas[i]);
    }
    free(celdas);
    free(pila);
    polaca_inicializar();
}

size_t polaca_insertar(const char *token)
{
    size_t longitud = strlen(token) + 1;

    if (cantidad == capacidad)
    {
        size_t nueva = capacidad == 0 ? CAPACIDAD_INICIAL : capacidad * 2;
        char **nuevas = realloc(celdas, nueva * sizeof(char *));

        if (nuevas == NULL)
        {
            fprintf(stderr, "Error: no hay memoria para la polaca inversa.\n");
            exit(EXIT_FAILURE);
        }
        celdas = nuevas;
        capacidad = nueva;
    }

    celdas[cantidad] = malloc(longitud);
    if (celdas[cantidad] == NULL)
    {
        fprintf(stderr, "Error: no hay memoria para la polaca inversa.\n");
        exit(EXIT_FAILURE);
    }
    memcpy(celdas[cantidad], token, longitud);

    return cantidad++;
}

size_t polaca_actual(void)
{
    return cantidad;
}

int polaca_guardar_archivo(const char *ruta)
{
    FILE *archivo = fopen(ruta, "wt");
    size_t i;

    if (archivo == NULL)
    {
        fprintf(stderr, "No se pudo generar el archivo %s.\n", ruta);
        return 0;
    }

    for (i = 0; i < cantidad; i++)
    {
        fprintf(archivo, "%zu: %s\n", i, celdas[i]);
    }

    return fclose(archivo) == 0;
}

size_t polaca_avanzar(void)
{
    return polaca_insertar("");   /* celda en blanco, se completa después */
}

void polaca_escribir_en(size_t celda, size_t valor)
{
    char buffer[32];
    char *nuevo;

    if (celda >= cantidad)
    {
        fprintf(stderr, "Error interno: la celda %zu no existe en la polaca.\n", celda);
        exit(EXIT_FAILURE);
    }

    snprintf(buffer, sizeof(buffer), "%zu", valor);
    nuevo = malloc(strlen(buffer) + 1);
    if (nuevo == NULL)
    {
        fprintf(stderr, "Error: no hay memoria para la polaca inversa.\n");
        exit(EXIT_FAILURE);
    }
    strcpy(nuevo, buffer);

    free(celdas[celda]);
    celdas[celda] = nuevo;
}

const char *polaca_obtener(size_t celda)
{
    if (celda >= cantidad)
    {
        fprintf(stderr, "Error interno: la celda %zu no existe en la polaca.\n", celda);
        exit(EXIT_FAILURE);
    }
    return celdas[celda];
}

void polaca_reemplazar(size_t celda, const char *token)
{
    size_t longitud = strlen(token) + 1;
    char *nuevo;

    if (celda >= cantidad)
    {
        fprintf(stderr, "Error interno: la celda %zu no existe en la polaca.\n", celda);
        exit(EXIT_FAILURE);
    }

    nuevo = malloc(longitud);
    if (nuevo == NULL)
    {
        fprintf(stderr, "Error: no hay memoria para la polaca inversa.\n");
        exit(EXIT_FAILURE);
    }
    memcpy(nuevo, token, longitud);

    free(celdas[celda]);
    celdas[celda] = nuevo;
}

void pila_apilar(size_t valor)
{
    if (tope == capacidad_pila)
    {
        size_t nueva = capacidad_pila == 0 ? CAPACIDAD_PILA_INICIAL : capacidad_pila * 2;
        size_t *nuevas = realloc(pila, nueva * sizeof(size_t));

        if (nuevas == NULL)
        {
            fprintf(stderr, "Error: no hay memoria para la pila de saltos.\n");
            exit(EXIT_FAILURE);
        }
        pila = nuevas;
        capacidad_pila = nueva;
    }
    pila[tope++] = valor;
}

size_t pila_desapilar(void)
{
    if (tope == 0)
    {
        fprintf(stderr, "Error interno: se intentó desapilar con la pila de saltos vacía.\n");
        exit(EXIT_FAILURE);
    }
    return pila[--tope];
}