#lang racket

(require rackunit rackunit/text-ui)

(define hello-content
  (call-with-input-file "hello.cf" port->string))

(define hello-tests
  (test-suite
   "Hello World Tests"
   (test-case "Check hello.cf contents"
     (check-equal? hello-content "hello world"))))

(run-tests hello-tests)
