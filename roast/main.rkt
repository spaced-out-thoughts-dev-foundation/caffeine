#lang racket

(require "parser.rkt")
(require "utils.rkt")

;; Re-export all parser functions (IR processing only)
(provide (all-from-out "parser.rkt"))

;; Re-export all utility functions  
(provide (all-from-out "utils.rkt"))

;; High-level IR processing functions
(provide process-ir-data
         get-service-summary
         validate-ir-data)

;; Process intermediate representation data directly
(define (process-ir-data ir-data)
  (with-handlers ([exn:fail? (lambda (e) 
                               (printf "DEBUG: Error in process-ir-data: ~a~n" e)
                               (values '() '() '()))])
    (create-dependency-graph-from-ir ir-data)))

;; Get a comprehensive summary from IR data
(define (get-service-summary ir-data)
  (define-values (service-names dependencies availabilities) (process-ir-data ir-data))
  (define metrics (calculate-availability-metrics availabilities))
  (define service-info (format-service-info service-names dependencies availabilities))
  (define-values (valid-deps invalid-deps) (validate-dependencies dependencies service-names))
  
  (hash 'services service-names
        'service-count (length service-names)
        'dependencies dependencies
        'dependency-count (length dependencies)
        'valid-dependencies valid-deps
        'invalid-dependencies invalid-deps
        'availabilities availabilities
        'availability-metrics metrics
        'service-details service-info))

;; Validate IR data directly
(define (validate-ir-data ir-data)
  (with-handlers ([exn:fail? (lambda (e) 
                               (hash 'valid #f
                                     'error (exn-message e)
                                     'services '()
                                     'dependencies '()))])
    (define-values (service-names dependencies availabilities) (process-ir-data ir-data))
    (define-values (valid-deps invalid-deps) (validate-dependencies dependencies service-names))
    
    (hash 'valid (null? invalid-deps)
          'error #f
          'services service-names
          'dependencies dependencies
          'valid-dependencies valid-deps
          'invalid-dependencies invalid-deps
          'availabilities availabilities))) 