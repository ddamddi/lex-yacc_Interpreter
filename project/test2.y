%{
	#include <stdio.h>
	#include <stdlib.h>
	void yyerror(char*);
%}

%union { int digit; char * id; char operator;};
%start program
%token ReservedWord
%token <op> Operator
%token Delimiter
%token <num> Digit
%token <id> Letter
%type <num> Integer Float
%type <op> sign relop addop multop

%%
program		: "mainprog" id ';' declarations subprogram_declarations compound_statement
	 	;
declarations	: "var" identifier_list ';' type ';' declarations
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
subprogram_declarartions	: subprogram_declarartion subprogram_declarations
			 	| epsilon
			 	;
subprogram_declarartion		: subprogram_head declarations compound_statement
			 	;
subprogram_head			: "function" id argements ':' standard_type ';'
		  		| "procedure" id arguments ';'
		  		;
arguments	: "(" parameter_list ")"
	  	| epsilon
	  	;
parameter_list	: identifier_list ':' type
	       	| identifier_list ':' type ';'
	       	;
compound_statement		: "begin" statement_list "end"

		    		;
statement_list			: statement
		 		| statement ';' statement_list
		 		;
statement	: variable "=" expression
	  	| print_statment
		| procedure_statement
		| compound_statement
		| "if" expression "then"
		| statement "else" statement
		| "while" "(" expression ")" statement
		| return expression
		| "nop"
	  	;
print_statement	: "print"
		| "print" "(" expression ")"
	       	;
variable	: id
	 	| id "[" expression "]"
	 	;
procedure_statement		: id "(" actual_parameter_expression ")"
		    		;
actual_parameter_expression	: epsilon
			    	| expression_list
			    	;
expression_list		: expression
		 	| expression "," expression_list
		  	;
expression		: simple_expression
	    		| simple_expression relop simple_expression
	     		;
simple_expression	: term
		   	| term addop simple_expression
			;
term	: factor
     	| factor multop term
     	;
factor	: Integer
       	| Float
	| variable
	| procedure_statement
	| "!" factor
	| sign factor
       	;
sign	: "+"
     	| "-"
     	;
relop	: ">"
      	| ">="
	| "<"
	| "<="
	| "=="
	| "!="
      	;
addop	: "+"
      	| "-"
      	;
multop	: "*"
       	| "/"
	;

%%

int main(void){
	yyparse();
	return 0;
}

void yyerror (char *s) {fprintf (srderr, "%s\n", s);}
