#lang racket/gui
(require racket/string)
(require racket/file)
(require racket/random)
(require "../roast/file-loader.rkt")
(require "../roast/main.rkt")
(require "file-watcher.rkt")

;; Export the graph-canvas% class
(provide graph-canvas% create-graph-from-cf)

;; Create a custom canvas class for drawing the directed graph
(define graph-canvas%
  (class canvas%
    (init-field [services #f]
                [dependencies #f]
                [availabilities #f]
                [cf-file-path #f])
    (init [parent #f]
          [style '()]
          [min-width #f]
          [min-height #f])
    (super-new [parent parent]
               [style style]
               [min-width min-width]
               [min-height min-height])
    
    ;; Initialize data - either from parameters or by parsing cf file
    (cond
      [services 
       ;; Use provided parameters
       (set! services services)
       (set! dependencies (or dependencies '((0 1) (1 2))))
       (set! availabilities (or availabilities '(99.9 95.5 98.2)))]
      [cf-file-path 
       ;; Load and process cf file using ideal IR pattern
       (define ir-data (load-caffeine-file cf-file-path))
       (define-values (s d a) (process-ir-data ir-data))
       (set! services s)
       (set! dependencies d)
       (set! availabilities a)]
      [else 
       ;; Use defaults
       (set! services '("hello" "salad" "veggie" "authentication service"))
       (set! dependencies '((0 1) (1 3) (3 1) (3 0) (3 2)))
       (set! availabilities '(99.9 99.5 99.5 99))])
    
    ;; Fields for dragging
    (define offset-x 0)
    (define offset-y 0)
    (define dragging? #f)
    (define last-mouse-x 0)
    (define last-mouse-y 0)
    
    ;; Method to update the graph data and refresh
    (define/public (update-graph new-services new-dependencies new-availabilities)
      (set! services new-services)
      (set! dependencies new-dependencies)
      (set! availabilities new-availabilities)
      (send this refresh))
    
     
    
        ;; Calculate the required node radius based on the largest service name
    (define/private (calculate-required-node-radius)
      (define dc (send this get-dc))
      (define base-radius 35) ; minimum radius
      
      ;; Find the largest text dimensions across all services
      (define max-required-radius
        (for/fold ([current-max base-radius])
                  ([service services]
                   [availability availabilities])
                     ;; Measure service name
           (send dc set-font (make-font #:size 12 #:weight 'bold))
           (define-values (service-width service-height service-desc service-extra) (send dc get-text-extent service))
           
           ;; Measure availability text
           (send dc set-font (make-font #:size 10))
           (define avail-text (format "~a%" availability))
           (define-values (avail-width avail-height avail-desc avail-extra) (send dc get-text-extent avail-text))
          
          ;; Calculate required radius for this service (smaller relative to text)
          (define required-width (max service-width avail-width))
          (define required-height (+ service-height avail-height 10)) ; 10px spacing
          (define required-radius (+ (max (/ required-width 2.0) (/ required-height 2.0)) 15)) ; tighter padding
          
          (max current-max required-radius)))
      
      max-required-radius)
    
    ;; Calculate positions for nodes in a circular layout
    (define/private (calculate-node-positions)
      (define canvas-width (send this get-width))
      (define canvas-height (send this get-height))
      (define center-x (+ (/ canvas-width 2) offset-x))
      (define center-y (+ (/ canvas-height 2) offset-y))
      (define node-count (length services))
      (define node-radius (calculate-required-node-radius))
      
      ;; Make nodes MUCH further apart - very large circular layout radius
      (define max-radius (- (min (/ canvas-width 2) (/ canvas-height 2)) node-radius 50))
      (define radius (max 250 (min max-radius 400))) ; Between 250 and 400 pixels from center (HUGE spacing)
      
      (for/list ([i (in-range node-count)])
        (define angle (* 2 pi (/ i node-count)))
        (define x (+ center-x (* radius (cos angle))))
        (define y (+ center-y (* radius (sin angle))))
        (define service-name (list-ref services i))
        (define availability (list-ref availabilities i))
         
        (list x y service-name availability node-radius)))
    
        ;; Draw simple, visible arrows between nodes
    (define/private (draw-arrows dc nodes)
      (for ([dep dependencies])
        (define from-idx (first dep))
        (define to-idx (second dep))
        (when (and (< from-idx (length nodes)) (< to-idx (length nodes)))
          (define from-node (list-ref nodes from-idx))
          (define to-node (list-ref nodes to-idx))
          (define from-x (first from-node))
          (define from-y (second from-node))
          (define to-x (first to-node))
          (define to-y (second to-node))
          (define from-radius (fifth from-node))
          (define to-radius (fifth to-node))
          
          ;; Calculate arrow start and end points on circle edges
          (define dx (- to-x from-x))
          (define dy (- to-y from-y))
          (define distance (sqrt (+ (* dx dx) (* dy dy))))
          (define unit-dx (/ dx distance))
          (define unit-dy (/ dy distance))
          
          (define start-x (+ from-x (* unit-dx from-radius)))
          (define start-y (+ from-y (* unit-dy from-radius)))
          (define end-x (- to-x (* unit-dx to-radius)))
          (define end-y (- to-y (* unit-dy to-radius)))
          
          ;; Draw thick bright arrow line
          (send dc set-pen "yellow" 4 'solid)
          (send dc draw-line start-x start-y end-x end-y)
          
          ;; Draw filled triangular arrowhead
          (define arrow-length 18)
          (define arrow-width 12)
          (define arrow-angle (atan dy dx))
          
          ;; Calculate arrowhead triangle points
          (define arrow-tip-x end-x)
          (define arrow-tip-y end-y)
          
          ;; Calculate base of arrow (back from tip)
          (define arrow-base-x (+ end-x (* arrow-length (cos (+ arrow-angle pi)))))
          (define arrow-base-y (+ end-y (* arrow-length (sin (+ arrow-angle pi)))))
          
          ;; Calculate left and right points of arrow base
          (define perp-angle (+ arrow-angle (/ pi 2)))
          (define arrow-left-x (+ arrow-base-x (* (/ arrow-width 2) (cos perp-angle))))
          (define arrow-left-y (+ arrow-base-y (* (/ arrow-width 2) (sin perp-angle))))
          (define arrow-right-x (- arrow-base-x (* (/ arrow-width 2) (cos perp-angle))))
          (define arrow-right-y (- arrow-base-y (* (/ arrow-width 2) (sin perp-angle))))
          
          ;; Draw filled arrowhead triangle
          (send dc set-brush "yellow" 'solid)
          (send dc set-pen "yellow" 1 'solid)
          (define arrow-triangle (list (cons arrow-tip-x arrow-tip-y)
                                       (cons arrow-left-x arrow-left-y)
                                       (cons arrow-right-x arrow-right-y)))
          (send dc draw-polygon arrow-triangle))))
    
    ;; Main paint method
    (define/override (on-paint)
      (define dc (send this get-dc))
      
      ;; Get canvas dimensions
      (define canvas-width (send this get-width))
      (define canvas-height (send this get-height))
      
      ;; Set professional dark background inspired by Zen SRE Studio
      (send dc set-brush "#2C3E50" 'solid)
      (send dc set-pen "#2C3E50" 0 'transparent)
      (send dc draw-rectangle 0 0 canvas-width canvas-height)
      
      ;; Calculate node positions
      (define nodes (calculate-node-positions))
      
      ;; Draw arrows first (so they appear behind nodes)
      (draw-arrows dc nodes)
      
      ;; Draw nodes with professional color scheme
      (for ([node nodes] [i (in-range (length nodes))])
        (define x (first node))
        (define y (second node))
        (define service-name (third node))
        (define availability (fourth node))
        (define node-radius (fifth node))
        
                 ;; Draw circle with bright visible colors for debugging
         (send dc set-brush "blue" 'solid) ; Bright blue nodes
         (send dc set-pen "white" 3 'solid) ; White border
         (define diameter (* node-radius 2))

         (send dc draw-ellipse (- x node-radius) (- y node-radius) diameter diameter)
        
                 ;; Draw service name in white
         (send dc set-text-foreground "white")
         (send dc set-font (make-font #:size 12 #:weight 'bold))
        (define-values (text-width text-height descent extra-space) (send dc get-text-extent service-name))
        (send dc draw-text service-name (- x (/ text-width 2)) (- y (/ text-height 2)))
        
                 ;; Draw availability percentage below the service name
         (define avail-text (format "~a%" availability))
         (send dc set-text-foreground "green") ; Green for availability
         (send dc set-font (make-font #:size 10))
        (define-values (avail-width avail-height avail-descent avail-extra) (send dc get-text-extent avail-text))
        (send dc draw-text avail-text (- x (/ avail-width 2)) (+ y 5))))
    
    ;; Handle mouse events for dragging
    (define/override (on-event event)
      (cond
        [(send event button-down? 'left)
         (set! dragging? #t)
         (set! last-mouse-x (send event get-x))
         (set! last-mouse-y (send event get-y))]
        [(send event button-up? 'left)
         (set! dragging? #f)]
        [(and dragging? (send event dragging?))
         (define current-x (send event get-x))
         (define current-y (send event get-y))
         (set! offset-x (+ offset-x (- current-x last-mouse-x)))
         (set! offset-y (+ offset-y (- current-y last-mouse-y)))
         (set! last-mouse-x current-x)
         (set! last-mouse-y current-y)
         (send this refresh)])
      (super on-event event))))

;; Function to create graph data from caffeine .cf file using ideal IR pattern
(define (create-graph-from-cf cf-file-path)
  (printf "DEBUG create-graph-from-cf: using ideal IR pattern for file ~a~n" cf-file-path)
  ;; Step 1: Load caffeine file to get IR data
  (define ir-data (load-caffeine-file cf-file-path))
  ;; Step 2: Process IR data to get structured results
  (process-ir-data ir-data))

