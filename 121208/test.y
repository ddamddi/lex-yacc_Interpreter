%{

	#include <stdio.h>
	#include <stdlib.h>
	#include <string.h>
	


	void yyerror(char*); 
	struct symbol {
		char* name;
		int type;
		float value;
		struct symbol* next;
	};

	
	#define NHASH 10
	int symtabIndex = 0;

	struct symbol symtab[NHASH];
	struct symbol* lookup(char* name);
	void symbolDeclare(char* name, char* type);
	void assignSymbolValue(char* name, float value);
	void symbolPrint(char* name);
	void printArray(char* name);
	void printSymAll();
	float getValue(char* name);
%}


%union{ float fnum; int inum; char* str; char c;}

%start line
%token <fnum> Float 
%token <inum> Integer
%token <str> Identifier ReservedWord
%token <c> Operator DOT DECLARE_SIGN ASSIGN_SIGN PLUS MINUS MULTIPLY DIVIDE L_BRACKET R_BRACKET
%token <str> PRINT VAR INT FLOAT SYMTAB OF ARRAY

%type <fnum> line simple_expression term factor
%type <str> assignment print_command declarations standard_type type




%%
line 		: line simple_expression 	{;}
		| simple_expression 		{;}
		| line declarations		{;}
		| declarations			{;}
		| line assignment		{;}
		| assignment			{;}
		| print_command 		{;}
		| line print_command		{;}
		;

print_command 	: PRINT Identifier	{ symbolPrint($2); }
		| PRINT Integer		{ printf("%d\n", (int)$2);}
		| PRINT Float		{ printf("%f\n", $2);}
		| SYMTAB		{ printSymAll(); }
		;

simple_expression 	: term			     { $$ = $1; }
	   		| term PLUS simple_expression { $$ = $1 + $3; }
			| term MINUS simple_expression { $$ = $1 - $3; }
			;

declarations	: VAR Identifier DECLARE_SIGN type {symbolDeclare($2, $4);}
		;

type		: standard_type						{char* tmp = (char*)malloc(sizeof(char) * 5);
									 tmp[0] = '0';
									 strcat(tmp, $1);
									 $$ = tmp;
									}


		| ARRAY L_BRACKET Integer R_BRACKET OF standard_type	{
									  char len[4];
									  char tmp[10];
									  len[0] = $3 + 48;
									  len[1] = '\0';
									  
									  if(strcmp($6, "0") == 0){
										tmp[0] = '1';
										tmp[1] = '0';
										tmp[2] = '\0';	
										strcat(tmp, len);
										$$ = tmp;
									  }
									  else {
										tmp[0] = '1';
										tmp[1] = '1';
										tmp[2] = '\0';	
										strcat(tmp, len);
										$$ = tmp;
									  }
									}
										
		;

standard_type	: INT		{ $$ = "0"; }
		| FLOAT		{ $$ = "1"; }
		;


assignment 	: Identifier ASSIGN_SIGN simple_expression { assignSymbolValue($1, $3); }
		;

term		: factor	  { $$ = $1; }
		| factor MULTIPLY term { $$ = $1 * $3; }
		| factor DIVIDE term { if($3 != 0) $$ = $1 / $3; else yyerror("cannot divide by 0");}
		;

factor	: Integer		{ $$ = $1; }
       	| Float			{ $$ = $1; }
	| Identifier		{ $$ = getValue($1);}
	;

%%

void yyerror (char *s) {fprintf (stderr, "%s\n", s);}

struct symbol* lookup(char* name) { 
	int i;
	struct symbol* tmp;

	for(i=0; i < symtabIndex; i++) {
		// printf("%d\n", i);
		// printf("%s   %s\n", symtab[i].name, name);
		if(strcmp(symtab[i].name, name) == 0) {
			tmp = &(symtab[i]);
			return tmp; 
		}
	}
	printf("cannot find identifier\n");
	return 0;
}


void symbolDeclare(char* name, char* type) {
	
	int tmp ,len;
	char * arr_len;
	int i;
	struct symbol* ptr;
	
	if(lookup(name) != 0){
		printf("same identifier name error.\n");
		return;
	}
	
	symtab[symtabIndex].name = name;
		
	tmp = type[1] - 48;
	switch(tmp){
		case 0 : symtab[symtabIndex].type = 0; printf("new integer type variable!!!\n"); symtabIndex++; break;
		case 1 : symtab[symtabIndex].type = 1; printf("new float type variable!!!\n"); symtabIndex++; break;
	}

	if(type[0] == '1') {
		
		arr_len = &type[2];
		len = atoi(arr_len);

		ptr = &(symtab[symtabIndex]);
		for(i = 0;i < len - 1; i++){
			ptr->next = (struct symbol*)malloc(sizeof(struct symbol));
			ptr = ptr->next;
			ptr->type = symtab[symtabIndex].type;
			ptr->name = symtab[symtabIndex].name;
			ptr->value = 0;
		}

		ptr = &(symtab[symtabIndex]);
		for(i = 0; i < len; i++){
			printf("%s[%d] : %f\n", name, i, ptr->value);
			ptr = ptr->next;
		} 

		printf("this is array\n");
		
	}
	
	// printSymAll();
	
}


void assignSymbolValue(char* name, float value) {
	struct symbol* tmp = lookup(name);
	if(tmp == 0){
		printf("undeclared identifier error.\n");
		return;
	}
	tmp->value = value;
	
}

void symbolPrint(char* name){
	struct symbol* temp = lookup(name);
	if(temp != 0){
		printf("%f\n",temp->value);	
	}
	else{
		printf("print error\n");
	}
}

void printArray(char* name){
	int i = 0;
	struct symbol* temp = lookup(name);
	
	while(temp->next != NULL){
		printf("%s[%d] : %f\n", name, i, temp->value);
		i++;  
	}
}

void printSymAll(){
	int i = 0;
	printf("index\tname\t  type\tvalue\t   size\n");
	for(i=0; i < NHASH; i++){
		printf("%3d : %12s %d \t%4f\n", i, symtab[i].name, symtab[i].type, symtab[i].value);
	}
	printf("\t symtabIndex : %d\n",symtabIndex);
}



float getValue(char* name){
	struct symbol* tmp = lookup(name);
	if(tmp == 0){
		fprintf(stderr,"undefined identifier error.\n");
	}
	return tmp->value;

}


int main() {
	
	
	int i = 0;
	for(int i = 0; i < NHASH; i++) {
	
		symtab[i].name = " ";
		symtab[i].type = -1;
		symtab[i].value = 0;

	}	

	return yyparse();
}
