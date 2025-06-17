;; The expander deter­mines how the code produced by the reader cor­re­sponds to real Racket expres­sions,
;; which are then eval­u­ated to pro­duce a result. The expander works by adding bind­ings to iden­ti­fiers
;; in the code.
#lang br/quicklang
(require json)

(define-macro (caffeine-mb PARSE-TREE)
  #'(#%module-begin
     (provide parsed-data)
     (define parsed-data PARSE-TREE)))
(provide (rename-out [caffeine-mb #%module-begin]))

;; ===== top level =====
;; caffeine-program
(define-macro (caffeine-program . SERVICE-DECLARATIONS)
  #'(list 'caffeine-program . SERVICE-DECLARATIONS))
(provide caffeine-program)
;; =================================================

;; ===== higher level constructs =====
;; caffeine-service-declaration
(define-macro (caffeine-service-declaration SERVICE-NAME EXPECTATION AND-TOK DEPENDENCY DECLERATION-END)
  #'(list 'service SERVICE-NAME EXPECTATION DEPENDENCY))
(provide caffeine-service-declaration)
;; =================================================

;; ===== medium level constructs =====
;; caffeine-service-dependency
(define-macro (caffeine-service-dependency DEPENDENCY)
  #'DEPENDENCY)
(provide caffeine-service-dependency)

;; dependencies
(define-macro (dependencies DEPENDS-TOK ON-TOK SERVICE-NAME . DEPENDENCY-LIST)
  #'(cons SERVICE-NAME (apply append (filter list? (list . DEPENDENCY-LIST)))))
(provide dependencies)

;; no-dependencies
(define-macro (no-dependencies HAS-TOK NO-TOK DEPENDENCIES-TOK)
  #''())
(provide no-dependencies)

;; dependency-list
(define-macro (dependency-list . DEPENDENCY-LIST-ITEMS)
  #'(list . DEPENDENCY-LIST-ITEMS))
(provide dependency-list)

;; dependency-list-item
(define-macro (dependency-list-item AND-TOK SERVICE-NAME)
  #'SERVICE-NAME)
(provide dependency-list-item)
;; =================================================

;; ===== building blocks =====
;; caffeine-expectation
(define-macro (caffeine-expectation EXPECTS-TOK THRESHOLD AVAILABILITY-TOK)
  #'THRESHOLD)
(provide caffeine-expectation)

;; caffeine-threshold
(define-macro (caffeine-threshold NUMBER-TOK PERCENT-TOK)
  #'(string->number NUMBER-TOK))
(provide caffeine-threshold)

;; caffeine-service-name
(define-macro (caffeine-service-name WORD-TOK . REST)
  #'(string-append WORD-TOK 
     (if (empty? (filter string? (list . REST)))
         ""
         (string-append " " (string-join (filter string? (list . REST)) " ")))))
(provide caffeine-service-name)
;; =================================================

;; ===== basics =====
;; caffeine-decleration-end
(define-macro (caffeine-decleration-end PERIOD-TOK)
  #'#f)
(provide caffeine-decleration-end)

;; caffeine-and
(define-macro (caffeine-and AND-TOK)
  #'#f)
(provide caffeine-and)
;; =================================================
