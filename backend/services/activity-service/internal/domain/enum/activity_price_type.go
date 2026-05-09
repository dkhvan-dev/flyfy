package enum

type ActivityPriceType string

const (
	ActivityPriceTypeFree    ActivityPriceType = "FREE"
	ActivityPriceTypePaid    ActivityPriceType = "PAID"
	ActivityPriceTypeDeposit ActivityPriceType = "DEPOSIT"
)

func (v ActivityPriceType) IsValid() bool {
	switch v {
	case ActivityPriceTypeFree, ActivityPriceTypePaid, ActivityPriceTypeDeposit:
		return true
	default:
		return false
	}
}

func (v ActivityPriceType) IsUserSelectable() bool {
	switch v {
	case ActivityPriceTypeFree, ActivityPriceTypePaid:
		return true
	default:
		return false
	}
}
