%{

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include "y.tab.h"

%}

Letter [a-zA-Z]
Digit [0-9]

%%

"quit"		{exit(EXIT_SUCCESS);}

"#".*\n		{ yylineno++; }

"var"		{return VAR;}
"print"         {yylval.c = 'P'; return PRINT;}
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

{Letter}({Letter}|{Digit})*		{lookup(yytext); yylval.str = strdup(yytext);return Identifier;}

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


">"           				{yylval.fn = 1; return GREATER;}
"<"           				{yylval.fn = 2; return SMALLER;}
"!="                    {yylval.fn = 3; return NOT_EQUAL;}
"=="                    {yylval.fn = 4; return EQUAL;}
">="                    {yylval.fn = 5; return GREATER_EQUAL;}
"<="       				   {yylval.fn = 6;return SMALLER_EQUAL;}


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
