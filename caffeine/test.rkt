#lang racket

(require rackunit rackunit/text-ui)
(require "main.rkt")

(define (run-caffeine-file file-path)
  (parse-caffeine-to-data file-path))

(define hello-tests
  (test-suite
   "Caffeine Parser Tests"
   (test-case "Parse caffeine file and check structured output"
     (define output (run-caffeine-file "test-example.cf"))
     (displayln (format "Parsed data: ~a" output))
     (check-equal? output 
                   '(caffeine-program 
                     (service "hello" 99.9 ("salad"))
                     (service "salad" 99.995 ())
                     (service "tasty fruit bar" 99.999 ())
                     (service "authentication service" 98.5 ("salad" "hello" "tasty fruit bar")))))))

(run-tests hello-tests)
