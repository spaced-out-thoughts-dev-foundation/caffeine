#lang racket/gui

;; Brewface GUI - Service Dependency Graph Viewer
(require "graph.rkt")
(require "file-watcher.rkt")
(require "../roast/file-loader.rkt")
(require "../roast/main.rkt")
(require racket/date)
(require net/url)
(require net/sendurl)

;; Global variables
(define caffeine-file (build-path (current-directory) "example.cf"))
(define graph-canvas #f)
(define msg #f)
(define editor-text #f)
(define editor-canvas #f)
(define graph-panel #f)
(define editor-panel #f)
(define show-graph-checkbox #f)
(define show-editor-checkbox #f)

;; Function to parse and process caffeine data using ideal IR pattern
(define (process-caffeine-file)
  (if (file-exists? caffeine-file)
      (with-handlers ([exn:fail? (lambda (e) 
                                   (printf "DEBUG: Error in process-caffeine-file: ~a~n" e)
                                   (values '() '() '()))])
        ;; Step 1: Load caffeine file to get IR data
        (define ir-data (load-caffeine-file (path->string caffeine-file)))
        ;; Step 2: Process IR data to get structured results
        (process-ir-data ir-data))
      (values '() '() '())))

;; Function to load file content into editor
(define (load-file-to-editor)
  (when editor-text
    (if (file-exists? caffeine-file)
        (with-handlers ([exn:fail? (lambda (e) 
                                     (message-box "Error" 
                                                  (format "Failed to load file: ~a" e) 
                                                  frame))])
          (define content (file->string caffeine-file))
          (send editor-text erase)
          (send editor-text insert content)
          ;; Reapply Zen styling after loading content
          (when (and editor-text (send editor-text get-style-list))
            (define style-list (send editor-text get-style-list))
            (define zen-style (send style-list find-or-create-style
                                   (send style-list basic-style)
                                   zen-delta))
            (send editor-text change-style zen-style 0 (send editor-text last-position))))
        (begin
          (send editor-text erase)
          (let ([zen-content "# Zen SRE Studio

Research Icon Current research 

About Icon About Us 

Welcome to Zen SRE Studio - your gateway to mindful Site Reliability Engineering practices.

## Current Research

We are exploring innovative approaches to:
- Mindful incident response and post-mortem practices
- Zen-inspired monitoring and observability patterns  
- Contemplative approaches to system design and architecture
- Stress-free deployment and release management
- Balanced on-call practices that prioritize engineer wellbeing

## About Us

Zen SRE Studio represents a paradigm shift in how we approach reliability engineering.
We believe that sustainable, reliable systems emerge from balanced, mindful practices
rather than reactive, stress-driven methodologies.

Our philosophy centers on:
- **Mindful Monitoring**: Observing systems with intention and clarity
- **Compassionate Incident Response**: Handling outages with empathy and learning
- **Sustainable Practices**: Building reliability that doesn't burn out teams
- **Contemplative Design**: Creating systems through thoughtful, deliberate choices

Join us in exploring how ancient wisdom traditions can inform modern reliability practices.

# Example Caffeine File
# You can replace this content with your service definitions

service hello {
    availability 99.9%
}

service salad {
    availability 95.5%
}

service veggie {
    availability 98.2%
}

service authentication_service {
    availability 99.0%
}

# Define dependencies
hello -> salad
salad -> authentication_service
authentication_service -> salad  
authentication_service -> hello
authentication_service -> veggie
"])
            (send editor-text insert zen-content))
          ;; Reapply Zen styling after inserting default content
          (when (and editor-text (send editor-text get-style-list))
            (define style-list (send editor-text get-style-list))
            (define zen-style (send style-list find-or-create-style
                                   (send style-list basic-style)
                                   zen-delta))
            (send editor-text change-style zen-style 0 (send editor-text last-position)))))))

;; Function to save editor content to file
(define (save-editor-to-file)
  (when editor-text
    (with-handlers ([exn:fail? (lambda (e) 
                                 (message-box "Error" 
                                              (format "Failed to save file: ~a" e) 
                                              frame))])
      (define content (send editor-text get-text))
      (with-output-to-file caffeine-file
        (lambda () (display content))
        #:exists 'replace)
      (message-box "Success" "File saved successfully!" frame))))

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
              (printf "DEBUG: update-graph call completed~n"))
            
            ;; Reload editor content if file was changed externally
            (when editor-text
              (load-file-to-editor))))
        #f))))

;; Initial data processing
(define-values (service-names valid-dependencies service-availabilities) (process-caffeine-file))

;; Define colors to match Zen SRE Studio aesthetic
(define zen-bg-color (make-color 18 18 18))      ; Dark background
(define zen-panel-color (make-color 28 28 28))   ; Slightly lighter panels
(define zen-accent-color (make-color 0 122 255)) ; Blue accent
(define zen-text-color (make-color 255 255 255)) ; White text
;; Black background editor theme
(define zen-editor-bg (make-color 0 0 0))            ; Pure black background
(define zen-editor-text (make-color 255 255 255))    ; Pure white text
(define zen-editor-selection (make-color 50 50 50))  ; Dark gray selection
(define zen-editor-cursor (make-color 255 255 255))  ; White cursor
(define zen-editor-border (make-color 40 40 40))     ; Dark gray border

;; Create UI with Zen SRE Studio styling
(define frame (new frame% 
                   [label "Brewface - Service Dependency Graph | Powered by Zen SRE Studio"]
                   [width 1400]
                   [height 1000]))

(define main-panel (new vertical-panel% 
                        [parent frame]
                        [style '()]
                        [border 0]))

;; Function to update panel visibility
(define (update-panel-visibility)
  (define show-graph (send show-graph-checkbox get-value))
  (define show-editor (send show-editor-checkbox get-value))
  
  ;; Remove all panels from the layout first
  (with-handlers ([exn:fail? (lambda (e) (void))])
    (send splitter-panel delete-child graph-panel))
  (with-handlers ([exn:fail? (lambda (e) (void))])
    (send splitter-panel delete-child separator-panel))
  (with-handlers ([exn:fail? (lambda (e) (void))])
    (send splitter-panel delete-child editor-panel))
  
  (cond
    [(and show-graph show-editor)
     ;; Add both panels back with separator
     (send splitter-panel add-child graph-panel)
     (send splitter-panel add-child separator-panel)
     (send splitter-panel add-child editor-panel)]
    [show-graph
     ;; Add only graph panel - it will expand to full width
     (send splitter-panel add-child graph-panel)]
    [show-editor
     ;; Add only editor panel - it will expand to full width
     (send splitter-panel add-child editor-panel)]
    [else
     ;; Don't add any panels back (both hidden)
     (void)]))

;; Create horizontal splitter for graph and editor
(define splitter-panel (new horizontal-panel%
                            [parent main-panel]
                            [stretchable-width #t]
                            [stretchable-height #t]
                            [style '()]))

;; Left side - Graph
(set! graph-panel (new vertical-panel%
                       [parent splitter-panel]
                       [min-width 50]
                       [stretchable-width #t]
                       [style '()]))

(define graph-label (new message%
                         [parent graph-panel]
                         [label "Service Dependency Graph"]
                         [font (make-font #:size 14 #:weight 'bold)]))

(set! graph-canvas (new graph-canvas% 
                        [parent graph-panel]
                        [services service-names]
                        [dependencies valid-dependencies]
                        [availabilities service-availabilities]
                        [style '()]
                        [min-width 50]
                        [min-height 600]))

;; Add separator between graph and editor
(define separator-panel (new vertical-panel%
                             [parent splitter-panel]
                             [min-width 3]
                             [stretchable-width #f]
                             [style '()]))

;; Create separator visual element
(define separator-canvas (new canvas%
                              [parent separator-panel]
                              [min-width 3]
                              [paint-callback (lambda (canvas dc)
                                                (send dc set-brush (make-color 200 200 200) 'solid)
                                                (send dc draw-rectangle 0 0 3 800))]))

;; Right side - Text Editor
(set! editor-panel (new vertical-panel%
                        [parent splitter-panel]
                        [min-width 50]
                        [stretchable-width #t]
                        [style '()]))

(define editor-label (new message%
                          [parent editor-panel]
                          [label "Caffeine File Editor"]
                          [font (make-font #:size 14 #:weight 'bold)]))

;; Create text editor with proper styling according to Racket docs
(set! editor-text (new text%))

;; Enable basic features
(send editor-text set-max-undo-history 100)
(send editor-text auto-wrap #t)

;; Enable standard keyboard shortcuts (copy, paste, cut, undo, redo, select all)
(define keymap (new keymap%))
(send keymap add-function "copy" (lambda (text event) (send editor-text copy)))
(send keymap add-function "paste" (lambda (text event) (send editor-text paste)))
(send keymap add-function "cut" (lambda (text event) (send editor-text cut)))
(send keymap add-function "undo" (lambda (text event) (send editor-text undo)))
(send keymap add-function "redo" (lambda (text event) (send editor-text redo)))
(send keymap add-function "select-all" (lambda (text event) (send editor-text select-all)))

;; Bind standard hotkeys
(send keymap map-function "c:c" "copy")      ; Ctrl+C
(send keymap map-function "c:v" "paste")     ; Ctrl+V  
(send keymap map-function "c:x" "cut")       ; Ctrl+X
(send keymap map-function "c:z" "undo")      ; Ctrl+Z
(send keymap map-function "c:s:z" "redo")    ; Ctrl+Shift+Z (alternative to Ctrl+Y)
(send keymap map-function "c:y" "redo")      ; Ctrl+Y
(send keymap map-function "c:a" "select-all") ; Ctrl+A

;; Set the keymap for the editor
(send editor-text set-keymap keymap)

;; Create the proper style using Racket's style system
(define editor-style-list (new style-list%))
(send editor-text set-style-list editor-style-list)

;; Create style delta for Zen theme
(define zen-delta (new style-delta%))
(send zen-delta set-delta-background zen-editor-bg)
(send zen-delta set-delta-foreground zen-editor-text)
(send zen-delta set-family 'modern)
(send zen-delta set-size-add 2)

;; Create and apply the styled text style
(define zen-style (send editor-style-list find-or-create-style
                        (send editor-style-list basic-style)
                        zen-delta))

;; Apply style to all content
(send editor-text change-style zen-style 0 'end)

;; Create editor canvas with black background
(set! editor-canvas (new editor-canvas%
                         [parent editor-panel]
                         [editor editor-text]
                         [style '()]))

;; Force the canvas background to be black
(send editor-canvas set-canvas-background zen-editor-bg)

;; Editor button panel
(define editor-button-panel (new horizontal-panel%
                                 [parent editor-panel]
                                 [stretchable-height #f]
                                 [min-height 40]))

(define load-button (new button%
                         [parent editor-button-panel]
                         [label "Load File"]
                         [callback (lambda (button event)
                                     (load-file-to-editor))]))

(define save-button (new button%
                         [parent editor-button-panel]
                         [label "Save File"]
                         [callback (lambda (button event)
                                     (save-editor-to-file))]))

(define refresh-graph-button (new button%
                                  [parent editor-button-panel]
                                  [label "Refresh Graph"]
                                  [callback (lambda (button event)
                                              (update-display))]))

;; Create panel visibility controls
(define visibility-panel (new horizontal-panel%
                              [parent main-panel]
                              [stretchable-height #f]
                              [min-height 30]))

(define visibility-label (new message%
                              [parent visibility-panel]
                              [label "Show Panels: "]))

(set! show-graph-checkbox (new check-box%
                               [parent visibility-panel]
                               [label "Graph"]
                               [value #t]
                               [callback (lambda (checkbox event)
                                           (update-panel-visibility))]))

(set! show-editor-checkbox (new check-box%
                                [parent visibility-panel]
                                [label "Editor"]
                                [value #t]
                                [callback (lambda (checkbox event)
                                            (update-panel-visibility))]))

;; Create bottom panel for main buttons
(define button-panel (new horizontal-panel% 
                          [parent main-panel]
                          [stretchable-height #f]
                          [min-height 50]))

(define sync-button (new button%
                         [parent button-panel]
                         [label "Sync"]
                         [callback (lambda (button event)
                                     ;; Log the current parsed caffeine state
                                     (define-values (service-names valid-dependencies service-availabilities) (process-caffeine-file))
                                     (printf "DEBUG sync: services=~a (length=~a)~n" service-names (length service-names))
                                     (printf "DEBUG sync: dependencies=~a (length=~a)~n" valid-dependencies (length valid-dependencies))
                                     (printf "DEBUG sync: availabilities=~a (length=~a)~n" service-availabilities (length service-availabilities))
                                     (message-box "Sync" "Sync operation will be available soon for infrastructure as code deployment." frame))]))

(define close-button (new button%
                          [parent button-panel]
                          [label "Close"]
                          [callback (lambda (button event)
                                      (stop-file-watcher (path->string caffeine-file))
                                      (send frame show #f))]))

;; Zen SRE Studio navigation button
(define zen-visit-button (new button%
                              [parent button-panel]
                              [label "🧘 Zen SRE Studio →"]
                              [callback (lambda (button event)
                                          (send-url "https://zen.sre.studio/"))]))

;; Load initial file content
(load-file-to-editor)

;; Start file watching
(start-file-watcher (path->string caffeine-file) on-file-changed 0.5)

;; Show the frame
(send frame show #t) 