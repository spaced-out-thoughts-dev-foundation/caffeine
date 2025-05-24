package persist

import "fmt"

type Storage struct{}

func (s Storage) Init() error {
	fmt.Println("[Persist] Initializing storage")
	return nil
}
