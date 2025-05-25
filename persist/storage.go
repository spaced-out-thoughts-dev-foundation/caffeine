package persist

type Storage struct{}

func (s Storage) Init() error {
	LogInfo("Initializing storage")
	return nil
}

func (s Storage) Write() error {
	return nil
}

// Sequential scan if no index
func (s Storage) ReadByUUID() (string, error) {
	return "", nil
}
