#lang racket/gui

;; Export the graph-canvas% class
(provide graph-canvas%)

;; Create a custom canvas class for drawing the directed graph
(define graph-canvas%
  (class canvas%
    (init-field [services '("A" "B" "C")]
                [dependencies '((0 1) (1 2))])
    (super-new)
    
    ;; Method to update the graph data and refresh
    (define/public (update-graph new-services new-dependencies)
      (set! services new-services)
      (set! dependencies new-dependencies)
      (send this refresh))
    
    ;; Calculate positions for nodes in a circular layout
    (define (calculate-positions services)
      (define num-services (length services))
      (if (= num-services 0)
          '()
          (let ([center-x 250]
                [center-y 200]
                [radius (min 100 (max 50 (* 20 num-services)))])
            
            (for/list ([i (in-range num-services)])
              (define angle (* 2 pi (/ i num-services)))
              (define x (+ center-x (* radius (cos angle))))
              (define y (+ center-y (* radius (sin angle))))
              (list x y (list-ref services i))))))
    
    ;; Override the on-paint method to draw our graph
    (define/override (on-paint)
      (define dc (send this get-dc))
      
      ;; Clear the canvas
      (send dc clear)
      
      ;; Draw a dramatic background color based on number of services
      (define bg-colors '("white" "lightred" "lightblue" "lightgreen" "lightyellow" "lightpink"))
      (define bg-color (list-ref bg-colors (min (length services) (- (length bg-colors) 1))))
      (send dc set-brush bg-color 'solid)
      (send dc draw-rectangle 0 0 600 500)
      
      ;; Set drawing properties
      (send dc set-pen "black" 2 'solid)
      (send dc set-brush "lightblue" 'solid)
      
      ;; Calculate node positions
      (define nodes (calculate-positions services))
      
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
            (define arrow-length 15)
            (define arrow-width 8)
            (define tip-x (- to-x (* unit-x 20))) ; Stop before node center
            (define tip-y (- to-y (* unit-y 20)))
            (define left-x (- tip-x (* unit-x arrow-length) (* unit-y arrow-width)))
            (define left-y (- tip-y (* unit-y arrow-length) (- (* unit-x arrow-width))))
            (define right-x (- tip-x (* unit-x arrow-length) (- (* unit-y arrow-width))))
            (define right-y (- tip-y (* unit-y arrow-length) (* unit-x arrow-width)))
            
            (send dc draw-polygon (list (cons tip-x tip-y)
                                        (cons left-x left-y)
                                        (cons right-x right-y))))))
      
      ;; Draw nodes with different colors for each service
      (define colors '("lightblue" "lightgreen" "lightcoral" "lightyellow" "lightpink" "lightcyan"))
      (for ([node nodes] [i (in-range (length nodes))])
        (define x (first node))
        (define y (second node))
        (define label (third node))
        (define color (list-ref colors (modulo i (length colors))))
        
        ;; Draw circle with unique color
        (send dc set-brush color 'solid)
        (send dc draw-ellipse (- x 25) (- y 25) 50 50)
        
        ;; Draw black border
        (send dc set-pen "black" 2 'solid)
        (send dc set-brush "transparent" 'solid)
        (send dc draw-ellipse (- x 25) (- y 25) 50 50)
        
        ;; Draw label
        (send dc set-text-foreground "black")
        (define-values (w h d v) (send dc get-text-extent label))
        (send dc draw-text label (- x (/ w 2)) (- y (/ h 2))))
      
      ;; Draw a count indicator in the corner
      (send dc set-text-foreground "red")
      (send dc draw-text (format "Services: ~a" (length services)) 10 10)
      
      ;; Draw a timestamp to show when last redrawn
      (send dc set-text-foreground "black")
      (send dc draw-text (format "Last drawn: ~a" (current-seconds)) 10 30))))