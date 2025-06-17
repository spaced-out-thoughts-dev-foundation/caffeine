#lang br/quicklang
(module reader br
  (require "lang/reader.rkt")
  (provide read-syntax))

;; Import required functions for file operations
(require racket/file racket/path)

;; Utility function to parse caffeine files and return structured data
(provide parse-caffeine-to-data)
(define (parse-caffeine-to-data filepath)
  "Parse a caffeine file and return structured data"
  (define path (string->path filepath))
  
  ;; Read the file contents directly
  (define file-contents (file->string path))
  
  ;; Create a temporary file with a unique name to avoid caching
  (define temp-name (format "temp-~a.cf" (current-milliseconds)))
  (define temp-path (build-path (current-directory) temp-name))
  
  (with-output-to-file temp-path
    (lambda () (display file-contents))
    #:exists 'replace)
  
  ;; Use dynamic-require on the temporary file
  (define result (dynamic-require temp-path 'parsed-data))
  
  ;; Clean up the temporary file
  (with-handlers ([exn:fail? (lambda (e) (void))])
    (delete-file temp-path))
  
  result)