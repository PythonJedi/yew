# Makefile for the C++ bootstrap of Yew

source = $(wildcard *.cpp) $(wildcard *.c)
header = $(wildcard *.hpp) $(wildcard *.h)

parse.tab.c parse.tab.h: parse.y
	bison -o parse.tab.c -defines=parse.tab.h parse.y

lex.yy.c: lex.l parse.tab.h
	flex -o $^ lex.l

yew: $(source) $(header)
	g++ $(source) -lfl -o $^
