package main

import (
	"time"

	"github.com/spaced-out-thoughts-dev-foundation/caffeine/agent"
	"github.com/spaced-out-thoughts-dev-foundation/caffeine/observer"
	"github.com/spaced-out-thoughts-dev-foundation/caffeine/persist"
)

func DoAgentThings() {
	todoAgent := agent.NewTodoOrganizerAgent("todo_list.txt")
	if err := todoAgent.Init(nil); err != nil {
		observer.LogError("main", "Failed to initialize TodoOrganizerAgent: %v", err)
		return
	}
	if err := todoAgent.Perform(); err != nil {
		observer.LogError("main", "Failed to perform TodoOrganizerAgent: %v", err)
		return
	}
	observer.LogInfo("main", "TodoOrganizerAgent performed successfully")
}

func main() {
	observer.LogInfo("main", "Starting application...")
	persistInstance := persist.Server{
		Port:    8080,
		Storage: persist.Storage{},
	}

	// boot up the persistence engine
	go persistInstance.Start()

	// time.Sleep(1000000000)

	for {
		DoAgentThings()
		time.Sleep(5 * time.Second)
	}
}
