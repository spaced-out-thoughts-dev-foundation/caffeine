#lang brag

;; top level
caffeine-program             ::= caffeine-ws (caffeine-service-declaration)+

;; higher level constructs
caffeine-service-declaration ::= caffeine-service-name caffeine-ws caffeine-expectation PERIOD-TOK caffeine-ws

;; building blocks
caffeine-expectation         ::= EXPECTS-TOK caffeine-ws caffeine-threshold 
caffeine-threshold           ::= NUMBER-TOK PERCENT-TOK
caffeine-service-name        ::= WORD-TOK [caffeine-ws WORD-TOK]*

;; basics
caffeine-ws                  ::= (WS-TOK)*
