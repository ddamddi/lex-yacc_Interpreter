%{

	#include <stdio.h>
	#include <stdlib.h>
	#include <string.h>
	#define NHASH 10
	#define FILE_POINTER_STACK_SIZE 10
	#define FLOAT_CHAR '1'
	#define FLOAT_STR "1"
	#define INT_STR "0"

	#define MAX_NAME_LEN 20
	#define ASCII_NUM 48

	void yyerror(char*);
	struct symbol {
		char name[MAX_NAME_LEN];
		char type;
		float value;
		struct symbol* next;
	};

	//struct declare
	/* all have common initial nodetype */
	struct ast {
		int nodetype;
		struct ast *l;	
		struct ast *r;
	}
	
	struct fncall {
	};

	struct flow {
		int nodetype; 		// I or W
		struct ast *cond;	//condition
		struct ast *tl;		//branch or do
		struct ast *el;		//optional else branch
	};

	struct numval {
		int nodetype;	//type K
		float number;
	};

	struct stmref {
		int nodetype;	//type N
		struct symbol *s;
	};


	int symtabIndex = 0;
	FILE *yyin;
	extern int yylineno;
	extern char *yytext;
	extern FILE * fp;

	struct symbol symtab[NHASH];
	struct symbol* lookup(char* name);

	int flag;

	/* function declare */
   	int yylex();
   	void yyerror();
   	void symbolDeclare(char* name, char* type);
   	void assignSymbolValue(char* name, float value);
   	void symbolPrint(char* name);
   	void printArray(char* name);
   	void printSymAll();
   	float getValue(char* name);
	char * makeArrayInfo(int num);
	char * typeArray(int, char*);
	char * arrayVariable(char * identifier, float num);
%}


%union{ float fnum; int inum; char* str; char c;}

%start program
%token <fnum> Float NOT PLUS MINUS
%token <inum> Integer
%token <str> Identifier ReservedWord
%token <c> Operator DOT DECLARE_SIGN ASSIGN_SIGN MULTIPLY DIVIDE L_BRACKET R_BRACKET L_PAREN R_PAREN
%token <str> PRINT VAR INT FLOAT SYMTAB OF ARRAY IF ELSE THEN TOK_BEGIN TOK_END SEMICOLON FUNCTION NOP RETURN
%token <str> COMMA PROCEDURE GREATER SMALLER GREATER_EQUAL SMALLER_EQUAL EQUAL NOT_EQUAL
%token <str> MAINPROG
%token <fps> WHILE

%type <fnum> simple_expression term factor expression
%type <str> print_command declarations standard_type type statement statement_list compound_statement variable
%type <str> subprogram_declarations subprogram_declaration subprogram_head parameter_list identifier_list argument



%%

program		: MAINPROG Identifier SEMICOLON declarations subprogram_declarations compound_statement
		;

declarations	: VAR identifier_list DECLARE_SIGN type SEMICOLON declarations { symbolDeclare($2, $4); }
         	| epsilon {;}
         	;

identifier_list : Identifier { $$ = $1; }
            	| Identifier COMMA identifier_list {;}
            	;

