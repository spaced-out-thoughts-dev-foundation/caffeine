#lang racket/base

(require racket/path)
(provide read-syntax)

(define (read-syntax name port)
  (define content (read port))
  (define module-name 
    (if name 
        (let ([path-string (if (path? name) (path->string name) (symbol->string name))])
          (string->symbol (path->string (file-name-from-path path-string))))
        'anonymous))
  (define module-form
    `(module ,module-name helloworld/main
       ,content))
  (datum->syntax #f module-form))
