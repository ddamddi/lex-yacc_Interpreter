%{

#include "y.tab.h"

%}

Letter [a-zA-Z]
Digit [0-9]

%%

"quit"			{exit(EXIT_SUCCESS);}

"#".*\n 		{
			printf("comment\n");
			}

"mainprog" |
"var" |
"array" |
"of" | 
"function" |
"procedure" |
"begin" |
"end" |
"if" |
"then" |
"else" |
"nop" |
"while" |
"return" |
"print"	|
"int" |
"float" 		{ return ReservedWord;}

{Letter}({Letter}|{Digit})*	{yylval.str = yytext; return id;}

{Digit}+			{yylval.inum = atoi(yytext); return Integer;}

{Digit}+\.{Digit}+		{yylval.fnum = atof(yytext); return Float;}

"+" |
"-" |
"*" |
"/" |
"<" |
"<=" |
">=" |
">" |
"==" |
"!=" |
"!"			{yylval.str = yytext; return Operator;}

";" |
"." |
"," |
"=" |
"(" |
")" |
"[" |
"]" |
":"			{yylval.c = yytext[0]; return Delimiter;}

				
[ \t\n]			;
.			;



%%

int yywrap(void) { 
    return 1;
}
