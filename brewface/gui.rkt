#lang racket/gui

;; Brewface GUI - Service Dependency Graph Viewer
(require "graph.rkt")
(require "caffeine-parser.rkt")
(require "file-watcher.rkt")
(require racket/date)

;; Global variables
(define caffeine-file (build-path (current-directory) "example.cf"))
(define graph-canvas #f)
(define msg #f)

;; Function to parse and process caffeine data
(define (process-caffeine-file)
  (if (file-exists? caffeine-file)
      (let ([parsed-data #f]
            [service-names '()]
            [service-dependencies '()])
        
        (with-handlers ([exn:fail? (lambda (e) 
                                     (set! parsed-data '()))])
          (set! parsed-data (parse-caffeine-file (path->string caffeine-file))))
        
        (set! service-names (get-services parsed-data))
        (set! service-dependencies (get-dependencies parsed-data))
        
        ;; Convert service names to indices for the graph
        (define (service-name-to-index name)
          (for/first ([i (in-range (length service-names))]
                      [svc service-names]
                      #:when (string=? svc name))
            i))
        
        (define dependency-indices
          (for/list ([dep service-dependencies])
            (list (service-name-to-index (first dep))
                  (service-name-to-index (second dep)))))
        
        (define valid-dependencies
          (filter (lambda (dep) (and (car dep) (cadr dep))) dependency-indices))
        
        (values parsed-data service-names valid-dependencies))
      (values '() '() '())))

;; Function to update the display
(define (update-display)
  (with-handlers ([exn:fail? (lambda (e) (void))])
    (define-values (parsed-data service-names valid-dependencies) (process-caffeine-file))
    
    ;; Update the message
    (when msg
      (send msg set-label (format "Services: ~a (Updated: ~a)" 
                                 (length service-names)
                                 (date->string (current-date) #t))))
    
    ;; Update the graph
    (when graph-canvas
      (send graph-canvas update-graph service-names valid-dependencies))))

;; File change callback
(define (on-file-changed filepath)
  (thread
    (lambda ()
      (sleep 0.1) ;; Brief delay to ensure file write is complete
      (queue-callback 
        (lambda ()
          (with-handlers ([exn:fail? (lambda (e) (void))])
            ;; Parse and update
            (define-values (parsed-data service-names valid-dependencies) (process-caffeine-file))
            
            ;; Update message
            (when msg
              (send msg set-label (format "Services: ~a (Updated: ~a)" 
                                         (length service-names)
                                         (date->string (current-date) #t))))
            
            ;; Update graph
            (when graph-canvas
              (send graph-canvas update-graph service-names valid-dependencies))))
        #f))))

;; Initial data processing
(define-values (parsed-data service-names valid-dependencies) (process-caffeine-file))

;; Create UI
(define frame (new frame% 
                   [label "Brewface - Service Dependency Graph"]
                   [width 600]
                   [height 500]))

(define panel (new vertical-panel% [parent frame]))

(set! msg (new message% 
               [parent panel]
               [label (format "Services: ~a" (length service-names))]))

(set! graph-canvas (new graph-canvas% 
                        [parent panel]
                        [services service-names]
                        [dependencies valid-dependencies]
                        [min-width 500]
                        [min-height 400]))

(define close-button (new button%
                          [parent panel]
                          [label "Close"]
                          [callback (lambda (button event)
                                      (stop-file-watcher (path->string caffeine-file))
                                      (send frame show #f))]))

;; Start file watching
(start-file-watcher (path->string caffeine-file) on-file-changed 0.5)

;; Show the frame
(send frame show #t) 