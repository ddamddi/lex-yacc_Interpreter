CC = gcc
LEX = lex
YACC = yacc
TARGET = compiler
OBJECT = lex.yy.c y.tab.c

$(TARGET) : lex.yy.c y.tab.c
	$(CC) -o $(TARGET) $(OBJECT)

lex.yy.c : test.l
	$(LEX) test.l
y.tab.c : test.y
	$(YACC) -d test.y
clean :
	rm $(OBJECT) y.tab.h $(TARGET)

