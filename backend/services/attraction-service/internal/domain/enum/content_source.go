package enum

type ContentSource string

const (
	SourceUser    ContentSource = "USER"
	SourceAIAgent ContentSource = "AI_AGENT"
	SourceImport  ContentSource = "IMPORT"
)

func (s ContentSource) IsValid() bool {
	return s == SourceUser || s == SourceAIAgent || s == SourceImport
}

func (s ContentSource) String() string {
	return string(s)
}
