#lang racket

(provide service-name->index
         index->service-name
         create-service-mapping
         validate-dependencies)

;; Create bidirectional mapping between service names and indices
(define (create-service-mapping service-names)
  (define name-to-index (make-hash))
  (define index-to-name (make-hash))
  (for ([name service-names] [i (in-range (length service-names))])
    (hash-set! name-to-index name i)
    (hash-set! index-to-name i name))
  (values name-to-index index-to-name))

;; Convert service name to index using mapping
(define (service-name->index name mapping)
  (hash-ref mapping name #f))

;; Convert index to service name using mapping
(define (index->service-name index mapping)
  (hash-ref mapping index #f))

;; Validate that all dependencies reference existing services
(define (validate-dependencies dependencies service-names)
  (define max-index (- (length service-names) 1))
  (define valid-deps '())
  (define invalid-deps '())
  
  (for ([dep dependencies])
    (define from-idx (first dep))
    (define to-idx (second dep))
    (if (and (<= 0 from-idx max-index)
             (<= 0 to-idx max-index))
        (set! valid-deps (cons dep valid-deps))
        (set! invalid-deps (cons dep invalid-deps))))
  
  (values (reverse valid-deps) (reverse invalid-deps))) 