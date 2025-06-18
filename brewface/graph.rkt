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
    
    ;; Calculate positions for nodes in a circular layout
    (define/private (calculate-node-positions)
      (define canvas-width (send this get-width))
      (define canvas-height (send this get-height))
      (define center-x (+ (/ canvas-width 2) offset-x))
      (define center-y (+ (/ canvas-height 2) offset-y))
      (define radius (min (/ canvas-width 3) (/ canvas-height 3)))
      (define node-count (length services))
      (define node-radius 30)
      
      (for/list ([i (in-range node-count)])
        (define angle (* 2 pi (/ i node-count)))
        (define x (+ center-x (* radius (cos angle))))
        (define y (+ center-y (* radius (sin angle))))
        (define service-name (list-ref services i))
        (define availability (list-ref availabilities i))
        (list x y service-name availability node-radius)))
    
    ;; Draw arrows between nodes
    (define/private (draw-arrows dc nodes)
      (send dc set-pen "gray" 2 'solid)
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
          
          ;; Draw arrow line
          (send dc draw-line start-x start-y end-x end-y)
          
          ;; Draw arrowhead
          (define arrow-size 10)
          (define arrow-angle (atan dy dx))
          (define arrow-x1 (+ end-x (* arrow-size (cos (+ arrow-angle pi 0.5)))))
          (define arrow-y1 (+ end-y (* arrow-size (sin (+ arrow-angle pi 0.5)))))
          (define arrow-x2 (+ end-x (* arrow-size (cos (- arrow-angle 0.5)))))
          (define arrow-y2 (+ end-y (* arrow-size (sin (- arrow-angle 0.5)))))
          
          (send dc draw-line end-x end-y arrow-x1 arrow-y1)
          (send dc draw-line end-x end-y arrow-x2 arrow-y2))))
    
    ;; Main paint method
    (define/override (on-paint)
      (define dc (send this get-dc))
      (send dc clear)
      
      ;; Set drawing properties
      (send dc set-pen "black" 2 'solid)
      
      ;; Calculate node positions
      (define nodes (calculate-node-positions))
      
      ;; Draw arrows first (so they appear behind nodes)
      (draw-arrows dc nodes)
      
      ;; Draw nodes with different colors for each service
      (for ([node nodes] [i (in-range (length nodes))])
        (define x (first node))
        (define y (second node))
        (define service-name (third node))
        (define availability (fourth node))
        (define node-radius (fifth node))
        (define color "lightblue")
        (define diameter (* node-radius 2))
        
        ;; Draw circle with unique color (uniform radius) - no border
        (send dc set-brush color 'solid)
        (send dc set-pen color 0 'transparent)  ; Remove black border by setting transparent pen
        (send dc draw-ellipse (- x node-radius) (- y node-radius) diameter diameter)
        
        ;; Reset pen to black for other drawing operations
        ; (send dc set-pen "black" 2 'solid)
        
        ;; Draw service name in yellow
        (send dc set-text-foreground "yellow")
        (send dc set-font (make-font #:size 10 #:weight 'bold))
        (define text-width (send dc get-text-width service-name))
        (define text-height (send dc get-text-height))
        (send dc draw-text service-name (- x (/ text-width 2)) (- y (/ text-height 2)))
        
        ;; Draw availability percentage below the service name
        (define avail-text (format "~a%" availability))
        (send dc set-text-foreground "black")
        (send dc set-font (make-font #:size 8))
        (define avail-width (send dc get-text-width avail-text))
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

