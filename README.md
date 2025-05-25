# caffeine

A systema and framework for agentic ai on resource constrained devices.

***

## Design Space

* Ephemeral (no assumptions about on or off)
* Designed to run on Raspberry Pi 4 Model B with 1gb ram

***

## How it Works

Each agent is some bits with a trigger. The trigger determines when we push the work into a queue which will the be scheduled. The queue is backed by the naive storage system (`persist`).
