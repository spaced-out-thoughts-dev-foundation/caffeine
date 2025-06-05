#lang racket/base

(provide assert test-equal test-suite run-tests)

;; Test tracking
(define test-results '())
(define current-suite "")

;; Testing functions
(define (assert condition [message "Assertion failed"])
  (if condition
      (begin
        (set! test-results (cons `(pass ,current-suite ,message) test-results))
        (displayln (format "✓ PASS: ~a" message)))
      (begin
        (set! test-results (cons `(fail ,current-suite ,message) test-results))
        (displayln (format "✗ FAIL: ~a" message)))))

(define (test-equal actual expected [message "Values should be equal"])
  (assert (equal? actual expected) 
          (format "~a (got ~a, expected ~a)" message actual expected)))

(define (test-suite name)
  (set! current-suite name)
  (displayln (format "\n=== ~a ===" name)))

(define (run-tests)
  (let ([total (length test-results)]
        [passed (length (filter (lambda (result) (eq? (car result) 'pass)) test-results))]
        [failed (length (filter (lambda (result) (eq? (car result) 'fail)) test-results))])
    (displayln (format "\n=== Test Results ==="))
    (displayln (format "Total: ~a, Passed: ~a, Failed: ~a" total passed failed))
    (if (= failed 0)
        (displayln "🎉 All tests passed!")
        (displayln "💥 Some tests failed!"))
    (= failed 0)))