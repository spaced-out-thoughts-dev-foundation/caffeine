#lang racket

;; Export the file watching functions
(provide start-file-watcher stop-file-watcher)

;; Simple file watcher using polling
(define file-watchers (make-hash))

(define (start-file-watcher filepath callback [interval 1])
  "Start watching a file for changes and call callback when modified"
  (define watcher-thread
    (thread
      (lambda ()
        (define last-modified 
          (if (file-exists? filepath)
              (file-or-directory-modify-seconds filepath)
              0))
        (let loop ([prev-time last-modified])
          (sleep interval)
          (when (file-exists? filepath)
            (define current-time (file-or-directory-modify-seconds filepath))
            (when (> current-time prev-time)
              (callback filepath))
            (loop current-time))))))
  (hash-set! file-watchers filepath watcher-thread)
  watcher-thread)

(define (stop-file-watcher filepath)
  "Stop watching a file"
  (define watcher (hash-ref file-watchers filepath #f))
  (when watcher
    (kill-thread watcher)
    (hash-remove! file-watchers filepath))) 