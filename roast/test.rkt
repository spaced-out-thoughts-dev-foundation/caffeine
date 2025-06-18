#lang racket

(require rackunit rackunit/text-ui)
(require "main.rkt")
(require "file-loader.rkt")

(define roast-tests
  (test-suite
   "Roast IR Processing Tests"
   
   (test-case "Load caffeine file and get IR data"
     (define ir-data (load-caffeine-file "../caffeine/test-example.cf"))
     (check-true (list? ir-data))
     (check-equal? (car ir-data) 'caffeine-program)
     (displayln (format "IR Data: ~a" ir-data)))
   
   (test-case "Process IR data directly"
     (define ir-data (load-caffeine-file "../caffeine/test-example.cf"))
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
                         dependencies)))
   
   (test-case "Parse IR data and extract components"
     (define ir-data '(caffeine-program 
                       (service "hello" 99.9 ("world"))
                       (service "world" 98.5 ("hello"))))
     
     (define services (extract-services ir-data))
     (define availabilities (extract-availabilities ir-data))
     (define dependencies (extract-dependencies ir-data))
     
     (check-equal? services '("hello" "world"))
     (check-equal? availabilities '(99.9 98.5))
     (check-equal? dependencies '((0 1) (1 0))))
   
   (test-case "Service mapping utilities"
     (define services '("hello" "world" "test"))
     (define-values (name-to-index index-to-name) (create-service-mapping services))
     
     (check-equal? (service-name->index "hello" name-to-index) 0)
     (check-equal? (service-name->index "world" name-to-index) 1)
     (check-equal? (service-name->index "test" name-to-index) 2)
     (check-equal? (service-name->index "nonexistent" name-to-index) #f)
     
     (check-equal? (index->service-name 0 index-to-name) "hello")
     (check-equal? (index->service-name 1 index-to-name) "world")
     (check-equal? (index->service-name 2 index-to-name) "test")
     (check-equal? (index->service-name 99 index-to-name) #f))
   
   (test-case "Dependency validation"
     (define services '("a" "b" "c"))
     (define valid-deps '((0 1) (1 2) (2 0)))
     (define invalid-deps '((0 5) (10 1) (-1 2)))
     (define mixed-deps (append valid-deps invalid-deps))
     
     (define-values (validated-valid validated-invalid) 
       (validate-dependencies mixed-deps services))
     
     (check-equal? (length validated-valid) 3)
     (check-equal? (length validated-invalid) 3)
     (check-true (not (null? (andmap (lambda (dep) (member dep valid-deps)) validated-valid))))
     (check-true (not (null? (andmap (lambda (dep) (member dep invalid-deps)) validated-invalid)))))
   
   (test-case "Availability metrics calculation"
     (define availabilities '(99.9 95.5 98.2 99.0))
     (define metrics (calculate-availability-metrics availabilities))
     
     (check-equal? (hash-ref metrics 'count) 4)
     (check-equal? (hash-ref metrics 'minimum) 95.5)
     (check-equal? (hash-ref metrics 'maximum) 99.9)
     (check-= (hash-ref metrics 'average) 98.15 0.01)
     (check-equal? (hash-ref metrics 'total) 392.6))
   
   (test-case "Service summary from IR data"
     (define ir-data (load-caffeine-file "../caffeine/test-example.cf"))
     (define summary (get-service-summary ir-data))
     
     (check-true (hash? summary))
     (check-true (hash-has-key? summary 'services))
     (check-true (hash-has-key? summary 'service-count))
     (check-true (hash-has-key? summary 'dependencies))
     (check-true (hash-has-key? summary 'availability-metrics))
     (check-true (hash-has-key? summary 'service-details))
     
     (check-equal? (hash-ref summary 'service-count) 4)
     (check-true (> (length (hash-ref summary 'dependencies)) 0)))
   
   (test-case "IR data validation"
     (define ir-data (load-caffeine-file "../caffeine/test-example.cf"))
     (define validation (validate-ir-data ir-data))
     
     (check-true (hash? validation))
     (check-true (hash-has-key? validation 'valid))
     (check-true (hash-has-key? validation 'services))
     (check-true (hash-has-key? validation 'dependencies))
     
     ;; Should be valid for the test file
     (check-true (hash-ref validation 'valid))
     (check-equal? (hash-ref validation 'error) #f))))

(run-tests roast-tests) 