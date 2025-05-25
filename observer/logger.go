package observer

import (
	"fmt"
	"time"
)

func LogInfo(service string, message string) {
	msg := fmt.Sprintf("{%s: %s} %s", formattedNow(), service, message)

	fmt.Printf("[INFO]: %s\n", msg)
}

func LogError(service string, message string, args ...interface{}) {
	msg := fmt.Sprintf("{%s: %s} %s", formattedNow(), service, fmt.Sprintf(message, args...))

	fmt.Printf("[ERROR]: %s\n", msg)
}

func formattedNow() string {
	unformatted := time.Now().Local()

	return fmt.Sprintf("%d-%d-%d@%d:%d", unformatted.Year(), unformatted.Day(), unformatted.Month(), unformatted.Hour()%12, unformatted.Minute())
}
