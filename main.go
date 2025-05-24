package main

import (
	"fmt"

	"github.com/spaced-out-thoughts-dev-foundation/caffeine/persist"
)

func main() {
	fmt.Println("Starting the main application...")
	persistInstance := persist.Server{
		Port:    8080,
		Storage: persist.Storage{},
	}
	persistInstance.Start()
}
