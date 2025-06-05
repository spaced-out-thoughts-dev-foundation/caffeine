#lang reader "./caffeine/lang/reader.rkt"

(test-suite "Caffeine Language Tests")

;; Test basic coffee functions
(test-equal (display-cafe) 
            "☕ Welcome to the cafe! Enjoy your coffee! ☕"
            "cafe function should return welcome message")

;; This should be transformed from bare symbol to function call by our reader
(test-equal cafe "☕ Welcome to the cafe! Enjoy your coffee! ☕" "bare 'cafe' should work")

;; Run all tests and show results
(run-tests)
