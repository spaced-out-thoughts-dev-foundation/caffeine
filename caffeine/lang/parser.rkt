#lang brag
caffeine-program             ::= ws (caffeine-service-declaration)+
caffeine-service-declaration ::= WORD-TOK ws EXPECTS-TOK ws NUMBER-TOK PERCENT-TOK PERIOD-TOK ws
ws                           ::= (WS-TOK)*