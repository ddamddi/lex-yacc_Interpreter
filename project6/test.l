%{

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "y.tab.h"



%}

Letter [a-zA-Z]
Digit [0-9]

%%

"quit"		{exit(EXIT_SUCCESS);}

"#".*\n		{ yylineno++; }

"var"		{return VAR;}
"print"         {return PRINT;}
"int"		{return INT;}
"float"		{return FLOAT;}
"table"         {return SYMTAB;}
"of"		{return OF;}
"array"         {return ARRAY;}
"if"		{return IF;}
"else"		{return ELSE;}
"then"		{return THEN;}
"begin"         {return TOK_BEGIN;}
"end"		{return TOK_END;}
"while"         {return WHILE;}
"return"	{return RETURN;}
"nop"		{return NOP;}
"function"      {return FUNCTION;}
"procedure"	{return PROCEDURE;}
"mainprog"      {return MAINPROG;}

{Letter}({Letter}|{Digit})*		{yylval.s = lookup(yytext); return Identifier;}

{Digit}+				{yylval.dnum = atof(yytext);return Integer;}

{Digit}+\.{Digit}+			{yylval.dnum = atof(yytext); return Double;}

"+"         				{yylval.c = yytext[0]; return PLUS;}
"-"         				{yylval.c = yytext[0]; return MINUS;}
"*"         				{yylval.c = yytext[0]; return MULTIPLY;}
"/"          				{yylval.c = yytext[0]; return DIVIDE;}

"."         				{yylval.c = yytext[0]; return DOT;}
","         				{yylval.c = yytext[0]; return COMMA;}
"="         				{yylval.c = yytext[0]; return ASSIGN_SIGN;}
":"         				{yylval.c = yytext[0]; return DECLARE_SIGN;}
"!"         				{yylval.c = yytext[0]; return NOT;}

"<"           				{return SMALLER;}
">"           				{return GREATER;}
"<="       				{return SMALLER_EQUAL;}
">="       				{return GREATER_EQUAL;}
"=="       				{return EQUAL;}
"!="      				{return NOT_EQUAL;}


"["         				{yylval.c = yytext[0]; return L_BRACKET;}
"]"         				{yylval.c = yytext[0]; return R_BRACKET;}

"("         				{yylval.c = yytext[0]; return L_PAREN;}
")"         				{yylval.c = yytext[0]; return R_PAREN;}

";"         				{return SEMICOLON;}

[\n]      				{yylineno++;}
[ \t]      				;
.         				;

%%

int yywrap(void) {
    return 1;
}
