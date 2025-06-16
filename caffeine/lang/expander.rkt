;; The expander deter­mines how the code produced by the reader cor­re­sponds to real Racket expres­sions,
;; which are then eval­u­ated to pro­duce a result. The expander works by adding bind­ings to iden­ti­fiers
;; in the code.
#lang br/quicklang
(require json)

(define-macro (caffeine-mb PARSE-TREE)
  #'(#%module-begin
     (display PARSE-TREE)))
(provide (rename-out [caffeine-mb #%module-begin]))

(define-macro (caffeine-char CHAR-TOK-VALUE)
  #'CHAR-TOK-VALUE)
(provide caffeine-char)

(define-macro (caffeine-word WORD-TOK-VALUE)
  #'WORD-TOK-VALUE)
(provide caffeine-word)

(define-macro (caffeine-number NUMBER-TOK-VALUE)
  #'NUMBER-TOK-VALUE)
(provide caffeine-number)

(define-macro (caffeine-expectation _ _ NUMBER-VALUE _)
  #'(string-append "expects " NUMBER-VALUE "%"))
(provide caffeine-expectation)

(define-macro (ws . _)
  #'#f)
(provide ws)

(define-macro (caffeine-service-declaration WORD _ _ _ NUMBER _ _ _)
  #'(string-append WORD " expects " NUMBER "%.\n"))
(provide caffeine-service-declaration)

(define-macro (caffeine-program _ . SERVICE-DECLARATIONS)
  #'(string-append . SERVICE-DECLARATIONS))
(provide caffeine-program)
