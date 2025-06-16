#lang racket

(require rackunit rackunit/text-ui)

(define (run-caffeine-file file-path)
  (define output-port (open-output-string))
  (parameterize ([current-output-port output-port])
    (dynamic-require (string->path file-path) #f))
  (get-output-string output-port))

(define hello-tests
  (test-suite
   "Hello World Tests"
   (test-case "Execute hello.cf and check output"
     (define output (run-caffeine-file "hello.cf"))
     (displayln (format "Output: ~a" output))
     (check-equal? output "hello expects success"))))

(run-tests hello-tests)
