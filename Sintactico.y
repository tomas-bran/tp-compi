// Usa Lexico_ClasePractica
//Solo expresiones sin ()
%{
#include <stdio.h>
#include <stdlib.h>
#include "y.tab.h"
int yystopparser=0;
FILE  *yyin;

  int yyerror();
  int yylex();


%}

%token CTE_INT
%token CTE_FLOAT
%token CTE_STRING
%token ID
%token OP_ASIG
%token OP_SUM
%token OP_MUL
%token OP_RES
%token OP_DIV
%token PAR_AP
%token PAR_CI

/* Declaracion de variables */
%token INIT
%token TIPO_FLOAT
%token TIPO_INT
%token TIPO_STRING
%token DOS_PUNTOS
%token COMA
%token LLAVE_AP
%token LLAVE_CI

/* Comparadores */
%token OP_IGUAL
%token OP_MENOR
%token OP_MAYOR
%token OP_MEN_IG
%token OP_MAY_IG
%token OP_DIF

/* Logicos y control */
%token AND
%token OR
%token NOT
%token IF
%token ELSE
%token WHILE
%token READ
%token WRITE

/* TE1 - matchPatterns */
%token WHEN
%token IS
%token IN
%token OP_RANGO

/* TE3 - powerSpaceship */
%token OP_POT
%token OP_SPACESHIP

%%
sentencia:  	   
	asignacion {printf(" FIN\n");} ;

asignacion: 
          ID OP_ASIG expresion {printf("    ID = Expresion es ASIGNACION\n");}
	  ;

expresion:
         termino {printf("    Termino es Expresion\n");}
	 |expresion OP_SUM termino {printf("    Expresion+Termino es Expresion\n");}
	 |expresion OP_RES termino {printf("    Expresion-Termino es Expresion\n");}
	 ;

termino: 
       factor {printf("    Factor es Termino\n");}
       |termino OP_MUL factor {printf("     Termino*Factor es Termino\n");}
       |termino OP_DIV factor {printf("     Termino/Factor es Termino\n");}
       ;

factor: 
      ID {printf("    ID es Factor \n");}
      | CTE_INT {printf("    CTE es Factor\n");}
	| PAR_AP expresion PAR_CI {printf("    Expresion entre parentesis es Factor\n");}
     	;
%%


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
       printf("Error Sintactico\n");
	 exit (1);
     }