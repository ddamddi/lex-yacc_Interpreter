CC = gcc
LEX = lex
YACC = yacc
TARGET = compiler
OBJECT = lex.yy.c y.tab.c

$(TARGET) : lex.yy.c y.tab.c
        $(CC) -o $(TARGET) $(OBJECT)

lex.yy.c : calc.l
        $(LEX) calc.l
y.tab.c : calc.y
        $(YACC) -d calc.y
clean :
        rm $(OBJECT) y.tab.h $(TARGET)