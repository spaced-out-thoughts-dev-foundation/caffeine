#lang racket

(provide (rename-out [caffeine #%module-begin]))

(define-syntax-rule (caffeine . _)
  (#%plain-module-begin
    (displayln "Caffeine")))
