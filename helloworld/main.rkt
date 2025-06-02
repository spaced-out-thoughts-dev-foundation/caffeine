#lang racket

(provide (rename-out [hello-world #%module-begin]))

(define-syntax-rule (hello-world . _)
  (#%plain-module-begin
    (displayln "Hello, World!")))
