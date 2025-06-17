#lang brag

;; top level
caffeine-program             ::= (caffeine-service-declaration)+

;; higher level constructs
caffeine-service-declaration ::= caffeine-service-name caffeine-expectation caffeine-and caffeine-service-dependency caffeine-decleration-end

;; medium level constructs
caffeine-service-dependency  ::= dependencies | no-dependencies
dependencies                 ::= DEPENDS-TOK ON-TOK caffeine-service-name [dependency-list]*
dependency-list              ::= (dependency-list-item)+
dependency-list-item         ::= AND-TOK caffeine-service-name
no-dependencies              ::= HAS-TOK NO-TOK DEPENDENCIES-TOK

;; building blocks
caffeine-expectation         ::= EXPECTS-TOK caffeine-threshold 
caffeine-threshold           ::= NUMBER-TOK PERCENT-TOK
caffeine-service-name        ::= WORD-TOK [WORD-TOK]*

;; basics
caffeine-decleration-end     ::= PERIOD-TOK
caffeine-and                 ::= AND-TOK
