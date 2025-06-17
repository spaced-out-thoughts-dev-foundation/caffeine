#lang racket

;; Export the parsing functions
(provide parse-caffeine-file get-services get-dependencies)

;; Import the caffeine DSL parser
(require "../caffeine/main.rkt")

;; Parse a caffeine file using the robust DSL parser
(define (parse-caffeine-file filename)
  "Parse a caffeine file and return a list of service declarations"
  (define parsed-data (parse-caffeine-to-data filename))
  ;; Convert from DSL format to our expected format
  (extract-services-from-dsl parsed-data))

(define (extract-services-from-dsl dsl-data)
  "Convert DSL structured data to our expected format: (service-name availability dependencies)"
  (match dsl-data
    [`(caffeine-program . ,services)
     (map extract-service-data services)]
    [_ (error "Invalid DSL data format")]))

(define (extract-service-data service-data)
  "Extract service data from DSL format"
  (match service-data
    [`(service ,name ,availability ,dependencies)
     (list name availability dependencies)]
    [_ (error "Invalid service data format")]))

(define (get-services parsed-data)
  "Extract unique service names from parsed data"
  (remove-duplicates 
    (append (map car parsed-data)
            (apply append (map caddr parsed-data)))))

(define (get-dependencies parsed-data)
  "Extract dependency relationships as (from to) pairs"
  (apply append
    (for/list ([service-data parsed-data])
      (define service-name (car service-data))
      (define deps (caddr service-data))
      (for/list ([dep deps])
        (list service-name dep))))) 