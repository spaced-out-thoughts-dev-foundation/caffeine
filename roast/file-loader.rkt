#lang racket

(require racket/string)
(require racket/file)
(require racket/random)
(require "../caffeine/main.rkt")

(provide load-caffeine-file)

;; Load and parse a caffeine file, returning intermediate representation
(define (load-caffeine-file cf-file-path)
  (printf "DEBUG load-caffeine-file: parsing file ~a~n" cf-file-path)
  ;; Force fresh parsing by clearing any potential caches
  (collect-garbage)
  
  ;; Force a completely fresh parse by creating a unique temporary file
  (define temp-name (format "temp-parse-~a-~a.cf" (current-milliseconds) (random 10000)))
  (define temp-path (build-path (current-directory) temp-name))
  
  ;; Copy file contents to temp file
  (define file-contents (file->string cf-file-path))
  (printf "DEBUG load-caffeine-file: file contents length=~a~n" (string-length file-contents))
  (with-output-to-file temp-path
    (lambda () (display file-contents))
    #:exists 'replace)
  
  ;; Parse the temp file
  (define parsed-data (dynamic-require temp-path 'parsed-data))
  (printf "DEBUG load-caffeine-file: parsed-data=~a~n" parsed-data)
  
  ;; Clean up
  (with-handlers ([exn:fail? (lambda (e) (void))])
    (delete-file temp-path))
  
  parsed-data) 