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

;; Step 3: Demonstrate utility functions
(printf "Step 3: Using utility functions...\n")
(define-values (name-to-index index-to-name) (create-service-mapping services))
(printf "✓ Created service mapping\n")

(define-values (valid-deps invalid-deps) (validate-dependencies dependencies services))
(printf "✓ Valid dependencies: ~a\n" (length valid-deps))
(printf "✓ Invalid dependencies: ~a\n\n" (length invalid-deps))

(printf "=== Benefits of IR-First Design ===\n")
(printf "• File was parsed only ONCE\n")
(printf "• All subsequent operations worked on in-memory IR data\n")
(printf "• Fast, testable, and cacheable\n")
(printf "• Clean separation between file I/O and data processing\n") 