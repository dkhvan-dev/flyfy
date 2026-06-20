package enum

type MediaType string

const (
	MediaPhoto MediaType = "PHOTO"
	MediaVideo MediaType = "VIDEO"
)

func (m MediaType) IsValid() bool {
	return m == MediaPhoto || m == MediaVideo
}

func (m MediaType) String() string {
	return string(m)
}
