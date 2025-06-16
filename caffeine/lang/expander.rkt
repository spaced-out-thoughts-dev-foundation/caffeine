;; The expander deter­mines how the code produced by the reader cor­re­sponds to real Racket expres­sions,
;; which are then eval­u­ated to pro­duce a result. The expander works by adding bind­ings to iden­ti­fiers
;; in the code.
#lang br/quicklang
(require json)

(define-macro (caffeine-mb PARSE-TREE)
  #'(#%module-begin
     (display PARSE-TREE)))
(provide (rename-out [caffeine-mb #%module-begin]))

(define-macro (caffeine-program _ . SERVICE-DECLARATIONS)
  #'(string-append . SERVICE-DECLARATIONS))
(provide caffeine-program)

(define-macro (caffeine-service-declaration SERVICE-NAME _ _ _ THRESHOLD _ _ _)
  #'(string-append SERVICE-NAME " expects " THRESHOLD "%.\n"))
(provide caffeine-service-declaration)

(define-macro (caffeine-service-name WORD-TOK . REST)
  #'(string-append WORD-TOK 
     (if (empty? (filter string? (list . REST)))
         ""
         (string-append " " (string-join (filter string? (list . REST)) " ")))))
(provide caffeine-service-name)

(define-macro (ws . _)
  #'#f)
(provide ws)
