#lang racket/gui

;; Brewface GUI - Service Dependency Graph Viewer
(require "graph.rkt")
(require "file-watcher.rkt")
(require racket/date)

;; Global variables
(define caffeine-file (build-path (current-directory) "example.cf"))
(define graph-canvas #f)
(define msg #f)

;; Function to parse and process caffeine data
(define (process-caffeine-file)
  (if (file-exists? caffeine-file)
      (with-handlers ([exn:fail? (lambda (e) 
                                   (printf "DEBUG: Error in process-caffeine-file: ~a~n" e)
                                   (values '() '() '()))])
        (create-graph-from-cf (path->string caffeine-file)))
      (values '() '() '())))

;; Function to update the display
(define (update-display)
  (with-handlers ([exn:fail? (lambda (e) (void))])
    (define-values (service-names valid-dependencies service-availabilities) (process-caffeine-file))
    
    ;; Update the graph
    (when graph-canvas
      (send graph-canvas update-graph service-names valid-dependencies service-availabilities))))

;; File change callback
(define (on-file-changed filepath)
  (printf "DEBUG: File changed detected: ~a~n" filepath)
  (thread
    (lambda ()
      (sleep 0.1) ;; Brief delay to ensure file write is complete
      (queue-callback 
        (lambda ()
          (printf "DEBUG: Processing file change in queue callback~n")
          (with-handlers ([exn:fail? (lambda (e) 
                                       (printf "DEBUG: Error during file change processing: ~a~n" e)
                                       (void))])
            ;; Parse and update
            (printf "DEBUG: About to parse file after change~n")
            (define-values (service-names valid-dependencies service-availabilities) (process-caffeine-file))
            (printf "DEBUG: Parsed after file change - services: ~a, deps: ~a, avail: ~a~n" 
                    service-names valid-dependencies service-availabilities)
            
            ;; Update graph
            (when graph-canvas
              (printf "DEBUG: Calling update-graph with new data~n")
              (send graph-canvas update-graph service-names valid-dependencies service-availabilities)
              (printf "DEBUG: update-graph call completed~n"))))
        #f))))

;; Initial data processing
(define-values (service-names valid-dependencies service-availabilities) (process-caffeine-file))

;; Create UI
(define frame (new frame% 
                   [label "Brewface - Service Dependency Graph"]
                   [width 1200]
                   [height 800]))

(define panel (new vertical-panel% [parent frame]))

(set! graph-canvas (new graph-canvas% 
                        [parent panel]
                        [services service-names]
                        [dependencies valid-dependencies]
                        [availabilities service-availabilities]
                        [min-width 1100]
                        [min-height 700]))

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