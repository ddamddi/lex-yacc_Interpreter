%{

	#include <stdio.h>
	#include <stdlib.h>
	#include <string.h>
	#include <stdarg.h>

	#define NHASH 9997
	#define FILE_POINTER_STACK_SIZE 10
	#define FLOAT_CHAR '1'
	#define FLOAT_STR "1"
	#define INT_STR "0"
	#define MAX_NAME_LEN 20
	#define ASCII_NUM 48

	/* node types
	 * + - * / |
	 * 0-7 comparison ops, bit coded 04 equal, 02 less, 01 greater
	 * M unary minus
	 * L expression or statement list
	 * I IF statement
	 * W WHILE statement
	 * N symbol ref
	 * = assignment
	 * S list of symbols
	 * F built in function call
	 * C user function call
	*/

	struct symbol {
		char * name;
		double value;
		char type;
		struct ast *func; /* stmt for the function */
		struct symlist *syms; /* list of dummy args */
	};

	//struct declare
	/* all have common initial nodetype */
	struct ast {
		int nodetype;
		struct ast *l;
		struct ast *r;
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

	struct symref {
		int nodetype;	//type N
		struct symbol *s;
	};

	struct ufncall {
		int nodetype;
		struct ast *l;
		struct symbol *s;
	};

	struct symasgn {
		int nodetype;
		struct symbol * s;
		struct ast * v;
	};


	/* list of symbols, for an argument list */
	struct symlist {
		struct symbol *sym;
	 	struct symlist *next;
	};

	int symtabIndex = 0;
	FILE *yyin;
	extern int yylineno;
	extern char *yytext;
	extern FILE * fp;

	struct symbol symtab[NHASH];
	struct symbol *lookup(char*);

	int flag;

	/* function declare */
	/* build an AST */
	struct ast *newast(int nodetype, struct ast *l, struct ast *r);
	struct ast *newcmp(int cmptype, struct ast *l, struct ast *r);
	struct ast *newfunc(int functype, struct ast *l);
	struct ast *newcall(struct symbol *s, struct ast *l);
	struct ast *newref(struct symbol *s);
	struct ast *newasgn(struct symbol *s, struct ast *v);
	struct ast *newnum(double d);
	struct ast *newflow(int nodetype, struct ast *cond, struct ast *tl, struct ast *tr);
	static unsigned symhash(char *sym);

	/* define a function */
	void dodef(struct symbol *name, struct symlist *syms, struct ast *stmts);

	/* evaluate an AST */
	double eval(struct ast *);

	/* delete and free an AST */
	void treefree(struct ast *);

	/* interface to the lexer */
	struct symlist *newsymlist(struct symbol *sym, struct symlist *next);
	void symlistfree(struct symlist *sl);
	extern int yylineno; /* from lexer */
	void yyerror(char *s, ...);

	void newDeclareIdentifier(struct symlist * s, char *type);
	void printValue(struct symbol * s);
%}

%union {
 	struct ast *a;
 	struct symbol *s; /* which symbol */
 	struct symlist *sl;
 	int fn; /* which function */
	char c;
	int inum;
	double dnum;
	char * str;
}

%start program
%token <s> Identifier
%token <c> PLUS MINUS MULTIPLY DIVIDE DOT COMMA ASSIGN_SIGN DECLARE_SIGN NOT L_BRACKET R_BRACKET L_PAREN R_PAREN
%token <str> VAR PRINT INT FLOAT SYMTAB OF ARRAY IF ELSE THEN TOK_BEGIN TOK_END WHILE RETURN NOP FUNCTION PROCEDURE MAINPROG SEMICOLON
%token <str> SMALLER GREATER SMALLER_EQUAL GREATER_EQUAL EQUAL NOT_EQUAL QUIT
%token <dnum> Double Integer

%type <s> variable
%type <sl> identifier_list
%type <a> simple_expression term factor expression expression_list
%type <str> print_command declarations standard_type type statement statement_list compound_statement
%type <str> subprogram_declarations subprogram_declaration subprogram_head parameter_list argument
%type <str> actual_parameter_expression



%%

program			: MAINPROG Identifier SEMICOLON declarations subprogram_declarations compound_statement
					;

declarations	: VAR identifier_list DECLARE_SIGN type SEMICOLON declarations {newDeclareIdentifier($2, $4);}
         		| epsilon {;}
         		;

identifier_list : Identifier { $$ = newsymlist($1, NULL); }
            	| Identifier COMMA identifier_list { $$ = newsymlist($1, $3);}
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

parameter_list		: identifier_list DECLARE_SIGN type {;}
         		| identifier_list DECLARE_SIGN type SEMICOLON parameter_list {;}
         		;

compound_statement: TOK_BEGIN statement_list TOK_END { $1 = $2;}
               ;

statement_list: statement {$$ = $1;}
            | statement SEMICOLON statement_list {$$ = newast('L', $1, $3);}
            ;

statement: variable ASSIGN_SIGN expression {printf("statmentn"); $$ = newast('=',$1,$3); eval($$); printf("statmentn314");}
         | compound_statement { $$ = $1;}
         | print_command {;}
         | IF expression THEN statement ELSE statement { $$ = newflow('I', $2, $4, $6);}
         | WHILE L_PAREN expression R_PAREN statement { $$ = newflow('W', $3, $5, NULL);}
         | procedure_statement {;}
         | RETURN expression {;}
         | NOP {;}
         ;


print_command				: PRINT Identifier   { struct symbol * temp = $2; printValue(&temp);}
         				| PRINT Integer      { printf("%d\n", (int)$2);}
         				| PRINT Double      { printf("%f\n", $2);}
         				| SYMTAB      { //printSymAll();
												}
         				;

variable				: Identifier { $$ = $1;}
         				| Identifier L_BRACKET expression R_BRACKET { //char * temp = arrayVariable($1, $3); $$ = temp;
																					}
         				;

procedure_statement			: Identifier L_PAREN actual_parameter_expression R_PAREN {;}
               				;

actual_parameter_expression		: epsilon {;}
                     			| expression_list { $$ = $1;}
                     			;

expression_list			: expression { $$ = $1;}
            			| expression COMMA expression_list { $$ = newast('L', $1, $3);}
            			;

expression			: simple_expression	{ $$ = $1;}
	   			| simple_expression relop simple_expression { }
        		 	;

simple_expression		: term              {$$ = $1;}
            			| term PLUS simple_expression { $$ = newast('+', $1, $3); }
         			| term MINUS simple_expression { $$ = newast('-', $1, $3); }
         			;

term		:	factor     { $$ = $1;}
      		| factor MULTIPLY term { $$ = newast('*', $1, $3) ; }
      		| factor DIVIDE term { 	$$ = newast('/', $1, $3) ;}
      		;

factor	: Integer      { $$ = newnum($1); }
	      | Double         { $$ = newnum($1); }
      	| variable      { $$ = newref($1);}
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

void yyerror(char *s, ...) {
	va_list ap;
	va_start(ap, s);
	fprintf(stderr, "%d: error: ", yylineno);
	vfprintf(stderr, s, ap);
	fprintf(stderr, "\n");
}

void newDeclareIdentifier(struct symlist * s, char *type){
	//type declare
	while( s->next != NULL){
			printf("2\n");
		s->sym->type = type[0];
		s = s->next;
	}
}

void printValue(struct symbol * s){
	printf("%s %f\n", s->name,s->value);
}

void assignSymbolValue(struct symbol * s, struct ast * a){
	a->nodetype = "=";
	s->func = a;
	eval(a);
}

struct symbol * lookup(char* sym){
	struct symbol *sp = &symtab[symhash(sym)%NHASH];
	int scount = NHASH; /* how many have we looked at */

	while(--scount >= 0) {
		if(sp->name && !strcmp(sp->name, sym)) { return sp; }
		if(!sp->name) { /* new entry */
			sp->name = strdup(sym);
			sp->value = 0;
			sp->func = NULL;
			sp->syms = NULL;
			return sp;
		}

		if(++sp >= symtab+NHASH) sp = symtab; /* try the next entry */

	}
 	yyerror("symbol table overflow\n");
 	abort(); /* tried them all, table is full */
}

static unsigned symhash(char *sym) {
	unsigned int hash = 0;
	unsigned c;

  	while(c = *sym++)
		hash = hash*9 ^ c;
  		return hash;
}

struct ast * newast(int nodetype, struct ast *l, struct ast *r){
	struct ast *a = malloc(sizeof(struct ast));

	if(!a) {
		yyerror("out of space");
		exit(0);
	}

	a->nodetype = nodetype;
	a->l = l;
	a->r = r;
	return a;
}

struct ast *newnum(double d){
	struct numval *a = malloc(sizeof(struct numval));
	if(!a) {
 		yyerror("out of space");
		exit(0);
 	}
 	a->nodetype = 'K';
 	a->number = d;
 	return (struct ast *)a;
}


struct ast *newcmp(int cmptype, struct ast *l, struct ast *r){
	struct ast *a = malloc(sizeof(struct ast));
	if(!a) {
		yyerror("out of space");
		exit(0);
	}
 	a->nodetype = '0' + cmptype;
 	a->l = l;
 	a->r = r;
 	return a;
}


struct ast *newcall(struct symbol *s, struct ast *l){
 	struct ufncall *a = malloc(sizeof(struct ufncall));

 	if(!a) {
 		yyerror("out of space");
 		exit(0);
 	}

 	a->nodetype = 'C';
 	a->l = l;
 	a->s = s;
 	return (struct ast *)a;
}

struct ast *newref(struct symbol *s){
	struct symref *a = malloc(sizeof(struct symref));

	if(!a) {
 		yyerror("out of space");
 		exit(0);
 	}

	a->nodetype = 'N';
 	a->s = s;
 	return (struct ast *)a;
}

struct ast *newasgn(struct symbol *s, struct ast *v)
{
 	struct symasgn *a = malloc(sizeof(struct symasgn));
 	if(!a) {
 		yyerror("out of space");
 		exit(0);
 	}
 	a->nodetype = '=';
 	a->s = s;
 	a->v = v;
 	return (struct ast *)a;
}


struct ast *newflow(int nodetype, struct ast *cond, struct ast *tl, struct ast *el){
	struct flow *a = malloc(sizeof(struct flow));

 	if(!a) {
 		yyerror("out of space");
 		exit(0);
 	}
 	a->nodetype = nodetype;
 	a->cond = cond;
 	a->tl = tl;
 	a->el = el;
 	return (struct ast *)a;
}

/* free a tree of ASTs */
void treefree(struct ast *a){

	switch(a->nodetype) {

	 	/* two subtrees */
	 	case '+':
	 	case '-':
	 	case '*':
	 	case '/':
	 	case '1': case '2': case '3': case '4': case '5': case '6':
	 	case 'L':
	 		treefree(a->r);

	 	/* one subtree */
	 	case '|':
	 	case 'M': case 'C': case 'F':
	 		treefree(a->l);

	 	/* no subtree */
	 	case 'K': case 'N':
	 		break;
	 	case '=':
	 		free( ((struct symasgn *)a)->v);
	 		break;

	 	/* up to three subtrees */
		case 'I': case 'W':
	 		free( ((struct flow *)a)->cond);
	 		if( ((struct flow *)a)->tl)
				treefree( ((struct flow *)a)->tl);
	 		if( ((struct flow *)a)->el)
				treefree( ((struct flow *)a)->el);
	 		break;
	 	default:
			printf("internal error: free bad node %c\n", a->nodetype);
 	}

 	free(a); /* always free the node itself */
}

struct symlist *newsymlist(struct symbol *sym, struct symlist *next){
 	struct symlist *sl = malloc(sizeof(struct symlist));

 	if(!sl) {
 		yyerror("out of space");
 		exit(0);
 	}
 	sl->sym = sym;
 	sl->next = next;
 	return sl;
}

/* free a list of symbols */
void symlistfree(struct symlist *sl){
 	struct symlist *nsl;
 	while(sl) {
 		nsl = sl->next;
 		free(sl);
 		sl = nsl;
 	}
}

double eval(struct ast *a){
 	float v;
 	if(!a) {
 		yyerror("internal error, null eval");
 		return 0.0;
 	}

	switch(a->nodetype) {
 		/* constant */
 		case 'K':
			v = ((struct numval *)a)->number; break;

		/* name reference */
 		case 'N':
			v = ((struct symref *)a)->s->value; break;

		/* assignment */
 		case '=':
			((struct symasgn *)a)->s->value = eval(((struct symasgn *)a)->v);
				break;

		/* expressions */
 		case '+':
			v = eval(a->l) + eval(a->r);
			break;
 		case '-':
			v = eval(a->l) - eval(a->r);
			break;
 		case '*':
			v = eval(a->l) * eval(a->r);
			break;
 		case '/':
			v = eval(a->l) / eval(a->r);
			break;
 		case '|':
			v = fabs(eval(a->l));
			break;
 		case 'M':
			v = -eval(a->l);
			break;

		/* comparisons */
 		case '1':
			v = (eval(a->l) > eval(a->r))? 1 : 0;
			break;
 		case '2':
			v = (eval(a->l) < eval(a->r))? 1 : 0;
			break;
 		case '3':
			v = (eval(a->l) != eval(a->r))? 1 : 0;
			break;
 		case '4':
			v = (eval(a->l) == eval(a->r))? 1 : 0;
			break;
 		case '5':
			v = (eval(a->l) >= eval(a->r))? 1 : 0;
			break;
 		case '6':
			v = (eval(a->l) <= eval(a->r))? 1 : 0;
			break;

		/* control flow */
 		/* null expressions allowed in the grammar, so check for them */
 		/* if/then/else */
 		case 'I':
 			if( eval( ((struct flow *)a)->cond) != 0) {
 				if( ((struct flow *)a)->tl) {
 					v = eval( ((struct flow *)a)->tl);
 				}
				else
 					v = 0.0; /* a default value */
 			}
			else {
 				if( ((struct flow *)a)->el) {
 					v = eval(((struct flow *)a)->el);
 				}
				else
 					v = 0.0; /* a default value */
 			}
 			break;

		/* while/do */
		case 'W':
 			v = 0.0; /* a default value */
			if( ((struct flow *)a)->tl) {
 				while( eval(((struct flow *)a)->cond) != 0 )
 					v = eval(((struct flow *)a)->tl);
 			}
 			break; /* value of last statement is value of while/do */

 		/* list of statements */
 		case 'L':
			eval(a->l); v = eval(a->r);
			break;
 		default:
			printf("internal error: bad node %c\n", a->nodetype);
	}
	return v;
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
