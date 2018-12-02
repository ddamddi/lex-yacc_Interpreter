%{
	#include "y.tab.h"
	extern int line_number;
%}

Digit [0-9] 
Letter [a-zA-z]

%%
{Digit} 	{printf("%s is a digit\n", yytext);}
{Letter} 	{printf("%s is a letter\n", yytext);}

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
"print"				{ printf("%s is ReservedWord\n", yytext); return ReservedWord;}	

{Letter}({Letter}|{Digit})*	{ printf("%s is ID\n", yytext); return ID;}
{Digit}+			{ printf("%s IS Integer\n", yytext); return Integer;}
{Digit}+\.{Digit}+		{ printf("%s is float number\n", yytext); return Float;}


'+'	|
'-'	|
'*'	|
'/'	|
'<'	|
'>'	|
'!'	|
"<="	|
">="	|
"=="	|
"!="			{ printf("%s is operator\n", yytext); return Operator;}


";"	|
"."	|
","	|
"="	|
"("	|
")"	|
"["	|
"]"	|
":"			{ printf("%s is Delimiter\n", yytext); return Delimiter;}

"/*"			{ printf("%s is Comment\n", yytext); return Comment;}

[\n]			{line_number++;}
[ \t]			;
.			;

