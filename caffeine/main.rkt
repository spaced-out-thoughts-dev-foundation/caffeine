#lang racket/base

(require (for-syntax racket/base))
(require racket/contract)
(require "support/testing.rkt")

(provide (rename-out [caffeine-module-begin #%module-begin])
         #%app #%datum #%top
         (contract-out [slo (-> string? number? string?)])
         (all-from-out "support/testing.rkt"))

;; Main functions
(define (slo service threshold)
  (string-append "SLO: " service " " (number->string threshold)))

(define-syntax-rule (caffeine-module-begin expr ...)
  (#%plain-module-begin
   expr ...))
