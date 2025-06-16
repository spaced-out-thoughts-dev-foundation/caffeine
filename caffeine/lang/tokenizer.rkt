;; A token is the smallest meaningful chunk of a string of source code.
;; The tokenizer converts a stream of characters into a stream of tokens.
#lang br/quicklang
(require brag/support)

(define (make-tokenizer port)
  (define (next-token)
    (define caffeine-lexer
      (lexer
       [(from/to "//" "\n") (next-token)]
       [whitespace (token 'WS-TOK)]
       ["expects" (token 'EXPECTS-TOK)]
       ["%" (token 'PERCENT-TOK)]
       [any-char (token 'CHAR-TOK lexeme)]))
    (caffeine-lexer port))
  next-token)
(provide make-tokenizer)