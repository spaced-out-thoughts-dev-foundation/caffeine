#lang racket/base

(require (for-syntax racket/base))
(require "support/testing.rkt")

(provide (rename-out [caffeine-module-begin #%module-begin]
                     [caffeine-top #%top]
                     [caffeine-app #%app])
         #%datum
         quote
         begin
         slo
         depends
         get-dependencies
         hash-clear!
         dependencies
         (all-from-out "support/testing.rkt"))

;; Main functions
(define (slo service)
  (string-append "SLO: " service))

;; Dependency tracking
(define dependencies (make-hash))

;; Function to handle dependencies - we'll use a different approach
(define (add-dependency service dependency)
  (hash-set! dependencies service (cons dependency 
                                        (hash-ref dependencies service '())))
  (printf "~a depends on ~a~n" service dependency))

;; Runtime function to handle quoted expressions
(define (add-dependency-runtime service dependency)
  (let ([service-sym (if (and (pair? service) (eq? (car service) 'quote))
                         (cadr service)
                         service)]
        [dependency-sym (if (and (pair? dependency) (eq? (car dependency) 'quote))
                            (cadr dependency)
                            dependency)])
    (add-dependency service-sym dependency-sym)))

;; Macro to handle "ServiceA depends on ServiceB" syntax
;; This needs to be an application macro since it's infix
(define-syntax depends
  (syntax-rules (on)
    [(_ service on dependency)
     (add-dependency 'service 'dependency)]))

;; Override #%app to handle the infix depends syntax
(define-syntax (caffeine-app stx)
  (syntax-case stx (depends on)
    [(_ service depends on dependency)
     #'(add-dependency-runtime service dependency)]
    [(_ proc arg ...)
     #'(#%app proc arg ...)]))

;; Helper to get dependencies
(define (get-dependencies service)
  (hash-ref dependencies service '()))

;; Helper to clear dependencies (for testing)
(define (hash-clear! hash)
  (for ([key (hash-keys hash)])
    (hash-remove! hash key)))

;; Handle undefined identifiers by treating them as symbols
(define-syntax caffeine-top
  (syntax-rules ()
    [(_ . id) 'id]))

(define-syntax-rule (caffeine-module-begin expr ...)
  (#%plain-module-begin
    expr ...))
