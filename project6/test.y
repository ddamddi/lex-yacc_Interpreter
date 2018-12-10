%{

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>

struct symbol {
   char * name;
   double value;
   char type;
   struct ast *func; /* stmt for the function */
   struct symlist *syms; /* list of dummy args */
};
	#define NHASH 10
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
   struct symbol *dodef(struct symbol *name, struct symlist *syms, struct ast *stmts);

	/* evaluate an AST */
	double eval(struct ast *);

	/* delete and free an AST */
	void treefree(struct ast *);

	/* interface to the lexer */
	struct symlist *newsymlist(struct symbol *sym, struct symlist *next);
	void symlistfree(struct symlist *sl);
	extern int yylineno; /* from lexer */
	void yyerror(char *s, ...);

	struct symlist* newDeclareIdentifier(struct symlist * s, char *type);
   static double calluser(struct ufncall *f);
	void printValue(char* temp);
	void printTab();
%}

%union {
 	struct ast *a;
 	struct symbol *s; /* which symbol */
 	struct symlist *sl;
 	int fn; /* which function */
	char c;
	double dnum;
	char * str;
}

%start program
%token <str> Identifier
%token <c> PLUS MINUS MULTIPLY DIVIDE DOT COMMA ASSIGN_SIGN DECLARE_SIGN NOT L_BRACKET R_BRACKET L_PAREN R_PAREN PRINT
%token <str> VAR INT FLOAT SYMTAB OF ARRAY IF ELSE THEN TOK_BEGIN TOK_END WHILE RETURN NOP FUNCTION PROCEDURE MAINPROG SEMICOLON
%token <fn> SMALLER GREATER SMALLER_EQUAL GREATER_EQUAL EQUAL NOT_EQUAL
%token <dnum> Double Integer

%type <s> variable subprogram_head
%type <fn> relop
%type <sl> identifier_list argument parameter_list
%type <a> simple_expression term factor expression expression_list compound_statement statement statement_list print_command procedure_statement
%type <a> actual_parameter_expression
%type <str> declarations standard_type type
%type <str> subprogram_declarations subprogram_declaration



%%

program			: MAINPROG Identifier SEMICOLON declarations subprogram_declarations compound_statement { eval($6); printTab();}
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

subprogram_declaration: subprogram_head declarations compound_statement {$1->func = $3; printf("%s",$1->name);$1->value =0;}
                  ;

subprogram_head: FUNCTION Identifier argument DECLARE_SIGN standard_type SEMICOLON {   struct symbol * temp = (struct symbol*)malloc(sizeof(struct symbol)); temp = lookup($2);
                                                                                       $$ = dodef(temp, $3, NULL);
                                                                                    }
            |PROCEDURE Identifier argument SEMICOLON {;}
            ;

argument: L_PAREN parameter_list R_PAREN {$$ =$2;}
      | epsilon {;}
      ;

parameter_list		: identifier_list DECLARE_SIGN type {$$ = $1;}
         		| identifier_list DECLARE_SIGN type SEMICOLON parameter_list {
                                                                              struct symlist * temp = (struct symlist*)malloc(sizeof(struct symlist));
                                                                              temp = $1;
                                                                              while(temp->next)
                                                                              {
                                                                                 temp = temp->next;
                                                                              }
                                                                              temp->next = $5;
                                                                              $$ = $1;
                                                                        }

         		;
compound_statement: TOK_BEGIN statement_list TOK_END { $$ = $2; }
                  ;

statement_list: statement {$$ = newast('L',$1,NULL);}
            | statement SEMICOLON statement_list {$$ = newast('L', $1, $3);}
            ;

statement: variable ASSIGN_SIGN expression {$$ = newast('=',$1,$3);}
         | compound_statement {$$ = $1; }
         | print_command { $$ = $1;}
         | IF expression THEN statement ELSE statement { $$ = newflow('I', $2, $4, $6);}
         | WHILE L_PAREN expression R_PAREN statement {$$ = newflow('W', $3, $5, NULL); }
         | procedure_statement {$$ =$1;}
         | RETURN expression {;}
         | NOP {;}
         ;



print_command			: PRINT L_PAREN expression R_PAREN  { $$ = newast('P', $3, NULL);}
         				;

variable				: Identifier { char* temp = (char*)malloc(sizeof(char)*20);
											strcpy(temp,$1);
											struct symbol* temp_sym= (struct symbol*)malloc(sizeof(struct symbol)*1);
											temp_sym = lookup(temp);
											$$ = temp_sym; }
         				| Identifier L_BRACKET expression R_BRACKET { //char * temp = arrayVariable($1, $3); $$ = temp;
																					}
         				;

procedure_statement			: Identifier L_PAREN actual_parameter_expression R_PAREN {struct symbol * func = (struct symbol*)malloc(sizeof(struct symbol));
                                                                                       func = lookup($1);
                                                                                       $$ = newcall(func,$3);}
               				;

actual_parameter_expression		: epsilon {;}
                     			| expression_list {$$ = $1;}
                     			;

expression_list			: expression { $$ = newast('L',$1,NULL);}
            			| expression COMMA expression_list { $$ = newast('L', $1, $3);}
            			;

expression			: simple_expression	{ $$ = $1;}
	   			| simple_expression relop simple_expression {  $$ = newcmp($2, $1, $3);}
        		 	;

