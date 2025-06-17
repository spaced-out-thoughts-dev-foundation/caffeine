;; The expander deter­mines how the code produced by the reader cor­re­sponds to real Racket expres­sions,
;; which are then eval­u­ated to pro­duce a result. The expander works by adding bind­ings to iden­ti­fiers
;; in the code.
#lang br/quicklang
(require json)

(define-macro (caffeine-mb PARSE-TREE)
  #'(#%module-begin
     (display PARSE-TREE)))
(provide (rename-out [caffeine-mb #%module-begin]))

;; ===== top level =====
;; caffeine-program
(define-macro (caffeine-program _ . SERVICE-DECLARATIONS)
  #'(string-append . SERVICE-DECLARATIONS))
(provide caffeine-program)
;; =================================================

;; ===== higher level constructs =====
;; caffeine-service-declaration
(define-macro (caffeine-service-declaration SERVICE-NAME _ EXPECTATION _ AND-TOK DEPENDENCY DECLERATION-END)
  #'(string-append SERVICE-NAME " " EXPECTATION " " AND-TOK " " DEPENDENCY DECLERATION-END))
(provide caffeine-service-declaration)
;; =================================================

;; ===== medium level constructs =====
;; caffeine-service-dependency
(define-macro (caffeine-service-dependency DEPENDENCY)
  #'(string-append DEPENDENCY))
(provide caffeine-service-dependency)
;; single-dependency
(define-macro (single-dependency _ DEPENDS-TOK _ ON-TOK _ SERVICE-NAME _)
  #'(string-append DEPENDS-TOK " " ON-TOK " " SERVICE-NAME))
(provide single-dependency)

;; no-dependency
(define-macro (no-dependency _ HAS-TOK _ NO-TOK _ DEPENDENCIES-TOK _)
  #'(string-append HAS-TOK " " NO-TOK " " DEPENDENCIES-TOK))
(provide no-dependency)
;; =================================================

;; ===== building blocks =====
;; caffeine-expectation
(define-macro (caffeine-expectation EXPECTS-TOK _ THRESHOLD)
  #'(string-append EXPECTS-TOK " " THRESHOLD))
(provide caffeine-expectation)

;; caffeine-threshold
(define-macro (caffeine-threshold NUMBER-TOK PERCENT-TOK)
  #'(string-append NUMBER-TOK PERCENT-TOK))
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
;; caffeine-ws
(define-macro (caffeine-ws . _)
  #'#f)
(provide caffeine-ws)

;; caffeine-decleration-end
(define-macro (caffeine-decleration-end PERIOD-TOK _)
  #'(string-append PERIOD-TOK "\n"))
(provide caffeine-decleration-end)

;; caffeine-and
(define-macro (caffeine-and AND-TOK _)
  #'(string-append AND-TOK))
(provide caffeine-and)
;; =================================================
