#lang racket

(require "parser.rkt")
(require "utils.rkt")

;; Re-export all parser functions (IR processing only)
(provide (all-from-out "parser.rkt"))

;; Re-export all utility functions  
(provide (all-from-out "utils.rkt"))

;; High-level IR processing functions
(provide process-ir-data)

;; Process intermediate representation data directly
(define (process-ir-data ir-data)
  (with-handlers ([exn:fail? (lambda (e) 
                               (printf "DEBUG: Error in process-ir-data: ~a~n" e)
                               (values '() '() '()))])
    (create-dependency-graph-from-ir ir-data))) 