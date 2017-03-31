%{
#include <iostream>
#include <string>
#include "ast.hpp"

extern "C" int yylex();
extern "C" int yyparse();
extern "C" FILE* yyin;

void yyerror(const char* s);
%}

%union {
    std::string* atom;
}

%token CONSIDER
%token END
%token TURNSTILE
%right IMPLIES
%left  COIMPLIES
%token FORALL
%token EXISTS
%token INDUCE
%token ITERATE
%token DEFINE
%token <atom> ATOM

%%

session:
    sentences END '.';

sentences:
      sentence {}
    | sentences sentence {};

sentence:
      clause '?' {}
    | CONSIDER ATOM '.' {}
    | atoms DEFINE proposition '.' {};

clause:
      TURNSTILE proposition {}
    | proposition TURNSTILE proposition {};

proposition: disjunction {};

disjunction:
      conjunction {}
    | disjunction ';' conjunction {};

conjunction:
      coimplication {}
    | conjunction ',' implication {};

// Right recursive because implication is right associative
implication:
      specialization {}
    | specialization IMPLIES implication {};

coimplication:
      implication {}
    | coimplication COIMPLIES implication {};

quantification:
      ATOM {}
    | '(' proposition ')' {}
    | FORALL '(' proposition ')' '{' proposition '}' {}
    | EXISTS '(' proposition ')' '{' proposition '}' {}
    | INDUCE '(' atoms ')' '{' proposition '}' {}
    | ITERATE '(' atoms ')' '{' proposition '}' {};

specialization:
      quantification '<' proposition '>' {}
    | quantification {};

atoms:
      ATOM {}
    | atoms ',' ATOM {};
