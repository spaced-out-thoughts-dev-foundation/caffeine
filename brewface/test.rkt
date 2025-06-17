#lang racket

(require rackunit rackunit/text-ui)
(require "caffeine-parser.rkt")

(define brewface-tests
  (test-suite
   "Brewface Parser Tests"
   (test-case "Parse caffeine file and extract service data"
     (define parsed-data (parse-caffeine-file "../caffeine/test-example.cf"))
     (displayln (format "Parsed data: ~a" parsed-data))
     ;; Expected format: list of (service-name availability dependencies)
     (check-equal? parsed-data 
                   '(("hello" 99.9 ("salad"))
                     ("salad" 99.995 ())
                     ("tasty fruit bar" 99.999 ())
                     ("authentication service" 98.5 ("salad" "hello" "tasty fruit bar")))))
   
   (test-case "Extract unique services"
     (define parsed-data (parse-caffeine-file "../caffeine/test-example.cf"))
     (define services (get-services parsed-data))
     (displayln (format "Services: ~a" services))
     (check-equal? (sort services string<?) 
                   (sort '("hello" "salad" "tasty fruit bar" "authentication service") string<?)))
   
   (test-case "Extract dependencies"
     (define parsed-data (parse-caffeine-file "../caffeine/test-example.cf"))
     (define dependencies (get-dependencies parsed-data))
     (displayln (format "Dependencies: ~a" dependencies))
     (check-equal? (sort dependencies (lambda (a b) (string<? (car a) (car b))))
                   (sort '(("hello" "salad")
                          ("authentication service" "salad")
                          ("authentication service" "hello")
                          ("authentication service" "tasty fruit bar"))
                         (lambda (a b) (string<? (car a) (car b))))))))

(run-tests brewface-tests) 