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
(define show-graph-checkbox #f)
(define show-editor-checkbox #f)
(define show-openslo-checkbox #f)
(define show-ir-checkbox #f)
(define ir-canvas #f)
(define current-ir-data #f)

;; Dynamic layout containers
(define quadrant-container #f)
(define three-panel-container #f)
(define two-panel-container #f)
(define single-panel-container #f)

;; Panel content holders
(define graph-content #f)
(define editor-content #f)
(define openslo-content #f)
(define ir-content #f)

;; Function to parse and process caffeine data using ideal IR pattern
(define (process-caffeine-file)
  (if (file-exists? caffeine-file)
      (with-handlers ([exn:fail? (lambda (e) 
                                   (printf "DEBUG: Error in process-caffeine-file: ~a~n" e)
                                   (set! current-ir-data #f)
                                   (values '() '() '()))])
        ;; Step 1: Load caffeine file to get IR data
        (define ir-data (load-caffeine-file (path->string caffeine-file)))
        ;; Store IR data globally for IR panel display
        (set! current-ir-data ir-data)
        ;; Step 2: Process IR data to get structured results
        (process-ir-data ir-data))
      (begin
        (set! current-ir-data #f)
        (values '() '() '()))))

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
      (send graph-canvas update-graph service-names valid-dependencies service-availabilities))
    
    ;; Update the IR display
    (when ir-canvas
      (send ir-canvas refresh-ir))))

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
            
            ;; Update IR display
            (when ir-canvas
              (printf "DEBUG: Refreshing IR display~n")
              (send ir-canvas refresh-ir))
            
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
(define zen-border-color (make-color 60 60 60))  ; Border color for panel separation
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

;; Create flexible layout container instead of simple horizontal splitter
(define main-container (new vertical-panel%
                            [parent main-panel]
                            [stretchable-width #t]
                            [stretchable-height #t]
                            [style '()]))

;; Function to update panel visibility
(define (update-panel-visibility)
  (define show-graph (send show-graph-checkbox get-value))
  (define show-editor (send show-editor-checkbox get-value))
  (define show-openslo (send show-openslo-checkbox get-value))
  (define show-ir (send show-ir-checkbox get-value))
  
  ;; Count enabled panels
  (define enabled-panels (+ (if show-graph 1 0)
                           (if show-editor 1 0)
                           (if show-openslo 1 0)
                           (if show-ir 1 0)))
  
  ;; Clear existing layout
  (when quadrant-container
    (send main-container delete-child quadrant-container)
    (set! quadrant-container #f))
  (when three-panel-container
    (send main-container delete-child three-panel-container)
    (set! three-panel-container #f))
  (when two-panel-container
    (send main-container delete-child two-panel-container)
    (set! two-panel-container #f))
  (when single-panel-container
    (send main-container delete-child single-panel-container)
    (set! single-panel-container #f))
  
  ;; Create appropriate layout based on panel count
  (cond
    ;; 4 panels - quadrant layout
    [(= enabled-panels 4)
     (set! quadrant-container (new vertical-panel%
                                   [parent main-container]
                                   [stretchable-width #t]
                                   [stretchable-height #t]
                                   [style '(border)]
                                   [border 2]))
     
     (define upper-row (new horizontal-panel%
                           [parent quadrant-container]
                           [stretchable-width #t]
                           [stretchable-height #t]
                           [style '()]
                           [border 1]))
     
     ;; Add horizontal divider between upper and lower rows
     (define horizontal-divider (new canvas%
                                    [parent quadrant-container]
                                    [min-height 3]
                                    [stretchable-height #f]
                                    [paint-callback (lambda (canvas dc)
                                                      (send dc set-brush zen-border-color 'solid)
                                                      (define-values (w h) (send canvas get-size))
                                                      (send dc draw-rectangle 0 0 w h))]))
     
     (define lower-row (new horizontal-panel%
                           [parent quadrant-container]
                           [stretchable-width #t]
                           [stretchable-height #t]
                           [style '()]
                           [border 1]))
     
     ;; Create quadrant panels with borders
     (create-panel-content upper-row "Graph" show-graph graph-canvas #t #f)
     (create-panel-content upper-row "Editor" show-editor editor-canvas #t #f)
     (create-panel-content lower-row "OpenSLO" show-openslo #f #t #f)
     (create-panel-content lower-row "Intermediate Representation" show-ir #f #t #f)]
    
    ;; 3 panels - 2 upper, 1 lower expanded
    [(= enabled-panels 3)
     (set! three-panel-container (new vertical-panel%
                                      [parent main-container]
                                      [stretchable-width #t]
                                      [stretchable-height #t]
                                      [style '(border)]
                                      [border 2]))
     
     (define upper-half (new horizontal-panel%
                            [parent three-panel-container]
                            [stretchable-width #t]
                            [stretchable-height #t]
                            [style '()]
                            [border 1]))
     
     ;; Add horizontal divider
     (define horizontal-divider-3 (new canvas%
                                      [parent three-panel-container]
                                      [min-height 3]
                                      [stretchable-height #f]
                                      [paint-callback (lambda (canvas dc)
                                                        (send dc set-brush zen-border-color 'solid)
                                                        (define-values (w h) (send canvas get-size))
                                                        (send dc draw-rectangle 0 0 w h))]))
     
     (define lower-half (new horizontal-panel%
                            [parent three-panel-container]
                            [stretchable-width #t]
                            [stretchable-height #t]
                            [style '()]
                            [border 1]))
     
     ;; Add first two enabled panels to upper, third to lower
     (define enabled-list (filter (lambda (x) x)
                                 (list (if show-graph "Graph" #f)
                                       (if show-editor "Editor" #f)
                                       (if show-openslo "OpenSLO" #f)
                                       (if show-ir "Intermediate Representation" #f))))
     
     ;; Helper function to get content for panel
     (define (get-panel-content title)
       (cond
         [(string=? title "Graph") graph-canvas]
         [(string=? title "Editor") editor-canvas]
         [else #f]))
     
     (create-panel-content upper-half (first enabled-list) #t (get-panel-content (first enabled-list)) #t #f)
     (create-panel-content upper-half (second enabled-list) #t (get-panel-content (second enabled-list)) #t #f)
     (create-panel-content lower-half (third enabled-list) #t (get-panel-content (third enabled-list)) #t #f)]
    
    ;; 2 panels - side by side
    [(= enabled-panels 2)
     (set! two-panel-container (new horizontal-panel%
                                   [parent main-container]
                                   [stretchable-width #t]
                                   [stretchable-height #t]
                                   [style '(border)]
                                   [border 2]))
     
     (define enabled-list (filter (lambda (x) x)
                                 (list (if show-graph "Graph" #f)
                                       (if show-editor "Editor" #f)
                                       (if show-openslo "OpenSLO" #f)
                                       (if show-ir "Intermediate Representation" #f))))
     
     ;; Helper function to get content for panel
     (define (get-panel-content title)
       (cond
         [(string=? title "Graph") graph-canvas]
         [(string=? title "Editor") editor-canvas]
         [else #f]))
     
     (create-panel-content two-panel-container (first enabled-list) #t (get-panel-content (first enabled-list)) #t #f)
     (create-panel-content two-panel-container (second enabled-list) #t (get-panel-content (second enabled-list)) #t #f)]
    
    ;; 1 panel - full screen
    [(= enabled-panels 1)
     (set! single-panel-container (new vertical-panel%
                                      [parent main-container]
                                      [stretchable-width #t]
                                      [stretchable-height #t]
                                      [style '(border)]
                                      [border 2]))
     
     (cond
       [show-graph (create-panel-content single-panel-container "Graph" #t graph-canvas #t #t)]
       [show-editor (create-panel-content single-panel-container "Editor" #t editor-canvas #t #t)]
       [show-openslo (create-panel-content single-panel-container "OpenSLO" #t #f #t #t)]
       [show-ir (create-panel-content single-panel-container "Intermediate Representation" #t #f #t #t)])]
    
    ;; 0 panels - show nothing
    [else (void)]))

;; IR Display Canvas Class
(define ir-display-canvas%
  (class canvas%
    (super-new)
    
    ;; Override paint callback to display IR data
    (define/override (on-paint)
      (define dc (send this get-dc))
      (define-values (w h) (send this get-size))
      
      ;; Clear background
      (send dc set-brush zen-panel-color 'solid)
      (send dc draw-rectangle 0 0 w h)
      
      ;; Set text properties
      (send dc set-text-foreground zen-text-color)
      (send dc set-font (make-font #:size 12 #:family 'modern))
      
      (if current-ir-data
          (let ([line-height 16]
                [margin 10])
            ;; Display title
            (send dc set-font (make-font #:size 14 #:weight 'bold))
            (send dc draw-text "Roast Intermediate Representation" margin margin)
            
            ;; Display IR data
            (send dc set-font (make-font #:size 12 #:family 'modern))
            (let ([start-y (+ margin 30)]
                  [formatted-ir (format-ir-data current-ir-data)])
              (let ([formatted-lines (string-split formatted-ir "\n")])
                (for ([line formatted-lines] [i (in-range (length formatted-lines))])
                  (let ([y (+ start-y (* i line-height))])
                    (when (< y (- h 20)) ; Don't draw beyond canvas bounds
                      (send dc draw-text line margin y)))))))
          (let ([text "No IR Data Available"])
            ;; No data available
            (send dc set-font (make-font #:size 16 #:weight 'bold))
            (let-values ([(text-w text-h descent extra-space) (send dc get-text-extent text)])
              (let ([x (max 0 (/ (- w text-w) 2))]
                    [y (max 0 (/ (- h text-h) 2))])
                (send dc draw-text text x y))))))
    
    ;; Method to refresh the display
    (define/public (refresh-ir)
      (send this refresh-now))))

;; Helper function to format IR data for display
(define (format-ir-data ir-data)
  (if ir-data
      (with-output-to-string
        (lambda ()
          (pretty-print ir-data)))
      "No data"))

;; Helper function to create panel content
(define (create-panel-content parent title show? content [add-border #f] [fullscreen #f])
  (when show?
    (define panel (new vertical-panel%
                      [parent parent]
                      [stretchable-width #t]
                      [stretchable-height #t]
                      [style (if add-border '(border) '())]
                      [border (if add-border 1 0)]))
    
    ;; Only add title label if not in fullscreen mode
    (unless fullscreen
      (new message%
           [parent panel]
           [label title]
           [font (make-font #:size 14 #:weight 'bold)]))
    
    (cond
      [(string=? title "Graph")
       (when graph-canvas
         ;; Only reparent if not already a child of this panel
         (when (not (eq? (send graph-canvas get-parent) panel))
           (send graph-canvas reparent panel))
         ;; Ensure graph canvas fills the panel
         (send graph-canvas stretchable-width #t)
         (send graph-canvas stretchable-height #t)
         ;; Make sure it's visible
         (send graph-canvas show #t))]
      [(string=? title "Editor")
       (when editor-canvas
         ;; Only reparent if not already a child of this panel
         (when (not (eq? (send editor-canvas get-parent) panel))
           (send editor-canvas reparent panel))
         ;; Ensure editor canvas fills the panel
         (send editor-canvas stretchable-width #t)
         (send editor-canvas stretchable-height #t)
         ;; Make sure it's visible
         (send editor-canvas show #t))
       ;; Add editor buttons (only if not fullscreen to save space)
       (when (not fullscreen)
         (define button-panel (new horizontal-panel%
                                  [parent panel]
                                  [stretchable-height #f]
                                  [min-height 40]))
         (new button%
              [parent button-panel]
              [label "Load File"]
              [callback (lambda (button event) (load-file-to-editor))])
         (new button%
              [parent button-panel]
              [label "Save File"]
              [callback (lambda (button event) (save-editor-to-file))])
         (new button%
              [parent button-panel]
              [label "Refresh Graph"]
              [callback (lambda (button event) (update-display))]))]
      [(string=? title "Intermediate Representation")
       ;; Create or reparent IR canvas
       (unless ir-canvas
         (set! ir-canvas (new ir-display-canvas% [parent panel])))
       (when ir-canvas
         ;; Only reparent if not already a child of this panel
         (when (not (eq? (send ir-canvas get-parent) panel))
           (send ir-canvas reparent panel))
         ;; Ensure IR canvas fills the panel
         (send ir-canvas stretchable-width #t)
         (send ir-canvas stretchable-height #t)
         ;; Make sure it's visible
         (send ir-canvas show #t))]
      [else
       ;; Create placeholder content for OpenSLO/Intermediate Representation
       (new canvas%
            [parent panel]
            [stretchable-width #t]
            [stretchable-height #t]
            [paint-callback (lambda (canvas dc)
                              (define-values (w h) (send canvas get-size))
                              (send dc set-brush zen-panel-color 'solid)
                              (send dc draw-rectangle 0 0 w h)
                              (send dc set-text-foreground zen-text-color)
                              (send dc set-font (make-font #:size (if fullscreen 24 16) #:weight 'bold))
                              (define text (if fullscreen 
                                             (format "~a Panel - Full Screen Mode" title)
                                             (format "~a Panel - Coming Soon" title)))
                              (define-values (text-w text-h descent extra-space) (send dc get-text-extent text))
                              (define x (max 0 (/ (- w text-w) 2)))
                              (define y (max 0 (/ (- h text-h) 2)))
                              (send dc draw-text text x y))])])
    
         ;; Add vertical divider after panel (except for last panel in row and not in fullscreen)
     (when (and add-border (not fullscreen) (not (string=? title "Editor")) (not (string=? title "Intermediate Representation")))
      (new canvas%
           [parent parent]
           [min-width 3]
           [stretchable-width #f]
           [paint-callback (lambda (canvas dc)
                             (send dc set-brush zen-border-color 'solid)
                             (define-values (w h) (send canvas get-size))
                             (send dc draw-rectangle 0 0 w h))]))))

;; Create panels and their content

;; Graph canvas - will be reparented dynamically
(set! graph-canvas (new graph-canvas% 
                        [parent main-container]
                        [services service-names]
                        [dependencies valid-dependencies]
                        [availabilities service-availabilities]
                        [style '()]
                        [stretchable-width #t]
                        [stretchable-height #t]))

;; Hide the initial canvases so they only appear when properly placed
(send graph-canvas show #f)

;; Editor setup - will be reparented dynamically

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
                         [parent main-container]
                         [editor editor-text]
                         [style '()]
                         [stretchable-width #t]
                         [stretchable-height #t]))

;; Force the canvas background to be black
(send editor-canvas set-canvas-background zen-editor-bg)

;; Hide the initial editor canvas
(send editor-canvas show #f)

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

(set! show-openslo-checkbox (new check-box%
                                     [parent visibility-panel]
                                     [label "OpenSLO"]
                                     [value #t]
                                     [callback (lambda (checkbox event)
                                                 (update-panel-visibility))]))

(set! show-ir-checkbox (new check-box%
                        [parent visibility-panel]
                        [label "Intermediate Representation"]
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

;; Initialize the layout with all panels visible
(update-panel-visibility)

;; Show the frame
(send frame show #t) 