type		: standard_type                  {
    			char* tmp = (char*)malloc(sizeof(char) * 5);
              		tmp[0] = '0';
                            		strcat(tmp, $1);
              				$$ = tmp;
				}


      | ARRAY L_BRACKET Integer R_BRACKET OF standard_type   {
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

standard_type: INT      { $$ = "0"; }
         | FLOAT      { $$ = "1";}
         ;

subprogram_declarations: subprogram_declaration subprogram_declarations {;}
                   | epsilon {;}
                   ;

subprogram_declaration: subprogram_head declarations compound_statement {;}
                  ;

subprogram_head: FUNCTION Identifier argument DECLARE_SIGN standard_type SEMICOLON {;}
            |PROCEDURE Identifier argument SEMICOLON {;}
            ;

argument: L_PAREN parameter_list R_PAREN {;}
      | epsilon {;}
      ;

parameter_list: identifier_list DECLARE_SIGN type { }
         | identifier_list DECLARE_SIGN type SEMICOLON parameter_list {;}
         ;

compound_statement: TOK_BEGIN statement_list TOK_END {;}
               ;

statement_list: statement {;}
            | statement SEMICOLON statement_list {;}
            ;

statement: variable ASSIGN_SIGN expression { if(flag ==0 || flag ==1)assignSymbolValue($1, $3);
                                    			if(flag ==3)assignSymbolValue($1, $3); }
         | compound_statement {;}
         | print_command {;}
         | IF expression then statement else statement {flag = 1;}
         | WHILE L_PAREN expression R_PAREN statement {;}
         | procedure_statement {;}
         | RETURN expression {;}
         | NOP {;}
         ;

then	: THEN	{	if(flag ==0){
                  flag = 2;
               }
               else
						flag =3;
         	}
		;
else	: ELSE	{	if(flag ==2){
                  flag = 3; }
               else flag =2;
            	}
   	;

print_command	:	PRINT Identifier   { symbolPrint($2); }
         		| PRINT Integer      { printf("%d\n", (int)$2);}
         		| PRINT Float      { printf("%f\n", $2);}
         		| SYMTAB      { printSymAll(); }
         		;

variable	:	Identifier { $$ = $1; }
         	| Identifier L_BRACKET expression R_BRACKET { char * temp = arrayVariable($1, $3); $$ = temp;}
         	;

procedure_statement	:	Identifier L_PAREN actual_parameter_expression R_PAREN {;}
               		;

actual_parameter_expression	:	epsilon {;}
                     			|expression_list
                     			;

expression_list					:	expression {;}
            						| expression COMMA expression_list
            						;

expression	: simple_expression	{	$$ = $1;
												if($1 ==0)
                                 		flag =0;
					}
   			|	simple_expression relop simple_expression {;}
         	;

simple_expression	:	term              { $$ = $1; }
            		| term PLUS simple_expression { $$ = $1 + $3; }
         			| term MINUS simple_expression { $$ = $1 - $3; }
         			;

term		:	factor     { $$ = $1; }
      	| factor MULTIPLY term { $$ = $1 * $3; }
      	| factor DIVIDE term { 	if($3 != 0) $$ = $1 / $3;
											else yyerror("cannot divide by 0");}
      	;

factor	: Integer      { $$ = $1; }
        | Float         { $$ = $1; }
      	| variable      { $$ = getValue($1);}
      	| procedure_statement {;}
      	| NOT factor
      	| PLUS factor
      	| MINUS factor
      	;


relop: SMALLER
   	| SMALLER_EQUAL
   	| GREATER
   	| GREATER_EQUAL
   	| EQUAL
   	| NOT_EQUAL;
   	;

epsilon: {;}
		;

%%

void yyerror(char *s) {
   printf("%d : %s %s\n", yylineno, s, yytext );
}

struct symbol* lookup(char* name) {
   int i;
   struct symbol* tmp;

   for(i=0; i < symtabIndex; i++) {
      if(strcmp(symtab[i].name, name) == 0) {
         tmp = &(symtab[i]);
         return tmp;
      }
   }
   return 0;
}


void symbolDeclare(char* name, char* type) {

   int tmp ,len;
   char * arr_len;
   int i;
   struct symbol* ptr;
	
   if(lookup(name) != 0){
	yyerror("same identifier name error\n");
	return;
   }

	strcpy(symtab[symtabIndex].name, name);
   tmp = type[1] - ASCII_NUM;
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
      for(i = 0; i < len; i++){
         ptr = ptr->next;
      }

   }
	symtabIndex++;
}


void assignSymbolValue(char* name, float value) {
	char* variable_name = (char*)malloc(sizeof(char) * MAX_NAME_LEN);
	char* ptr = strstr(name, "/");
	int i, len;
	int index;
	
	if(ptr != NULL){
		len = (int)(ptr-name) / sizeof(char);
		strncpy(variable_name, name, len);
		index = atoi(ptr+1);

	}
	else
		strcpy(variable_name, name);

	struct symbol * tmp = lookup(variable_name);
	if(tmp == 0){
		yyerror("undeclared identifier error.\n");
		return;
	}
	if(ptr != NULL) {
		for(i = 0; i < index; i++){
			tmp = tmp->next;
		}
	}

	tmp->value = value;
	printf("value: %f\n",tmp->value);
}

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
		yyerror("no reference this variable\n");

	if(ptr != NULL)
		for(i=0; i<index; i++)
			temp = temp->next;
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
		yyerror("undefined identifier error\n");

	if(ptr != NULL){
		for(i=0; i<index; i++)
			temp = temp->next;
	}
	return temp->value;
}

char * typeArray(int int_num, char * standard_type){
	char* len;
	sprintf(len, "%d", int_num);
	char * tmp = (char*)malloc(sizeof(char) * 4);
//	printf("%s\n", standard_type);
	if(strcmp(standard_type, "0") == 0){
		strncat(tmp, "10", 2);
		strcat(tmp, len);
	}
 	 else {
		strncat(tmp, "11", 2);
		strcat(tmp, len);
  	}
  return &tmp;
}


char * arrayVariable(char * identifier, float num){
	char* var = (char*)malloc(sizeof(char) * MAX_NAME_LEN);
	char* idx = (char*)malloc(sizeof(char) * MAX_NAME_LEN);
	strcpy(var, identifier);
	strcat(var, "/");

	sprintf(idx, "%d", (int)num);
	strcat(var, idx);
	return var;
}

int main(int argc, char *argv[]) {


   int i = 0;
   for(int i = 0; i < NHASH; i++) {
      symtab[i].type = ' ';
      symtab[i].value = 0;

   }
   flag = 1;

   yyin = fopen(argv[1], "r");

   if(!yyparse())
      printf("Parsing complete\n");
   else
      printf("Parsing failed\n");

   fclose(yyin);

   return 0;
}
