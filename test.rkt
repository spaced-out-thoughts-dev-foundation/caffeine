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
     (define output (run-caffeine-file "test-example.cf"))
     (displayln (format "Output: ~a" output))
     (check-equal? output "hello expects 99.9% availability and depends on salad.\nsalad expects 99.995% availability and has no dependencies.\ntasty fruit bar expects 99.999% availability and has no dependencies.\nauthentication service expects 98.5% availability and depends on salad and hello and tasty fruit bar.\n"))))

(run-tests hello-tests)