simple_expression		: term              {$$ = $1;}
            			| term PLUS simple_expression { $$ = newast('+', $1, $3);}
         			| term MINUS simple_expression { $$ = newast('-', $1, $3);}
         			;

term		   : factor     { $$ = $1;}
      		| factor MULTIPLY term { $$ = newast('*', $1, $3) ; }
      		| factor DIVIDE term { 	$$ = newast('/', $1, $3) ;}
      		;

factor	: Integer      { $$ = newnum($1);}
	      | Double         { $$ = newnum($1);}
      	| variable      { $$ = newref($1);}
      	| procedure_statement {;}
      	| NOT factor {;}
      	| PLUS factor {;}
      	| MINUS factor {;}
      	;


relop    : SMALLER {$$ = $1;}
         | SMALLER_EQUAL {$$ = $1;}
   	   | GREATER {$$ = $1;}
   	   | GREATER_EQUAL {$$ = $1;}
         | EQUAL {$$ = $1;}
         | NOT_EQUAL {$$ = $1;}
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

struct symlist* newDeclareIdentifier(struct symlist * s, char *type){
	//type declare
   struct symlist* temp = (struct symlist*)malloc(sizeof(struct symlist));
	while( s->next != NULL){
		s->sym->type = type[0];
		s = s->next;
	}
   temp =s;
   return temp;
}

void printValue(char* temp){
	struct symbol * temp_sym = (struct symbol*)malloc(sizeof(struct symbol) * 1);
	temp_sym = lookup(temp);
	printf("%s : %f\n",temp_sym->name, temp_sym->value);
}

void assignSymbolValue(struct symbol * s, struct ast * a){
	a->nodetype = "=";
	s->func = a;
	eval(a);
}

struct symbol * lookup(char* sym){
	struct symbol *sp = &symtab[symhash(sym)%NHASH];
	struct symbol *temp = (struct symbol*)malloc(sizeof(struct symbol)*1);
	int scount = NHASH; /* how many have we looked at */

	while(--scount >= 0) {
		if(sp->name && !strcmp(sp->name, sym)) { return sp; }
		if(!sp->name) { /* new entry */
			sp->name = strdup(sym);
			sp->value = -1;
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
			break;
 		case 'M':
			v = -eval(a->l);
			break;

		/* comparisons */
 		case '1':
         printf("he\n");
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

      //print
      case 'P':
         printf("%f\n", eval(a->l));
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
         printf("in while\n");
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
      case 'C':
         v = calluser((struct ufncall *)a);
         break;
 		default:
			printf("internal error: bad node %c\n", a->nodetype);
	}
	return v;
}

static double calluser(struct ufncall *f)
{
   struct symbol *fn = f->s; /* function name */
   struct symlist *sl; /* dummy arguments */
   struct ast *args = f->l; /* actual arguments */
   double *oldval, *newval; /* saved arg values */
   double v;
   int nargs;
   int i;

   if(!fn->func) {
      yyerror("call to undefined function", fn->name);
      return 0;
   }

   /* count the arguments */
   sl = fn->syms;
   for(nargs = 0; sl; sl = sl->next)
      nargs++;

   /* define a function */
   /* prepare to save them */
   oldval = (double *)malloc(nargs * sizeof(double));
   newval = (double *)malloc(nargs * sizeof(double));

   if(!oldval || !newval) {
         yyerror("Out of space in %s", fn->name); return 0.0;
   }

   /* evaluate the arguments */
   for(i = 0; i < nargs; i++) {
      if(!args) {
         yyerror("too few args in call to %s", fn->name);
         free(oldval); free(newval);
         return 0.0;
      }
      if(args->nodetype == 'L') { /* if this is a list node */
         newval[i] = eval(args->l);
         args = args->r;
      }
      else { /* if it's the end of the list */
         newval[i] = eval(args);
         args = NULL;
      }
   }

   /* save old values of dummies, assign new ones */
   sl = fn->syms;
   for(i = 0; i < nargs; i++) {
      struct symbol *s = sl->sym;
      oldval[i] = s->value;
      s->value = newval[i];
      sl = sl->next;
   }
   free(newval);

   /* evaluate the function */
   v = eval(fn->func);

   /* put the real values of the dummies back */
   sl = fn->syms;
   for(i = 0; i < nargs; i++) {
      struct symbol *s = sl->sym;
      s->value = oldval[i];
      sl = sl->next;
   }
   free(oldval);
   return v;
}

struct symbol * dodef(struct symbol * name, struct symlist * syms, struct ast * func){
   struct symbol * temp = (struct symbol*)malloc(sizeof(struct symbol));
   if(name->syms)
      symlistfree(name->syms);
   if(name->func)
      treefree(name->func);

   name->syms = syms;
   name->func = func;
   temp = name;
   return temp;
}

void printTab(){
	int i;
	for(int i =0; i<NHASH;i++)
	{
		printf("name : %s value : %f\n",symtab[i].name,symtab[i].value);
	}
}
int main(int argc, char *argv[]) {


   int i = 0;
   for(int i = 0; i < NHASH; i++) {
      symtab[i].type = ' ';
      symtab[i].value = 0;

   }

   yyin = fopen(argv[1], "r");

   if(!yyparse())
      printf("Parsing complete\n");
   else
      printf("Parsing failed\n");

   fclose(yyin);

   return 0;
}
