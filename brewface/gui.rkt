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
(define editor-text #f)
(define editor-canvas #f)
(define abstraction-slider #f)
(define current-abstraction-level 3) ; 0=Graph, 1=Editor, 2=IR, 3=OpenSLO
(define ir-canvas #f)
(define openslo-canvas #f)
(define current-ir-data #f)

;; Dynamic layout container
(define single-panel-container #f)

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
      (send ir-canvas refresh-ir))
    
    ;; Update the OpenSLO display
    (when openslo-canvas
      (send openslo-canvas refresh-openslo))))

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
            
            ;; Update OpenSLO display
            (when openslo-canvas
              (printf "DEBUG: Refreshing OpenSLO display~n")
              (send openslo-canvas refresh-openslo))
            
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

;; Function to update display layout based on abstraction level
(define (update-display-layout)
  ;; Clear existing layout
  (when single-panel-container
    (send main-container delete-child single-panel-container)
    (set! single-panel-container #f))
  
  ;; Create single full-screen panel based on abstraction level
  (set! single-panel-container (new vertical-panel%
                                   [parent main-container]
                                   [stretchable-width #t]
                                   [stretchable-height #t]
                                   [style '(border)]
                                   [border 2]))
  
  (cond
    ;; Level 3 - Graph (most abstracted)
    [(= current-abstraction-level 3)
     (create-panel-content single-panel-container "Graph" #t #t #t)]
    
    ;; Level 2 - Editor
    [(= current-abstraction-level 2)
     (create-panel-content single-panel-container "Editor" #t #t #t)]
    
    ;; Level 1 - Intermediate Representation
    [(= current-abstraction-level 1)
     (create-panel-content single-panel-container "Intermediate Representation" #t #t #t)]
    
    ;; Level 0 - OpenSLO (least abstracted)
    [(= current-abstraction-level 0)
     (create-panel-content single-panel-container "OpenSLO" #t #t #t)]
    
    ;; Default to OpenSLO
    [else
     (set! current-abstraction-level 0)
     (create-panel-content single-panel-container "OpenSLO" #t #t #t)]))

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

;; OpenSLO Display Canvas Class - now using scrollable text editor
(define openslo-display-canvas%
  (class vertical-panel%
    (super-new)
    
    ;; Create text editor for OpenSLO content
    (define openslo-text (new text%))
    (send openslo-text set-max-undo-history 0) ; Read-only, no undo needed
    (send openslo-text auto-wrap #f) ; Don't wrap YAML content
    (send openslo-text lock #t) ; Make it read-only
    
    ;; Create style for OpenSLO text
    (define openslo-style-list (new style-list%))
    (send openslo-text set-style-list openslo-style-list)
    
    ;; Create style delta for OpenSLO theme
    (define openslo-delta (new style-delta%))
    (send openslo-delta set-delta-background zen-panel-color)
    (send openslo-delta set-delta-foreground zen-text-color)
    (send openslo-delta set-family 'modern)
    (send openslo-delta set-size-add 0)
    
    ;; Create and apply the styled text style
    (define openslo-style (send openslo-style-list find-or-create-style
                                (send openslo-style-list basic-style)
                                openslo-delta))
    
    ;; Apply style to all content
    (send openslo-text change-style openslo-style 0 'end)
    
    ;; Create editor canvas with scrollbars
    (define openslo-editor-canvas (new editor-canvas%
                                       [parent this]
                                       [editor openslo-text]
                                       [style '(no-border auto-vscroll auto-hscroll)]
                                       [stretchable-width #t]
                                       [stretchable-height #t]))
    
    ;; Set the background color
    (send openslo-editor-canvas set-canvas-background zen-panel-color)
    
    ;; Method to refresh the display
    (define/public (refresh-openslo)
      (send openslo-text lock #f) ; Temporarily unlock for editing
      (send openslo-text erase) ; Clear current content
      
      (if current-ir-data
          (let ([openslo-specs (generate-complete-openslo current-ir-data)])
            ;; Add header information
            (send openslo-text insert "# Generated OpenSLO Specifications\n")
            (send openslo-text insert "# Note: Auto-generated from Caffeine DSL - may need adjustment for actual monitoring setup\n")
            (send openslo-text insert "# This is a read-only view. Use scroll bars to navigate through the content.\n\n")
            
            ;; Add the YAML content
            (let ([formatted-yaml (format-openslo-yaml openslo-specs)])
              (send openslo-text insert formatted-yaml)))
          (begin
            ;; No data available
            (send openslo-text insert "# No OpenSLO Data Available\n")
            (send openslo-text insert "# Load a Caffeine DSL file to generate OpenSLO specifications.\n")))
      
      ;; Apply styling to all content
      (send openslo-text change-style openslo-style 0 'end)
      (send openslo-text lock #t) ; Lock again for read-only access
      (send openslo-text set-position 0)) ; Scroll to top
    
    ;; Initialize with current data
    (refresh-openslo)))

;; Helper function to format IR data for display
(define (format-ir-data ir-data)
  (if ir-data
      (with-output-to-string
        (lambda ()
          (pretty-print ir-data)))
      "No data"))

;; Helper function to create panel content
(define (create-panel-content parent title show? [add-border #f] [fullscreen #f])
  (when show?
    (define panel (new vertical-panel%
                      [parent parent]
                      [stretchable-width #t]
                      [stretchable-height #t]
                      [style (if add-border '(border) '())]
                      [border (if add-border 1 0)]
                      [spacing 0]
                      [alignment '(left top)]))
    
    ;; Add title label for all views except Graph (to maximize graph space)
    (when (not (string=? title "Graph"))
      (new message%
           [parent panel]
           [label title]
           [font (make-font #:size (if fullscreen 18 14) #:weight 'bold)]
           [stretchable-height #f]
           [stretchable-width #f]))
    
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
         (send graph-canvas show #t)
         ;; Force immediate layout refresh for the graph canvas
         (send panel reflow-container)
         ;; Queue an immediate refresh to ensure proper sizing
         (queue-callback
          (lambda ()
            (send panel reflow-container)
            (send parent reflow-container)
            (send graph-canvas refresh-now)
            ;; Do one more reflow after a tiny delay
            (queue-callback
             (lambda ()
               (send panel reflow-container)
               (send parent reflow-container)
               (send main-container reflow-container)
               (send graph-canvas refresh-now))
             #f))
          #f))]
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
       ;; Add editor buttons for all modes
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
            [callback (lambda (button event) (update-display))])]
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
      [(string=? title "OpenSLO")
       ;; Create or reparent OpenSLO canvas
       (unless openslo-canvas
         (set! openslo-canvas (new openslo-display-canvas% [parent panel])))
       (when openslo-canvas
         ;; Only reparent if not already a child of this panel
         (when (not (eq? (send openslo-canvas get-parent) panel))
           (send openslo-canvas reparent panel))
         ;; Ensure OpenSLO canvas fills the panel
         (send openslo-canvas stretchable-width #t)
         (send openslo-canvas stretchable-height #t)
         ;; Make sure it's visible
         (send openslo-canvas show #t))]
      [else
       ;; Create placeholder content for unknown panels
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
                              (send dc draw-text text x y))])])))

;; Create panels and their content

;; Graph canvas - will be reparented dynamically
(set! graph-canvas (new graph-canvas% 
                        [parent main-container]
                        [services service-names]
                        [dependencies valid-dependencies]
                        [availabilities service-availabilities]
                        [style '()]
                        [stretchable-width #t]
                        [stretchable-height #t]
                        [min-width 800]
                        [min-height 600]))

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

;; Create abstraction slider control
(define abstraction-panel (new vertical-panel%
                               [parent main-panel]
                               [stretchable-height #f]
                               [min-height 60]
                               [border 5]))

(define slider-container (new vertical-panel%
                              [parent abstraction-panel]
                              [stretchable-height #f]
                              [alignment '(center center)]
                              [spacing 10]))

;; Add centered label above slider
(define abstraction-label (new message%
                               [parent slider-container]
                               [label "Abstraction Level"]
                               [font (make-font #:size 16 #:weight 'normal)]))

(define slider-row (new horizontal-panel%
                        [parent slider-container]
                        [stretchable-height #f]
                        [alignment '(center center)]))

;; Create custom blue slider with 4 positions (0-3) - no number display
(define blue-slider-canvas%
  (class canvas%
    (super-new)
    (init-field [min-val 0] [max-val 3] [init-val 0] [on-change (lambda (val) (void))])
    
    (define current-value init-val)
    (define slider-width 300)
    (define slider-height 20)
    (define handle-size 16)
    (define dragging #f)
    
    (define/public (get-value) current-value)
    (define/public (set-value val)
      (set! current-value (max min-val (min max-val val)))
      (send this refresh-now))
    
    (define/override (on-paint)
      (define dc (send this get-dc))
      (define-values (w h) (send this get-size))
      
      ;; Clear background
      (send dc set-brush zen-panel-color 'solid)
      (send dc draw-rectangle 0 0 w h)
      
      ;; Calculate positions
      (define track-y (/ h 2))
      (define track-left 20)
      (define track-right (- w 20))
      (define track-width (- track-right track-left))
      (define handle-x (+ track-left (* (/ current-value (- max-val min-val)) track-width)))
      
      ;; Draw track background (gray)
      (send dc set-pen zen-border-color 2 'solid)
      (send dc draw-line track-left track-y track-right track-y)
      
      ;; Draw blue fill from left to handle position (standard slider behavior)
      (send dc set-pen zen-accent-color 4 'solid)
      (send dc draw-line track-left track-y handle-x track-y)
      
      ;; Draw handle
      (send dc set-brush zen-accent-color 'solid)
      (send dc set-pen zen-accent-color 1 'solid)
      (send dc draw-ellipse (- handle-x (/ handle-size 2)) (- track-y (/ handle-size 2)) handle-size handle-size))
    
    (define/override (on-event event)
      (define-values (w h) (send this get-size))
      (define track-left 20)
      (define track-right (- w 20))
      (define track-width (- track-right track-left))
      
      (cond
        [(send event button-down? 'left)
         (set! dragging #t)
         (define x (send event get-x))
         (define new-val (round (* (/ (- x track-left) track-width) (- max-val min-val))))
         (set! current-value (max min-val (min max-val new-val)))
         (on-change current-value)
         (send this refresh-now)]
        [(and dragging (send event dragging?))
         (define x (send event get-x))
         (define new-val (round (* (/ (- x track-left) track-width) (- max-val min-val))))
         (set! current-value (max min-val (min max-val new-val)))
         (on-change current-value)
         (send this refresh-now)]
        [(send event button-up? 'left)
         (set! dragging #f)]))))

(set! abstraction-slider (new blue-slider-canvas%
                              [parent slider-row]
                              [min-width 300]
                              [min-height 30]
                              [stretchable-width #f]
                              [stretchable-height #f]
                              [min-val 0]
                              [max-val 3]
                              [init-val 3]
                              [on-change (lambda (val)
                                          (set! current-abstraction-level val)
                                          (update-display-layout))]))

;; Add level labels directly beneath slider with bidirectional arrows
(define level-labels-panel (new horizontal-panel%
                                [parent slider-container]
                                [stretchable-height #f]
                                [alignment '(center center)]
                                [min-width 300]
                                [stretchable-width #f]))

(new message% [parent level-labels-panel] [label "OpenSLO"])
(new message% [parent level-labels-panel] [label " ↔ "])
(new message% [parent level-labels-panel] [label "IR"])
(new message% [parent level-labels-panel] [label " ↔ "])
(new message% [parent level-labels-panel] [label "Editor"])
(new message% [parent level-labels-panel] [label " ↔ "])
(new message% [parent level-labels-panel] [label "Graph"])

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

;; Initialize the layout with the default abstraction level
(update-display-layout)

;; Do the layout fix BEFORE showing the frame to minimize visual glitch
;; Simulate changing to a different view and back to graph
(set! current-abstraction-level 2) ; Switch to Editor
(update-display-layout)
(set! current-abstraction-level 3) ; Switch back to Graph
(update-display-layout)

;; Now show the frame after layout is fixed
(send frame show #t) 