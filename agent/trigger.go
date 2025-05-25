package agent

// A trigger is an instance of a initiating event that can be used to kick off an agent.
//
// Design Decisions to Make:
// * is a trigger ongoing or is it a one time thing?
//   - performance implications
type Trigger interface {
	// String returns a string representation of the trigger.
	String() string

	// Initialize the trigger
	Init() error
}
