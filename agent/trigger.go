package agent

// A trigger is an instance of a initiating event that can be used to kick off
// an agent.
type Trigger interface {
	// String returns a string representation of the trigger.
	String() string
}
