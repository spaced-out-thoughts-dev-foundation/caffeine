package agent

type Agent interface {
	// Initialization function. Every agent has a trigger.
	Init(Trigger) error

	Perform() error
}
