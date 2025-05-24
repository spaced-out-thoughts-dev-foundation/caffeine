# Persist

A compact, stupidly simple process for persisting state.

## Storage

Crawl: *a write only file*
  * Create: simple write
  * Modify: leveraging UUID of a data point, "overwrites" but write a new line in the file. Since it line has a timestamp, latest write wins.
    * Will not confirm still exists ahead of time
  * Delete: UUID, timestamp, all zeroes
  * Search: Bottom up (looks for most recent value) sequential scan. 
    * In-memory indexing is possible for faster reads
  * Compaction: a "stop the world" process of deleting unused values
    * Special feature: _limited persistence_. May delete, even "used" values greater than X.

Walk: **tbd**

Run: **tbd**
