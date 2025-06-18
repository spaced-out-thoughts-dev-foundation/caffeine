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
   
   (test-case "Service mapping functions"
     (define services '("web" "api" "db"))
     (define-values (name-to-index index-to-name) (create-service-mapping services))
     
     ;; Test name to index mapping
     (check-equal? (service-name->index "web" name-to-index) 0)
     (check-equal? (service-name->index "api" name-to-index) 1)
     (check-equal? (service-name->index "db" name-to-index) 2)
     (check-equal? (service-name->index "nonexistent" name-to-index) #f)
     
     ;; Test index to name mapping
     (check-equal? (index->service-name 0 index-to-name) "web")
     (check-equal? (index->service-name 1 index-to-name) "api")
     (check-equal? (index->service-name 2 index-to-name) "db")
     (check-equal? (index->service-name 99 index-to-name) #f))
   
   (test-case "Dependency validation"
     (define services '("web" "api" "db"))
     (define valid-deps '((0 1) (1 2)))
     (define invalid-deps '((0 1) (1 99) (99 2)))
     
     (define-values (valid-result invalid-result) 
       (validate-dependencies valid-deps services))
     (check-equal? valid-result '((0 1) (1 2)))
     (check-equal? invalid-result '())
     
     (define-values (mixed-valid mixed-invalid) 
       (validate-dependencies invalid-deps services))
     (check-equal? mixed-valid '((0 1)))
     (check-equal? mixed-invalid '((1 99) (99 2))))))

(run-tests roast-tests) 