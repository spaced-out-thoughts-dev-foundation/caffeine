#lang racket

(provide extract-services
         extract-dependencies  
         extract-availabilities
         create-dependency-graph-from-ir
         parse-ir-data)

;; Parse intermediate representation data structure
(define (parse-ir-data parsed-data)
  (if (and (list? parsed-data) 
           (not (null? parsed-data))
           (eq? (car parsed-data) 'caffeine-program))
      (cdr parsed-data) ; Skip 'caffeine-program header
      (error "Invalid IR format: expected caffeine-program structure")))

;; Extract service names from parsed IR data
(define (extract-services parsed-data)
  (define services-data (parse-ir-data parsed-data))
  (map cadr services-data))

;; Extract availabilities from parsed IR data
(define (extract-availabilities parsed-data)
  (define services-data (parse-ir-data parsed-data))
  (map caddr services-data))

;; Extract dependencies from parsed IR data
(define (extract-dependencies parsed-data)
  (define services-data (parse-ir-data parsed-data))
  (define service-names (extract-services parsed-data))
  
  ;; Create service name to index mapping
  (define name-to-index (make-hash))
  (for ([name service-names] [i (in-range (length service-names))])
    (hash-set! name-to-index name i))
  
  ;; Build dependencies list as (from-index to-index) pairs
  (apply append
         (for/list ([service-data services-data] [from-idx (in-range (length service-names))])
           (define deps (cadddr service-data))
           (filter (lambda (x) x)  ; Remove #f values
             (for/list ([dep deps])
               (define to-idx (hash-ref name-to-index dep #f))
               (if to-idx
                   (list from-idx to-idx)
                   (begin
                     (printf "DEBUG: Skipping unknown dependency: ~a~n" dep)
                     #f)))))))

;; Create a complete dependency graph from intermediate representation
(define (create-dependency-graph-from-ir parsed-data)
  (define service-names (extract-services parsed-data))
  (define dependencies (extract-dependencies parsed-data))
  (define availabilities (extract-availabilities parsed-data))
  
  (values service-names dependencies availabilities)) 