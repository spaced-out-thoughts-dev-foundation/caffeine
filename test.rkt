#lang reader "./caffeine/lang/reader.rkt"

(test-suite "Caffeine Language Tests")

;; Test basic coffee functions with different flavors
(test-equal (display-cafe "Vanilla") 
            "☕ Welcome to the cafe! Enjoy your coffee! Vanilla. ☕"
            "cafe function should return welcome message with Vanilla flavor")

(test-equal (display-cafe "Espresso") 
            "☕ Welcome to the cafe! Enjoy your coffee! Espresso. ☕"
            "cafe function should return welcome message with Espresso flavor")

(test-equal (display-cafe "Latte") 
            "☕ Welcome to the cafe! Enjoy your coffee! Latte. ☕"
            "cafe function should return welcome message with Latte flavor")

;; This should be transformed from bare symbol to function call by our reader
(test-equal cafe "☕ Welcome to the cafe! Enjoy your coffee! ☕" "bare 'cafe' should work")

;; Run all tests and show results
(run-tests)
