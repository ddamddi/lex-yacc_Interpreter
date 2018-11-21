%{
	// #include "y.tab.h"
	enum{ReservedWord, ID, Integer, Float, Operator, Delimiter, Comment};
%}

Digit [0-9] 
Letter [a-zA-z]

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

[ \t\n]			;
.			;

%%

int main()
{

	int running = 1;
	//yyin = fopen("test.txt", "r");
	while(running){
		yylex();
	
	}	
	return 0;
}

