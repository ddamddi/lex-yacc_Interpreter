%{

	#include <stdio.h>
	#include <stdlib.h>
	#include <string.h>
	


	void yyerror(char*); 
	struct symbol {
		char name[20];
		char type;
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
	char* makeArrayInfo(int num);
	
	extern FILE * fp;
	FILE* yyin;

%}


%union{ float fnum; int inum; char* str; char c;}

%start line
%token <fnum> Float 
%token <inum> Integer
%token <str> Identifier ReservedWord
%token <c> Operator DOT DECLARE_SIGN ASSIGN_SIGN PLUS MINUS MULTIPLY DIVIDE L_BRACKET R_BRACKET
%token <str> PRINT VAR INT FLOAT SYMTAB OF ARRAY

%type <fnum> line simple_expression term factor
%type <fnum> expression
%type <str> statement print_command declarations standard_type type variable




%%
line 		: expression line	 	{;}
		| expression 			{;}
		| declarations line 		{;}
		| declarations			{;}
		| statement line 		{;}
		| statement			{;}
		| print_command line 		{;}
		| print_command			{;}
		;

print_command 	: PRINT variable	{ symbolPrint($2); }
		| PRINT Integer		{ printf("%d\n", (int)$2);}
		| PRINT Float		{ printf("%f\n", $2);}
		| SYMTAB		{ printSymAll(); }
		;


declarations	: VAR variable DECLARE_SIGN type { symbolDeclare($2, $4); }
		;

statement 	: variable ASSIGN_SIGN expression { assignSymbolValue($1, $3); }
		;


variable	: Identifier { $$ = $1;}
		| Identifier L_BRACKET expression R_BRACKET	{char* var = (char*)malloc(sizeof(char) * 20);
								 char* idx = (char*)malloc(sizeof(char) * 20);
								 strcpy(var, $1);
								 strcat(var, "/");
								 printf("the expression is %d\n", (int)$3);
								 sprintf(idx, "%d", (int)$3);
								 printf("the idx is %s\n", idx);
					 			 strcat(var, idx);
								 $$ = var;
								 printf("%s\n", $$);	 
								}
		;

expression		: simple_expression { $$ = $1;}
			;


simple_expression 	: term			     { $$ = $1; }
	   		| term PLUS simple_expression { $$ = $1 + $3; }
			| term MINUS simple_expression { $$ = $1 - $3; }
			;



type		: standard_type						{char* tmp = (char*)malloc(sizeof(char) * 5);
									 tmp[0] = '0';
									 strcat(tmp, $1);
									 $$ = tmp;
									}


		| ARRAY L_BRACKET Integer R_BRACKET OF standard_type	{
									  char* len[10];
									  sprintf(len, "%d", $3);
									  char tmp[15];
									  
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



term		: factor	  { $$ = $1; }
		| factor MULTIPLY term { $$ = $1 * $3; }
		| factor DIVIDE term { if($3 != 0) $$ = $1 / $3; else yyerror("cannot divide by 0");}
		;

factor	: Integer		{ $$ = $1; }
       	| Float			{ $$ = $1; }
	| variable		{ $$ = getValue($1);}
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
	// printf("cannot find identifier\n");
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
	
	strcpy(symtab[symtabIndex].name, name);		
	tmp = type[1] - 48;

	switch(tmp){
		case 0 : symtab[symtabIndex].type = 'I'; break;
		case 1 : symtab[symtabIndex].type = 'F'; break;
	}

	if(type[0] == '1') {
		
		arr_len = &type[2];
		len = atoi(arr_len);

		ptr = &(symtab[symtabIndex]);
		for(i = 0;i < len - 1; i++){
			ptr->next = (struct symbol*)malloc(sizeof(struct symbol));
			ptr = ptr->next;
			ptr->type = symtab[symtabIndex].type;
			strcpy(ptr->name, symtab[symtabIndex].name);
			ptr->value = 0;
		}

		ptr = &(symtab[symtabIndex]);
		// printf("thisproblem>??\n");
		for(i = 0; i < len; i++){
			printf("%s[%d] : %f\n", ptr->name, i, ptr->value);
			ptr = ptr->next;
		}
		printf("this is array\n");
		
	}

	symtabIndex++;
}


void assignSymbolValue(char* name, float value) {
	
	char* variable_name = (char*)malloc(sizeof(char) * 20);
	char* ptr = strstr(name, "/");
	char* arr_len;
	int i, idx = -1;
	struct symbol* tmp;

	printf("parameter \"name\" : %s\n", name);
	
	
	// printf("%p\n", ptr);
	// printf("%p\n", (int)((ptr - name) / sizeof(char)));
	

	if(ptr != 0){
		arr_len = ptr + 1;

		//memcpy(variable_name, name, (int)(ptr - name) / sizeof(char));
		//variable_name[(int)(ptr - name) / sizeof(char)] = '\0';
		strncpy(variable_name, name, (int)(ptr - name) / sizeof(char));
		printf("variable name : %s\n", variable_name);
		idx = atoi(arr_len);
		printf("index Number : %d\n", idx);
				
	}
	else strcpy(variable_name, name);
	
	// printf("variable_name is %s\n", variable_name);
	
	tmp = lookup(variable_name);
	if(tmp == 0){
		printf("undeclared identifier error.\n");
		return;
	}

	// printf("????????\n");
	if(idx != -1) {
		for(i = 0; i < idx; i++)
			tmp = tmp->next;
	}
	
	// printf("!!!!!!\n");
	tmp->value = value;
	
}



/*void symbolPrint(char* name){
	struct symbol* temp = lookup(name);
	if(temp != 0){
		printf("%f\n",temp->value);	
	}
	else{
		printf("print error\n");
	}
}*/


void symbolPrint(char* name){
   char * variable_name;
   char * ptr = strstr(name, "/");
   int len, i;
   int index;
   variable_name = (char*) malloc(sizeof(char) * 20);

   if(ptr != NULL){
      len = (int)(ptr-name) / sizeof(char);
      strncpy(variable_name, name, len);
      index = atoi(ptr+1);
   }
   else
      strcpy(variable_name, name);

   struct symbol* temp = lookup(variable_name);
   
   if(temp == 0)
      printf("print error\n");

   if(ptr != NULL){
      for(i=0; i<index; i++){
         temp = temp->next;
      }
      printf("%f\n", temp->value);
   }
   else
      printf("%f\n", temp->value);   

}	


void printArray(char* name){
	int i = 0;
	struct symbol* temp = lookup(name);
	
	while(temp->next != NULL){
		printf("%s[%d] : %f\n", name, i, temp->value);
		i++;  
	}
}

int calculateSize(char* name){
	int len = 0;
	struct symbol* temp = lookup(name);
	while(temp != 0){
		len++;
		temp = &(temp->next);
	}
	return len * 4;
}

void printSymAll(){
	int i = 0;
	printf("index\tname\t  type\tvalue\n");
	for(i=0; i < NHASH; i++){
		printf("%3d : %-12s %c \t%4f\n", i, symtab[i].name, symtab[i].type, symtab[i].value);
	}
	printf("\t symtabIndex : %d\n",symtabIndex);
}



float getValue(char* name){
	char * variable_name;
	char * ptr = strstr(name, "/");
	int len, i;
   	int index;
   	
	variable_name = (char*) malloc(sizeof(char) * 20);

   	if(ptr != NULL){
      		len = (int)(ptr-name) / sizeof(char);
		strncpy(variable_name, name, len);
		index = atoi(ptr+1);
	}
	else
		strcpy(variable_name, name);
	
	struct symbol* temp = lookup(variable_name);
	
	if(temp == 0)
		printf("print error\n");
	
	if(ptr != NULL){
		for(i=0; i<index; i++)
			temp = temp->next;
	}
	return temp->value;
	
}


int main(int argc, char* argv[]) {

	int i = 0;

	for(int i = 0; i < NHASH; i++) {
		symtab[i].type = ' ';
		symtab[i].value = 0;	
	}	

	if(argc == 1)		
		return yyparse();
	
	else if(argc == 2){
		yyin = fopen(argv[1], "r");

		if(!yyparse())
			printf("Parsing Complete\n");
		else
			printf("file open fail\n");

		fclose(yyin);
		return 0;
	}
}
