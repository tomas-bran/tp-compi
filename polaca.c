#include "polaca.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define CAPACIDAD_INICIAL 64

static char **celdas = NULL;
static size_t cantidad = 0;
static size_t capacidad = 0;

void polaca_inicializar(void)
{
    celdas = NULL;
    cantidad = 0;
    capacidad = 0;
}

void polaca_destruir(void)
{
    size_t i;

    for (i = 0; i < cantidad; i++)
    {
        free(celdas[i]);
    }
    free(celdas);
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