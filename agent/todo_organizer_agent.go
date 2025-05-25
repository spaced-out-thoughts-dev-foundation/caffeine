package agent

import (
	"fmt"
	"os"

	"github.com/spaced-out-thoughts-dev-foundation/caffeine/observer"
)

type TodoOrganizerAgent struct {
	todoListLocation string
}

func NewTodoOrganizerAgent(todoListLocation string) *TodoOrganizerAgent {
	return &TodoOrganizerAgent{
		todoListLocation: todoListLocation,
	}
}

func (a *TodoOrganizerAgent) String() string {
	return "TodoOrganizerAgent"
}

func (a *TodoOrganizerAgent) Init() error {
	validationErr := a.Validate()
	if validationErr != nil {
		return fmt.Errorf("trigger validation failed: %w", validationErr)
	}

	return nil
}

func (a *TodoOrganizerAgent) Perform() error {
	validationErr := a.Validate()
	if validationErr != nil {
		return fmt.Errorf("trigger validation failed: %w", validationErr)
	}

	// Load the todo list from the specified location
	todoList, err := os.ReadFile(a.todoListLocation)
	if err != nil {
		return fmt.Errorf("failed to read todo list from %s: %w", a.todoListLocation, err)
	}

	// Process the todo list (this is a placeholder for actual processing logic)
	observer.LogInfo("TodoOrganizerAgent", fmt.Sprintf("Processing todo list from %s", a.todoListLocation))
	// Here you would implement the logic to organize the todo items
	// For example, you might sort them, categorize them, or remove duplicates
	observer.LogInfo("TodoOrganizerAgent", fmt.Sprintf("Todo list content: %s", string(todoList)))
	// Return nil to indicate success
	return nil
}

func (a *TodoOrganizerAgent) Validate() error {
	if a.todoListLocation == "" {
		return fmt.Errorf("todoListLocation is not set")
	}

	if _, err := os.Stat(a.todoListLocation); os.IsNotExist(err) {
		return fmt.Errorf("todo list location does not exist: %s", a.todoListLocation)
	}

	return nil
}
