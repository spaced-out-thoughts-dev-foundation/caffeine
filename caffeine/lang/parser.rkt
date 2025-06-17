#lang brag

;; top level
caffeine-program             ::= caffeine-ws (caffeine-service-declaration)+

;; higher level constructs
caffeine-service-declaration ::= caffeine-service-name caffeine-ws caffeine-expectation caffeine-ws caffeine-and caffeine-service-dependency caffeine-decleration-end

;; medium level constructs
caffeine-service-dependency  ::= multiple-dependencies | single-dependency | no-dependencies
single-dependency            ::= caffeine-ws DEPENDS-TOK caffeine-ws ON-TOK caffeine-ws caffeine-service-name caffeine-ws
multiple-dependencies        ::= caffeine-ws DEPENDS-TOK caffeine-ws ON-TOK caffeine-ws caffeine-service-name dependency-list
dependency-list              ::= (caffeine-ws dependency-list-item)+
dependency-list-item         ::= AND-TOK caffeine-ws caffeine-service-name
no-dependencies              ::= caffeine-ws HAS-TOK caffeine-ws NO-TOK caffeine-ws DEPENDENCIES-TOK caffeine-ws

;; building blocks
caffeine-expectation         ::= EXPECTS-TOK caffeine-ws caffeine-threshold 
caffeine-threshold           ::= NUMBER-TOK PERCENT-TOK
caffeine-service-name        ::= WORD-TOK [caffeine-ws WORD-TOK]*

;; basics
caffeine-ws                  ::= (WS-TOK)*
caffeine-decleration-end    ::= PERIOD-TOK caffeine-ws
caffeine-and                 ::= AND-TOK caffeine-ws
