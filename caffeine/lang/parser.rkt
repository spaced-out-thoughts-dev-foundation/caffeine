#lang brag

;; top level
caffeine-program             ::= caffeine-ws (caffeine-service-declaration)+

;; higher level constructs
caffeine-service-declaration ::= caffeine-service-name caffeine-ws caffeine-expectation caffeine-ws caffeine-and caffeine-service-dependency caffeine-decleration-end

;; medium level constructs
caffeine-service-dependency  ::= single-dependency | no-dependency
single-dependency            ::= caffeine-ws DEPENDS-TOK caffeine-ws ON-TOK caffeine-ws caffeine-service-name caffeine-ws
no-dependency                ::= caffeine-ws HAS-TOK caffeine-ws NO-TOK caffeine-ws DEPENDENCIES-TOK caffeine-ws

;; building blocks
caffeine-expectation         ::= EXPECTS-TOK caffeine-ws caffeine-threshold 
caffeine-threshold           ::= NUMBER-TOK PERCENT-TOK
caffeine-service-name        ::= WORD-TOK [caffeine-ws WORD-TOK]*

;; basics
caffeine-ws                  ::= (WS-TOK)*
caffeine-decleration-end    ::= PERIOD-TOK caffeine-ws
caffeine-and                 ::= AND-TOK caffeine-ws
