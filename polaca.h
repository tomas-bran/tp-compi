#ifndef POLACA_H
#define POLACA_H

#include <stddef.h>

void   polaca_inicializar(void);
void   polaca_destruir(void);
size_t polaca_insertar(const char *token);   /* escribe en la celda actual y avanza */
size_t polaca_actual(void);                  /* nº de la próxima celda libre */
int    polaca_guardar_archivo(const char *ruta);

#endif