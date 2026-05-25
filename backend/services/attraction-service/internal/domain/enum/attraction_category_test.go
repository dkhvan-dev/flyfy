package enum

import "testing"

func TestAttractionCategoryMarketIsValid(t *testing.T) {
	t.Parallel()

	if !CategoryMarket.IsValid() {
		t.Fatalf("CategoryMarket must be a valid attraction category")
	}
	if got := CategoryMarket.String(); got != "MARKET" {
		t.Fatalf("CategoryMarket.String() = %q, want MARKET", got)
	}
}
