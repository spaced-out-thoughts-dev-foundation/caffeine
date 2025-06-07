#lang racket

(require "caffeine/main.rkt")

;; ===== COMPREHENSIVE CAFFEINE LANGUAGE TESTS =====

;; Test 1: Valid calls
(displayln "=== Test 1: Valid calls ===")
(displayln (slo "web-service" 99.9))
(displayln (slo "api-gateway" 95.5))

;; Test 2: Contract violations
(displayln "
=== Test 2: Contract violations ===")
(with-handlers ([exn:fail:contract? (lambda (e) (displayln (exn-message e)))]) (slo 123 99.9))

;; Test 3: Caffeine test framework
(displayln "
=== Test 3: Caffeine test framework ===")
(test-suite "Contract Tests")
(test-equal (slo "Vanilla" 99.99) "SLO: Vanilla 99.99" "Vanilla SLO")
(test-equal (slo "Espresso" 99.5) "SLO: Espresso 99.5" "Espresso SLO")
(run-tests)
