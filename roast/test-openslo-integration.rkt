#lang racket

(require "main.rkt")
(require "file-loader.rkt")

(printf "Testing OpenSLO integration with Caffeine DSL...\n")

;; Load test file
(define ir-data (load-caffeine-file "../caffeine/test-example.cf"))
(printf "Loaded IR data: ~a\n" (if ir-data "SUCCESS" "FAILED"))

;; Generate OpenSLO specifications
(define openslo-specs (generate-complete-openslo ir-data))
(printf "Generated ~a OpenSLO specifications\n" (length openslo-specs))

;; Verify we have the expected components
(define kinds (map (lambda (spec) (hash-ref spec 'kind)) openslo-specs))
(define service-count (length (filter (lambda (k) (equal? k "Service")) kinds)))
(define slo-count (length (filter (lambda (k) (equal? k "SLO")) kinds)))
(define alert-count (length (filter (lambda (k) (equal? k "AlertPolicy")) kinds)))
(define notification-count (length (filter (lambda (k) (equal? k "AlertNotificationTarget")) kinds)))

(printf "Components generated:\n")
(printf "  - Services: ~a\n" service-count)
(printf "  - SLOs: ~a\n" slo-count)
(printf "  - Alert Policies: ~a\n" alert-count)
(printf "  - Notification Targets: ~a\n" notification-count)

;; Verify we have at least some specs
(if (> (length openslo-specs) 0)
    (printf "✅ OpenSLO integration test PASSED!\n")
    (printf "❌ OpenSLO integration test FAILED - no specs generated\n"))

;; Test YAML formatting
(define yaml-output (format-openslo-yaml openslo-specs))
(printf "YAML output length: ~a characters\n" (string-length yaml-output))

(if (> (string-length yaml-output) 100)
    (printf "✅ YAML formatting test PASSED!\n")
    (printf "❌ YAML formatting test FAILED - output too short\n"))

(printf "OpenSLO integration test completed.\n") 