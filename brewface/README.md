# Brewface

A GUI application built with Racket that dynamically visualizes service dependency graphs from caffeine files.

## Requirements

- [Racket](https://racket-lang.org/) installed on your system
- The `gui-lib` package (usually included with standard Racket installations)

## File Structure

- `gui.rkt` - Main GUI application with real-time file watching
- `graph.rkt` - Dynamic graph visualization module
- `caffeine-parser.rkt` - Integration with caffeine DSL parser
- `file-watcher.rkt` - File system monitoring for live updates
- `test.rkt` - Comprehensive test suite
- `example.cf` - Sample caffeine file with service definitions

## Running the Application

To run the GUI application:

```bash
racket gui.rkt
```
