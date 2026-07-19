package savedsearch

import (
	"time"

	"github.com/google/uuid"

	savedqueryapp "kz/inflap/backend/services/saved-service/internal/app/savedquery"
)

const (
	DefaultPageLimit            = savedqueryapp.DefaultPageLimit
	MaxPageLimit                = savedqueryapp.MaxPageLimit
	MaxEffectiveCollectionCount = savedqueryapp.MaxEffectiveCollectionCount
	MaxSearchCodePoints         = 200
	MaxSearchTokens             = 16
	maxAlternateDisplayRunes    = 300
)

type MatchRank uint8

const (
	MatchRankTitleExact MatchRank = iota + 1
	MatchRankTitleToken
	MatchRankTitlePrefix
	MatchRankLocationExactOrToken
	MatchRankLocationPrefix
)

func (r MatchRank) IsValid() bool {
	return r >= MatchRankTitleExact && r <= MatchRankLocationPrefix
}

type MatchKind string

const (
	MatchKindExact  MatchKind = "EXACT"
	MatchKindToken  MatchKind = "TOKEN"
	MatchKindPrefix MatchKind = "PREFIX"
)

func (k MatchKind) IsValid() bool {
	return k == MatchKindExact || k == MatchKindToken || k == MatchKindPrefix
}

type MatchedField string

const (
	MatchedFieldTitle   MatchedField = "TITLE"
	MatchedFieldCity    MatchedField = "CITY"
	MatchedFieldCountry MatchedField = "COUNTRY"
)

func (f MatchedField) IsValid() bool {
	return f == MatchedFieldTitle || f == MatchedFieldCity || f == MatchedFieldCountry
}

// Match contains only bounded presentation metadata. The matching text is
// returned only when the winning field is not the card's current title field.
type Match struct {
	Rank                   MatchRank
	Kind                   MatchKind
	Field                  MatchedField
	Locale                 savedqueryapp.Locale
	AlternatePublicDisplay *string
}

type Item struct {
	savedqueryapp.Item
	Match Match
}

// Keyset is decoded app-level cursor state. Cursor encryption and transport
// binding intentionally remain outside the repository.
type Keyset struct {
	MatchRank MatchRank
	SavedAt   time.Time
	ItemID    uuid.UUID
}

type Page struct {
	Items   []Item
	Next    *Keyset
	HasMore bool
}
