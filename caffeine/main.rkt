#lang racket/base

(require (for-syntax racket/base))
(require "support/testing.rkt")

(provide (rename-out [caffeine-module-begin #%module-begin])
         #%app #%datum #%top
         slo
         (all-from-out "support/testing.rkt"))

;; Main functions
(define (slo service threshold)
  (string-append "SLO: " service " " threshold))

(define-syntax-rule (caffeine-module-begin expr ...)
  (#%plain-module-begin
    expr ...))
