#lang racket/base

(provide read-syntax)

(define (read-syntax name port)
  (define content (read port))
  (define module-form
    `(module caffeine-module "caffeine/main.rkt"
       ,content))
  (datum->syntax #f module-form))
