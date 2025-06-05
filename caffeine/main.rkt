#lang racket/base

(require (for-syntax racket/base))
(require "support/testing.rkt")

(provide (rename-out [caffeine-module-begin #%module-begin])
         #%app #%datum #%top
         displayln printf format
         equal? string=? length filter
         + - * / > < >= <= = 
         quote list car cdr cons null?
         display-cafe
         (all-from-out "support/testing.rkt"))

;; Coffee functions
(define (display-cafe)
  "☕ Welcome to the cafe! Enjoy your coffee! ☕")

(define-syntax-rule (caffeine-module-begin expr ...)
  (#%plain-module-begin
    expr ...))
