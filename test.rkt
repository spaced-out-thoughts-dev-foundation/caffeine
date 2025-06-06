#lang reader "./caffeine/lang/reader.rkt"

(test-suite "Caffeine Language Tests")


;; Clear dependencies for clean testing
(hash-clear! dependencies)

;; Test basic dependency declaration
(test-equal (begin
              (ServiceA depends on ServiceB)
              (get-dependencies 'ServiceA))
            '(ServiceB)
            "ServiceA should depend on ServiceB")

;; Test multiple dependencies for same service
(test-equal (begin
              (ServiceA depends on ServiceC)
              (get-dependencies 'ServiceA))
            '(ServiceC ServiceB)
            "ServiceA should have multiple dependencies")

;; Test different services
(test-equal (begin
              (ServiceD depends on ServiceE)
              (get-dependencies 'ServiceD))
            '(ServiceE)
            "ServiceD should depend on ServiceE")

;; Test empty dependencies
(test-equal (get-dependencies 'NonExistentService)
            '()
            "Non-existent service should have no dependencies")

;; Test SLO function
(test-suite "SLO Tests")

(test-equal (slo "UserService")
            "SLO: UserService"
            "SLO function should format service name correctly")

(test-equal (slo "DatabaseService")
            "SLO: DatabaseService"
            "SLO function should work with different service names")


(run-tests)
