%{

#include <string>
#include "parse.tab.h"

#define YY_DECL extern "C" int yylexx()

}%

%%
"halt"|"quit"|"end" {return END}
"consider "         {return CONSIDER}
[,;.?(<{)>}]        {return yytext[0]}
":="                {return DEFINE}
":-"                {return TURNSTILE}
"->"                {return IMPLIES}
"-<"                {return COIMPLIES}
"forall"            {return FORALL}
"exists"            {return EXISTS}
"induce"            {return INDUCE}
"iterate"           {return ITERATE}
[A-Za-z0-9_]+       {yylval.atom = new std::string(yytext); return ATOM}
[ \t\n] ;
%%
