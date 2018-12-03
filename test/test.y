%{
	#include <stdio.h>
	#include <stdlib.h>
	#include <string.h>
	#include "test.l"
	void yyerror(char*);

	struct symbol {
		char* name;
		int type;
		int ivalue;
		float fvalue;
		struct symbol* next;	
	}

	#define NHASH 100
	int symtabIndex = 0;
	struct symbol symtab[NHASH];
	struct symbol* lookup(char* n);
	void symbolDeclare(char* id_list, char* type);
	void assignFloat(char* id, float value);
	void assignInt(char* id, int value);

%}

%union{ float fnum; int inum; char* string; char c;}

%start program

%token <string> id ReservedWord Operator
%token <inum> Integer num
%token <fnum> Float
%token <c> Delimiter
%token epsilon

%type <fnum> factor term simple_expression expression
%type <string> sign relop addop multop variable statement statement_list

%%
program		: "mainprog" id ';' declarations compound_statement
	 	;


declarations	: "var" identifier_list ':' type ';' declarations {  }
	     	| epsilon
	     	;

identifier_list	: id	
		| id "," identifier_list
		;

type		: standard_type
      		| "array" "[" num "]" "of" standard_type
      		;

standard_type	: "int"
	      	| "float"
	      	;

compound_statement		: "begin" statement_list "end"
		    		;

statement_list			: statement
		 		| statement ';' statement_list
		 		;

statement	: variable "=" expression {	struct symbol* tmp;
						if(!(tmp = lookup($1))){
							switch(tmp->type){
								case 0 : assignInt($1, $3); break; 
								case 1 : assignFloat($1, $3); break;
							}														
						}
					  }

	  	| print_statement
		| compound_statement
		| "return" expression {}
		| "nop"
	  	;

print_statement	: "print"
		| "print" "(" expression ")" { printf("%s\n", $3);}
	       	;
variable	: id { }
	 	| id "[" expression "]"  { }
		;

expression_list		: expression
		 	| expression "," expression_list
		  	;
expression		: simple_expression
	    		| simple_expression relop simple_expression	{
										if( strcmp($2, ">") )
											$$ = ($1 > $3)?1:0;
										else if(strcmp($2, ">="))
											$$ = ($1 >= $3)?1:0;
										else if( strcmp($2, "<=") )
											$$ = ($1 <= $3)?1:0;
										else if( strcmp($2, "==") )
											$$ = ($1 == $3)?1:0;
										else if( strcmp($2, "!=") )
											$$ = ($1 1= $3)?1:0;
									};
	     		
simple_expression	: term
		   	| term addop simple_expression	{ 
								if(strcmp($2 , "+") )
									$$ = $1 + $3;
								else if(strcmp($2 , "-") )
									$$ = $1 - $3;
							};
			
term	: factor
     	| factor multop term	{ 
					if(strcmp($2, "*"))
						$$ = $1 * $3;
					else if(strcmp($2, "/")){
						if($3 != 0) {
              						$$ = $1 / $3;
							break;
						}
						else yyerror("cannot divide by 0.");
					}
				};

factor	: Integer		{;}
       	| Float			{;}
	| variable		{;}
	// | procedure_statement	{}
	| "!" factor  {}
	| sign factor {;}
       	;
sign	: "+"  {;}
     	| "-"  {;}
     	;
relop	: ">"  {;}
      	| ">=" {;}
	| "<"  {;}
	| "<=" {;} 
	| "==" {;}
	| "!=" {;}
      	;
addop	: "+" {;} 
      	| "-" {;}
      	;
multop	: "*" {;}
       	| "/" {;} 
	;

%%

int main(void){
	yyparse();
	return 0;
}

void yyerror (char *s) {fprintf (stderr, "%s\n", s);}

struct symbol* lookup(char* n) { 
	int i;
	struct symbol* tmp;
	for(i=0; i < symtabIndex; i++) {
		if(strcmp(symtab[i].name, n)) {
			tmp = &(symtab[i]);
			return tmp; 
		}
	}
	printf("cannot find identifier\n");
	return 0;
}

void symbolDeclare(char* id_list, char* type) {

	if(lookup(id_list) != NULL){
		printf("same identifier name error.\n");
		return;
	}
	
	symtab[symtabIndex].name = id_list;
	if(strcmp(type, "int"))
		symtab[symtabIndex].type = 0;
	else if (strcmp(type, "float"))
		symtab[symtabIndex].type = 1;
	symtabIndex++;

}

void assignInt(char* name, int value) {
	struct symbol* temp = lookup(name);
	if(temp == NULL){
		printf("undeclared identifier error.\n");
		return;
	}
	temp->ivalue = value;

}

void assignFloat(char* name, float value) {
	struct symbol* temp = lookup(name);
	if(temp == NULL){
		printf("undeclared identifier error.\n");
		return;
	}
	temp->fvalue = value;

}




