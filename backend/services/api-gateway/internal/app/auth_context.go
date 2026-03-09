package app

type AuthContext struct {
	Subject   string
	UserID    string
	Roles     []string
	Token     string
	RequestID string
}

func (a AuthContext) IsAuthenticated() bool {
	return a.Subject != ""
}
