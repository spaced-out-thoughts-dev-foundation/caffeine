package persist

import (
	"fmt"
	"log"
	"net/http"
)

type Server struct {
	Port    uint16
	Storage Storage
}

func helloHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintln(w, "Hello, World!")
}

func (s Server) Start() {
	http.HandleFunc("/", helloHandler)

	if err := s.Storage.Init(); err != nil {
		log.Fatalf("[Persist] Failed to initialize storage: %v", err)
	}

	LogInfo(fmt.Sprintf("Starting server on port: %d", s.Port))
	if err := http.ListenAndServe(fmt.Sprintf(":%d", s.Port), nil); err != nil {
		log.Fatal(err)
	}
}
