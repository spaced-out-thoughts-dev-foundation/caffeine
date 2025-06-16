#lang brag
caffeine-program : ws caffeine-word ws caffeine-expect ws caffeine-word ws
caffeine-expect  ::= EXPECTS-TOK
caffeine-word    ::= (caffeine-char)+
caffeine-char    ::= CHAR-TOK
ws               ::= (WS-TOK)*
