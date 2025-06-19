#lang racket

(provide generate-openslo-from-ir
         format-openslo-yaml
         generate-service-slo
         generate-complete-openslo
         generate-service-definition
         generate-alert-policy)

(require "parser.rkt")

;; Generate OpenSLO specifications from intermediate representation
(define (generate-openslo-from-ir ir-data)
  (if ir-data
      (let ([services (extract-services ir-data)]
            [availabilities (extract-availabilities ir-data)])
        (map generate-service-slo services availabilities))
      '()))

;; Generate a single SLO for a service
(define (generate-service-slo service-name availability)
  (define slo-name (format "~a-availability-slo" (string-replace service-name " " "-")))
  (define service-ref (string-replace service-name " " "-"))
  
  (hash 'apiVersion "openslo/v1"
        'kind "SLO"
        'metadata (hash 'name slo-name
                        'displayName (format "~a Availability SLO" service-name))
        'spec (hash 'description (format "Availability SLO for ~a service. Target: ~a% uptime. Note: This is auto-generated and may need adjustment based on actual monitoring setup." service-name availability)
                    'service service-ref
                    'indicator (hash 'metadata (hash 'name (format "~a-availability-indicator" service-ref)
                                                      'displayName (format "~a Availability Indicator" service-name))
                                     'spec (hash 'description (format "Measures availability of ~a service based on successful requests" service-name)
                                                 'ratioMetric (hash 'counter (hash 'good (hash 'source "prometheus"
                                                                                                 'queryType "promql"  
                                                                                                                                                                                                  'query (string-append "sum(rate(http_requests_total{service=\"" service-name "\",code!=\"5xx\"}[5m]))"))
                                                                                         'total (hash 'source "prometheus"
                                                                                                      'queryType "promql"
                                                                                                      'query (string-append "sum(rate(http_requests_total{service=\"" service-name "\"}[5m]))"))))))
                    'objectives (list (hash 'displayName (format "~a% Availability" availability)
                                            'op "gte"
                                            'value (/ availability 100.0)
                                            'target (/ availability 100.0)
                                            'timeWindow (list (hash 'duration "30d"
                                                                    'isRolling #t))
                                            'budgetAlerts (list (hash 'name (format "~a-budget-alert" service-ref)
                                                                      'burnRate (hash 'op "gte"
                                                                                      'threshold 2.0
                                                                                      'lookbackWindow "1h"
                                                                                      'alertAfter "5m")
                                                                      'notifications (list (hash 'target "slack"
                                                                                                  'description (format "Alert for ~a availability budget burn" service-name))))))))))

;; Generate Service definition for OpenSLO
(define (generate-service-definition service-name)
  (hash 'apiVersion "openslo/v1"
        'kind "Service" 
        'metadata (hash 'name (string-replace service-name " " "-")
                        'displayName service-name)
        'spec (hash 'description (format "Service definition for ~a - auto-generated from Caffeine DSL" service-name))))

;; Generate Alert Policy for a service
(define (generate-alert-policy service-name)
  (define service-ref (string-replace service-name " " "-"))
  (hash 'apiVersion "openslo/v1"
        'kind "AlertPolicy"
        'metadata (hash 'name (format "~a-alert-policy" service-ref)
                        'displayName (format "~a Alert Policy" service-name))
        'spec (hash 'description (format "Alert policy for ~a availability breaches - auto-generated" service-name)
                    'alertWhenBreaching #t
                    'alertWhenResolved #t 
                    'alertWhenNoData #t
                    'conditions (list (hash 'conditionRef (format "~a-availability-condition" service-ref)))
                    'notificationTargets (list (hash 'targetRef "default-notification-target")))))

;; Format OpenSLO data structure as YAML string
(define (format-openslo-yaml openslo-data)
  (string-join
   (map format-slo-as-yaml openslo-data)
   "\n---\n"))

;; Format a single SLO specification as YAML
(define (format-slo-as-yaml slo-spec)
  (define (format-value val indent)
    (cond
      [(string? val) (string-append "\"" val "\"")]
      [(number? val) (number->string val)]
      [(boolean? val) (if val "true" "false")]
      [(hash? val) 
       (string-join
        (hash-map val (lambda (key value)
                        (format "~a~a: ~a" 
                                (make-string indent #\space)
                                (symbol->string key)
                                (if (or (hash? value) (list? value))
                                    (format "\n~a" (format-value value (+ indent 2)))
                                    (format-value value 0)))))
        "\n")]
      [(list? val) 
       (string-join
        (map (lambda (item)
               (format "~a- ~a"
                       (make-string indent #\space)
                       (if (or (hash? item) (list? item))
                           (format "\n~a" (format-value item (+ indent 2)))
                           (format-value item 0))))
             val)
        "\n")]
      [else (format "~a" val)]))
  
  (format-value slo-spec 0))

;; Generate complete OpenSLO specification with all components
(define (generate-complete-openslo ir-data)
  (if ir-data
      (let ([services (extract-services ir-data)]
            [availabilities (extract-availabilities ir-data)])
        (append
         ;; Generate Service definitions
         (map generate-service-definition services)
         ;; Generate SLOs
         (map generate-service-slo services availabilities)
         ;; Generate Alert Policies  
         (map generate-alert-policy services)
         ;; Add default notification target
         (list (hash 'apiVersion "openslo/v1"
                     'kind "AlertNotificationTarget"
                     'metadata (hash 'name "default-notification-target"
                                     'displayName "Default Notification Target")
                     'spec (hash 'description "Default notification target for alerts - configure based on your monitoring setup"
                                 'target "slack")))))
      '())) 