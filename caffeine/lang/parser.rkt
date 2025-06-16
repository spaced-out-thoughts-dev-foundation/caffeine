#lang brag
caffeine-program             ::= ws (caffeine-service-declaration)+
caffeine-service-declaration ::= caffeine-service-name ws EXPECTS-TOK ws NUMBER-TOK PERCENT-TOK PERIOD-TOK ws
caffeine-service-name        ::= WORD-TOK [ws WORD-TOK]*
ws                           ::= (WS-TOK)*