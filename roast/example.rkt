#lang racket

;; Example demonstrating the ideal roast usage pattern
(require "main.rkt")
(require "file-loader.rkt")

(printf "=== Roast Library - Ideal Usage Pattern ===\n\n")

;; Step 1: Load caffeine file to get IR data (file I/O happens once)
(printf "Step 1: Loading caffeine file to get IR data...\n")
(define ir-data (load-caffeine-file "../caffeine/test-example.cf"))
(printf "✓ IR data loaded: ~a services found\n\n" (length (cdr ir-data)))

;; Step 2: Process IR data (fast, in-memory operations)
(printf "Step 2: Processing IR data...\n")
(define-values (services dependencies availabilities) (process-ir-data ir-data))
(printf "✓ Services: ~a\n" services)
(printf "✓ Dependencies: ~a\n" dependencies)
(printf "✓ Availabilities: ~a\n\n" availabilities)

;; Step 3: Generate summary (reusing same IR data)
(printf "Step 3: Generating service summary...\n")
(define summary (get-service-summary ir-data))
(printf "✓ Service count: ~a\n" (hash-ref summary 'service-count))
(printf "✓ Dependency count: ~a\n" (hash-ref summary 'dependency-count))
(define metrics (hash-ref summary 'availability-metrics))
(printf "✓ Average availability: ~a%\n" (hash-ref metrics 'average))
(printf "✓ Min availability: ~a%\n\n" (hash-ref metrics 'minimum))

;; Step 4: Validate IR data (still using same IR data)
(printf "Step 4: Validating IR data...\n")
(define validation (validate-ir-data ir-data))
(printf "✓ Valid: ~a\n" (hash-ref validation 'valid))
(printf "✓ Error: ~a\n" (hash-ref validation 'error))
(printf "✓ Invalid dependencies: ~a\n\n" (length (hash-ref validation 'invalid-dependencies)))

(printf "=== Benefits of IR-First Design ===\n")
(printf "• File was parsed only ONCE\n")
(printf "• All subsequent operations worked on in-memory IR data\n")
(printf "• Fast, testable, and cacheable\n")
(printf "• Clean separation between file I/O and data processing\n") 