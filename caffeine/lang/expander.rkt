;; The expander deter­mines how the code produced by the reader cor­re­sponds to real Racket expres­sions,
;; which are then eval­u­ated to pro­duce a result. The expander works by adding bind­ings to iden­ti­fiers
;; in the code.
#lang br/quicklang
(require json)

(define-macro (caffeine-mb PARSE-TREE)
  #'(#%module-begin
     (define result-string PARSE-TREE)
     (display result-string)))
(provide (rename-out [caffeine-mb #%module-begin]))

(define-macro (caffeine-char CHAR-TOK-VALUE)
  #'CHAR-TOK-VALUE)
(provide caffeine-char)

(define-macro (caffeine-program SIMPLE-STR ...)
  #'(string-trim (string-append SIMPLE-STR ...)))
(provide caffeine-program)
