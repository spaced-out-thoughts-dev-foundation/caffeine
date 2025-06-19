#lang racket

(require rackunit rackunit/text-ui)
(require "openslo-generator.rkt")
(require "parser.rkt")

(define openslo-tests
  (test-suite
   "OpenSLO Generator Tests"
   
   (test-case "Generate single service SLO"
     (define slo (generate-service-slo "test-service" 99.9))
     
     ;; Check basic structure
     (check-equal? (hash-ref slo 'apiVersion) "openslo/v1")
     (check-equal? (hash-ref slo 'kind) "SLO")
     
     ;; Check metadata
     (define metadata (hash-ref slo 'metadata))
     (check-equal? (hash-ref metadata 'name) "test-service-availability-slo")
     (check-equal? (hash-ref metadata 'displayName) "test-service Availability SLO")
     
     ;; Check spec structure
     (define spec (hash-ref slo 'spec))
     (check-true (string-contains? (hash-ref spec 'description) "99.9%"))
     (check-equal? (hash-ref spec 'service) "test-service")
     
     ;; Check objectives - use approximate equality for floating point
     (define objectives (hash-ref spec 'objectives))
     (check-equal? (length objectives) 1)
     (define objective (first objectives))
     (check-= (hash-ref objective 'value) 0.999 0.0001)
     (check-= (hash-ref objective 'target) 0.999 0.0001)
     (check-equal? (hash-ref objective 'op) "gte"))
   
   (test-case "Generate SLO for service with spaces in name"
     (define slo (generate-service-slo "authentication service" 95.5))
     
     (define metadata (hash-ref slo 'metadata))
     (check-equal? (hash-ref metadata 'name) "authentication-service-availability-slo")
     (check-equal? (hash-ref metadata 'displayName) "authentication service Availability SLO")
     
     (define spec (hash-ref slo 'spec))
     (check-equal? (hash-ref spec 'service) "authentication-service"))
   
   (test-case "Generate SLO with high availability"
     (define slo (generate-service-slo "critical-service" 99.999))
     
     (define spec (hash-ref slo 'spec))
     (define objectives (hash-ref spec 'objectives))
     (define objective (first objectives))
     (check-= (hash-ref objective 'value) 0.99999 0.00001)
     (check-equal? (hash-ref objective 'displayName) "99.999% Availability"))
   
   (test-case "Check Prometheus queries are generated correctly"
     (define slo (generate-service-slo "web-api" 99.0))
     
     (define spec (hash-ref slo 'spec))
     (define indicator (hash-ref spec 'indicator))
     (define indicator-spec (hash-ref indicator 'spec))
     (define ratio-metric (hash-ref indicator-spec 'ratioMetric))
     (define counter (hash-ref ratio-metric 'counter))
     
     ;; Check good query
     (define good (hash-ref counter 'good))
     (define good-query (hash-ref good 'query))
     (check-true (string-contains? good-query "web-api"))
     (check-true (string-contains? good-query "code!=\"5xx\""))
     (check-equal? (hash-ref good 'source) "prometheus")
     (check-equal? (hash-ref good 'queryType) "promql")
     
     ;; Check total query
     (define total (hash-ref counter 'total))
     (define total-query (hash-ref total 'query))
     (check-true (string-contains? total-query "web-api"))
     (check-false (string-contains? total-query "5xx")))
   
   (test-case "Generate complete OpenSLO from IR data"
     (define test-ir '(caffeine-program 
                       (service "api" 99.9 ("database"))
                       (service "database" 99.99 ())))
     
     (define complete-openslo (generate-complete-openslo test-ir))
     
     ;; Should have services, SLOs, alert policies, and notification target
     ;; 2 services + 2 SLOs + 2 alert policies + 1 notification target = 7 items
     (check-equal? (length complete-openslo) 7)
     
     ;; Check we have the right kinds - check each kind individually
     (define kinds (map (lambda (item) (hash-ref item 'kind)) complete-openslo))
     (check-true (> (length (filter (lambda (k) (equal? k "Service")) kinds)) 0))
     (check-true (> (length (filter (lambda (k) (equal? k "SLO")) kinds)) 0))
     (check-true (> (length (filter (lambda (k) (equal? k "AlertPolicy")) kinds)) 0))
     (check-true (> (length (filter (lambda (k) (equal? k "AlertNotificationTarget")) kinds)) 0)))
   
   (test-case "Generate from empty IR data"
     (define empty-openslo (generate-complete-openslo #f))
     (check-equal? empty-openslo '())
     
     ;; Test with empty caffeine-program - this will still generate notification target
     (define empty-openslo2 (generate-complete-openslo '(caffeine-program)))
     (check-equal? (length empty-openslo2) 1) ; Just the notification target
     (check-equal? (hash-ref (first empty-openslo2) 'kind) "AlertNotificationTarget"))
   
   (test-case "Generate service definition"
     (define service-def (generate-service-definition "user-service"))
     
     (check-equal? (hash-ref service-def 'apiVersion) "openslo/v1")
     (check-equal? (hash-ref service-def 'kind) "Service")
     
     (define metadata (hash-ref service-def 'metadata))
     (check-equal? (hash-ref metadata 'name) "user-service")
     (check-equal? (hash-ref metadata 'displayName) "user-service")
     
     (define spec (hash-ref service-def 'spec))
     (check-true (string-contains? (hash-ref spec 'description) "user-service")))
   
   (test-case "Generate alert policy"
     (define alert-policy (generate-alert-policy "payment-service"))
     
     (check-equal? (hash-ref alert-policy 'apiVersion) "openslo/v1")
     (check-equal? (hash-ref alert-policy 'kind) "AlertPolicy")
     
     (define metadata (hash-ref alert-policy 'metadata))
     (check-equal? (hash-ref metadata 'name) "payment-service-alert-policy")
     
     (define spec (hash-ref alert-policy 'spec))
     (check-equal? (hash-ref spec 'alertWhenBreaching) #t)
     (check-equal? (hash-ref spec 'alertWhenResolved) #t)
     (check-equal? (hash-ref spec 'alertWhenNoData) #t)
     
     (define conditions (hash-ref spec 'conditions))
     (check-equal? (length conditions) 1)
     (define condition (first conditions))
     (check-equal? (hash-ref condition 'conditionRef) "payment-service-availability-condition"))
   
   (test-case "YAML formatting basic test"
     (define simple-hash (hash 'name "test" 'value 42 'enabled #t))
     (define yaml-output (format-openslo-yaml (list simple-hash)))
     
     (check-true (string-contains? yaml-output "name:"))
     (check-true (string-contains? yaml-output "\"test\""))
     (check-true (string-contains? yaml-output "value:"))
     (check-true (string-contains? yaml-output "42"))
     (check-true (string-contains? yaml-output "enabled:"))
     (check-true (string-contains? yaml-output "true")))
   
   (test-case "Integration test with real IR data structure"
     (define real-ir '(caffeine-program 
                       (service "web-frontend" 99.95 ("api-gateway" "cdn"))
                       (service "api-gateway" 99.9 ("user-service" "order-service"))
                       (service "user-service" 99.5 ("database"))
                       (service "database" 99.99 ())))
     
     (define services (extract-services real-ir))
     (check-equal? services '("web-frontend" "api-gateway" "user-service" "database"))
     
     (define availabilities (extract-availabilities real-ir))
     (check-equal? availabilities '(99.95 99.9 99.5 99.99))
     
     (define openslo-specs (generate-openslo-from-ir real-ir))
     (check-equal? (length openslo-specs) 4)
     
     ;; Check first service
     (define first-slo (first openslo-specs))
     (define first-metadata (hash-ref first-slo 'metadata))
     (check-equal? (hash-ref first-metadata 'displayName) "web-frontend Availability SLO"))
   
   (test-case "Error handling for malformed service names"
     ;; Test with empty string
     (check-not-exn (lambda () (generate-service-slo "" 99.0)))
     
     ;; Test with special characters
     (check-not-exn (lambda () (generate-service-slo "service@#$%^&*()" 99.0)))
     
     ;; Test with very long name
     (define long-name (make-string 200 #\a))
     (check-not-exn (lambda () (generate-service-slo long-name 99.0))))
   
   (test-case "Availability edge cases"
     ;; Test with 0% availability - use approximate equality
     (define zero-slo (generate-service-slo "failing-service" 0))
     (define spec (hash-ref zero-slo 'spec))
     (define objectives (hash-ref spec 'objectives))
     (define objective (first objectives))
     (check-= (hash-ref objective 'value) 0.0 0.0001)
     
     ;; Test with 100% availability
     (define perfect-slo (generate-service-slo "perfect-service" 100))
     (define spec2 (hash-ref perfect-slo 'spec))
     (define objectives2 (hash-ref spec2 'objectives))
     (define objective2 (first objectives2))
     (check-= (hash-ref objective2 'value) 1.0 0.0001))))

;; Run the tests
(define (run-openslo-tests)
  (printf "Running OpenSLO Generator Tests...\n")
  (run-tests openslo-tests)
  (printf "OpenSLO tests completed.\n"))

;; Export test runner
(provide run-openslo-tests)

;; Run tests if this file is executed directly
(module+ main
  (run-openslo-tests)) 