#lang racket

(require rackunit rackunit/text-ui)
(require "graph.rkt")
(require "../roast/file-loader.rkt")
(require "../roast/main.rkt")

(define brewface-tests
  (test-suite
   "Brewface Parser Tests"
   (test-case "Parse caffeine file using ideal IR pattern"
     ;; Step 1: Load IR data
     (define ir-data (load-caffeine-file "../caffeine/test-example.cf"))
     (displayln (format "IR Data: ~a" ir-data))
     
     ;; Step 2: Process IR data
     (define-values (services dependencies availabilities) 
       (process-ir-data ir-data))
     (displayln (format "Services: ~a" services))
     (displayln (format "Dependencies: ~a" dependencies))
     (displayln (format "Availabilities: ~a" availabilities))
     
     ;; Check services are extracted correctly
     (check-equal? (sort services string<?) 
                   (sort '("hello" "salad" "tasty fruit bar" "authentication service") string<?))
     
     ;; Check availabilities are extracted correctly
     (check-equal? availabilities '(99.9 99.995 99.999 98.5))
     
     ;; Check dependencies are converted to indices correctly
     (check-true (list? dependencies))
     (check-true (andmap (lambda (dep) 
                           (and (list? dep) 
                                (= (length dep) 2)
                                (number? (first dep))
                                (number? (second dep))))
                         dependencies)))))

(run-tests brewface-tests) 