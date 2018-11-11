%{

#include <stdio.h>
#include <stdlib.h>


%}

%%

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
"print"			{printf("%s is reserved word\n", yytext);}

"hello world"		printf("goodbye\n");
"exit"			{exit(EXIT_SUCCESS);}

[a-zA-Z]		{printf("%s is Letter\n", yytext);}
[a-zA-Z][a-zA-Z0-9]*	{printf("%s is Identifier\n", yytext);}

[0-9]			{printf("%s is digit\n", yytext);}
[1-9]*[0-9]*		{printf("%s is Number\n", yytext);}
[0-9]+.[0-9]+		printf("%s is float number\n", yytext);

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
"!"			printf("%s is operator\n", yytext);


[ \t\n]			;
.			;



%%
