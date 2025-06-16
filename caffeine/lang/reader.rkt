;; The reader con­verts the source code of our lan­guage from a string of char­ac­ters into Racket-style
;; paren­the­sized forms, also known as S-expres­sions.
#lang br/quicklang
(require "tokenizer.rkt" "parser.rkt")

(define (read-syntax path port)
  (define parse-tree (parse path (make-tokenizer port)))
  (define module-datum `(module caffeine-module caffeine/lang/expander
                          ,parse-tree))
  (datum->syntax #f module-datum))
(provide read-syntax)