#ifndef POLACA_H
#define POLACA_H

#include <stddef.h>

void   polaca_inicializar(void);
void   polaca_destruir(void);
size_t polaca_insertar(const char *token);   // escribe en la celda actual y avanza 
size_t polaca_actual(void);                  // nº de la próxima celda libre 
int    polaca_guardar_archivo(const char *ruta);

const char *polaca_obtener(size_t celda);                    //lee el contenido de una celda 
void        polaca_reemplazar(size_t celda, const char *token); // pisa una celda con un texto 

size_t polaca_avanzar(void);                         // reserva una celda en blanco y devuelve su nº 
void   polaca_escribir_en(size_t celda, size_t valor); // completa una celda ya reservada 
void   pila_apilar(size_t valor);
size_t pila_desapilar(void);



#endif