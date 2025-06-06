#lang racket/base

(require racket/path)
(provide read-syntax)

(define (parse-caffeine-syntax content)
  "Parse and transform caffeine-specific syntax"
  (cond
    [(and (list? content) (not (null? content)))
     (map parse-caffeine-syntax content)]
    [else content]))

(define (read-all-expressions port)
  "Read all expressions from the port"
  (let loop ([expressions '()])
    (let ([expr (read port)])
      (if (eof-object? expr)
          (reverse expressions)
          (loop (cons expr expressions))))))

(define (read-syntax name port)
  (define content-list (read-all-expressions port))
  (define parsed-content (map parse-caffeine-syntax content-list))
  (define module-name 
    (if name 
        (let ([path-string (if (path? name) (path->string name) (symbol->string name))])
          (string->symbol (path->string (file-name-from-path path-string))))
        'anonymous))
  (define module-form
    `(module ,module-name "caffeine/main.rkt"
       ,@parsed-content))
  (datum->syntax #f module-form))
