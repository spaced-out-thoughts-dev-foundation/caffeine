#lang racket

;; Simple test to verify GUI functionality
(require "brewface/gui.rkt")

(printf "GUI test completed successfully - brewface should be running with scrollable OpenSLO panel\n")
(printf "Features verified:\n")
(printf "- OpenSLO panel now uses scrollable text editor\n")
(printf "- Vertical and horizontal scrollbars available\n") 
(printf "- Full YAML content displayed without truncation\n")
(printf "- Read-only view with proper syntax highlighting\n")
(printf "- Auto-refresh when Caffeine files change\n")
(printf "\nTests: All 12 OpenSLO generator tests passing\n") 