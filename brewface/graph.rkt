#lang racket/gui
(require racket/string)
(require racket/file)
(require racket/random)
(require "../caffeine/main.rkt")
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
    (super-new)
    
    ;; Initialize data - either from parameters or by parsing cf file
    (cond
      [services 
       ;; Use provided parameters
       (set! services services)
       (set! dependencies (or dependencies '((0 1) (1 2))))
       (set! availabilities (or availabilities '(99.9 95.5 98.2)))]
      [cf-file-path 
       ;; Parse from cf file
       (define-values (s d a) (create-graph-from-cf cf-file-path))
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
    (define/public (update-graph new-services new-dependencies [new-availabilities '()])
      (printf "DEBUG update-graph: received services=~a, deps=~a, avail=~a~n" 
              new-services new-dependencies new-availabilities)
      (set! services new-services)
      (set! dependencies new-dependencies)
      (when (not (null? new-availabilities))
        (set! availabilities new-availabilities))
      (printf "DEBUG update-graph: after setting - services=~a, deps=~a, avail=~a~n" 
              services dependencies availabilities)
      (printf "DEBUG update-graph: calling refresh~n")
      (send this refresh)
      (printf "DEBUG update-graph: refresh completed~n"))
    
    ;; Calculate positions and uniform radius for all nodes
    (define (calculate-positions services)
      (define num-services (length services))
      (if (= num-services 0)
          '()
          (let ([center-x (+ 400 offset-x)]
                [center-y (+ 300 offset-y)]
                [layout-radius (min 250 (max 150 (* 50 num-services)))])
            
            ;; First pass: calculate all individual radii to find the maximum
            (define temp-bitmap (make-bitmap 1 1))
            (define temp-dc (new bitmap-dc% [bitmap temp-bitmap]))
            
            (define individual-radii
              (for/list ([i (in-range num-services)])
                (define service-name (list-ref services i))
                (define availability (if (< i (length availabilities))
                                         (list-ref availabilities i)
                                         99.0))
                (define label (string-append service-name "\n" (number->string availability) "%"))
                (define-values (w h d v) (send temp-dc get-text-extent label))
                (max 25 (+ (max (/ w 2) (/ h 2)) 10))))
            
            ;; Find the maximum radius
            (define max-radius (apply max individual-radii))
            
            ;; Second pass: create nodes with uniform radius
            (for/list ([i (in-range num-services)])
              (define angle (* 2 pi (/ i num-services)))
              (define x (+ center-x (* layout-radius (cos angle))))
              (define y (+ center-y (* layout-radius (sin angle))))
              (define service-name (list-ref services i))
              (define availability (if (< i (length availabilities))
                                       (list-ref availabilities i)
                                       99.0))
              
              (list x y service-name availability max-radius)))))
    
    ;; Override the on-paint method to draw our graph
    (define/override (on-paint)
      (define dc (send this get-dc))
      
      ;; Clear the canvas
      (send dc clear)
      
      ;; Debug painting
      (printf "DEBUG on-paint: services=~a (length=~a)~n" services (length services))
      (printf "DEBUG on-paint: dependencies=~a (length=~a)~n" dependencies (length dependencies))
      (printf "DEBUG on-paint: availabilities=~a (length=~a)~n" availabilities (length availabilities))
      
      ;; Draw a dramatic background color based on number of services
      (define bg-color "white")
      (send dc set-brush bg-color 'solid)
      (send dc draw-rectangle 0 0 1200 800)
      
      ;; Set drawing properties
      (send dc set-pen "black" 2 'solid)
      (send dc set-brush "lightblue" 'solid)
      
      ;; Calculate node positions
      (define nodes (calculate-positions services))
      (printf "DEBUG on-paint: calculated ~a nodes~n" (length nodes))
      
      ;; Draw edges first (so they appear behind nodes)
      (send dc set-pen "black" 2 'solid)
      (for ([edge dependencies])
        (when (and (< (first edge) (length nodes))
                   (< (second edge) (length nodes)))
          (define from-node (list-ref nodes (first edge)))
          (define to-node (list-ref nodes (second edge)))
          (define from-x (first from-node))
          (define from-y (second from-node))
          (define to-x (first to-node))
          (define to-y (second to-node))
          (define to-radius (fifth to-node))
          
          ;; Draw line
          (send dc draw-line from-x from-y to-x to-y)
          
          ;; Draw arrowhead
          (define dx (- to-x from-x))
          (define dy (- to-y from-y))
          (define length (sqrt (+ (* dx dx) (* dy dy))))
          (when (> length 0)
            (define unit-x (/ dx length))
            (define unit-y (/ dy length))
            
            ;; Arrowhead points
            (define arrow-length 30)
            (define arrow-width 10)
            (define tip-x (- to-x (* unit-x to-radius))) ; Stop before node edge (dynamic radius)
            (define tip-y (- to-y (* unit-y to-radius)))
            (define left-x (- tip-x (* unit-x arrow-length) (* unit-y arrow-width)))
            (define left-y (- tip-y (* unit-y arrow-length) (- (* unit-x arrow-width))))
            (define right-x (- tip-x (* unit-x arrow-length) (- (* unit-y arrow-width))))
            (define right-y (- tip-y (* unit-y arrow-length) (* unit-x arrow-width)))
            
            (send dc draw-polygon (list (cons tip-x tip-y)
                                        (cons left-x left-y)
                                        (cons right-x right-y))))))
      
      ;; Draw nodes with different colors for each service
      (for ([node nodes] [i (in-range (length nodes))])
        (define x (first node))
        (define y (second node))
        (define service-name (third node))
        (define availability (fourth node))
        (define node-radius (fifth node))
        (define color "lightblue")
        (define diameter (* node-radius 2))
        
        ;; Draw circle with unique color (uniform radius)
        (send dc set-brush color 'solid)
        (send dc draw-ellipse (- x node-radius) (- y node-radius) diameter diameter)
        
        ;; Draw black border
        (send dc set-pen "black" 2 'solid)
        (send dc set-brush "transparent" 'solid)
        (send dc draw-ellipse (- x node-radius) (- y node-radius) diameter diameter)
        
        ;; Draw service name in yellow
        (send dc set-text-foreground "yellow")
        (define-values (service-w service-h service-d service-v) (send dc get-text-extent service-name))
        
        ;; Draw availability percentage in red
        (define availability-text (string-append (number->string availability) "%"))
        (send dc set-text-foreground "red")
        (define-values (avail-w avail-h avail-d avail-v) (send dc get-text-extent availability-text))
        
        ;; Position text vertically centered with service name above availability
        (define total-height (+ service-h avail-h 5)) ; 5 pixels spacing between lines
        (define service-y (- y (/ total-height 2)))
        (define avail-y (+ service-y service-h 5))
        
        ;; Draw service name
        (send dc set-text-foreground "yellow")
        (send dc draw-text service-name (- x (/ service-w 2)) service-y)
        
        ;; Draw availability
        (send dc set-text-foreground "red")
        (send dc draw-text availability-text (- x (/ avail-w 2)) avail-y)))
    
    ;; Mouse event handlers for dragging
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

;; Function to create graph data from caffeine .cf file
(define (create-graph-from-cf cf-file-path)
  (printf "DEBUG create-graph-from-cf: parsing file ~a~n" cf-file-path)
  ;; Force fresh parsing by clearing any potential caches
  (collect-garbage)
  
  ;; Force a completely fresh parse by creating a unique temporary file
  (define temp-name (format "temp-graph-~a-~a.cf" (current-milliseconds) (random 10000)))
  (define temp-path (build-path (current-directory) temp-name))
  
  ;; Copy file contents to temp file
  (define file-contents (file->string cf-file-path))
  (printf "DEBUG create-graph-from-cf: file contents length=~a~n" (string-length file-contents))
  (with-output-to-file temp-path
    (lambda () (display file-contents))
    #:exists 'replace)
  
  ;; Parse the temp file
  (define parsed-data (dynamic-require temp-path 'parsed-data))
  (printf "DEBUG create-graph-from-cf: parsed-data=~a~n" parsed-data)
  
  ;; Clean up
  (with-handlers ([exn:fail? (lambda (e) (void))])
    (delete-file temp-path))
  
  (define services-data (cdr parsed-data)) ; Skip 'caffeine-program
  
  ;; Extract service names, availabilities, and build dependency mapping
  (define service-names (map cadr services-data))
  (define availabilities (map caddr services-data))
  
  ;; Create service name to index mapping
  (define name-to-index (make-hash))
  (for ([name service-names] [i (in-range (length service-names))])
    (hash-set! name-to-index name i))
  
  ;; Build dependencies list as (from-index to-index) pairs
  (define dependencies
    (apply append
           (for/list ([service-data services-data] [from-idx (in-range (length service-names))])
             (define deps (cadddr service-data))
             (filter (lambda (x) x)  ; Remove #f values
               (for/list ([dep deps])
                 (define to-idx (hash-ref name-to-index dep #f))
                 (if to-idx
                     (list from-idx to-idx)
                     (begin
                       (printf "DEBUG: Skipping unknown dependency: ~a~n" dep)
                       #f)))))))
  
  (values service-names dependencies availabilities))

