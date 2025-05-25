package persist

import "github.com/spaced-out-thoughts-dev-foundation/caffeine/observer"

func LogInfo(message string) {
	observer.LogInfo("persist", message)
}
