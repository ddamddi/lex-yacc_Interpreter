LEX = lex
YACC = yacc
TARGET = compiler
OBJECT = lex.yy.c y.tab.c y.tab.h

$(TARGET) : lex.yy.c y.tab.c y.tab.h
	$(CC) -o $(TARGET) $(OBJECT)

lex.yy.c : test.l
	$(LEX) test.l
y.tab.c y.tab.h: test.y
	$(YACC) -d test.y
clean :
	rm $(OBJECT) $(TARGET)
