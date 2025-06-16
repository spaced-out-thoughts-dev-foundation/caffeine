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

(define-macro (caffeine-word WORD-VALUE ...)
  #'(string-append WORD-VALUE ...))
(provide caffeine-word)

(define-macro (caffeine-expect EXPECTS-TOK-VALUE)
  #'"expects")
(provide caffeine-expect)

(define-macro (ws . _)
  #'#f)

(define-macro (caffeine-program _ WORD1 _ EXPECT _ WORD2 _)
  #'(string-trim (string-append WORD1 " " EXPECT " " WORD2)))
(provide caffeine-program)
