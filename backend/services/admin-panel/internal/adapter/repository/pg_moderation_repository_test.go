package repository

import (
	"strings"
	"testing"

	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/domain/enum"
	"github.com/dkhvan-dev/flyfy/backend/services/admin-panel/internal/domain/model"
)

func TestBuildListCasesQueryAppliesExcursionFiltersAndSort(t *testing.T) {
	t.Parallel()

	targetType := model.ModerationTargetExcursion
	query, args := buildListCasesQuery(model.ModerationQueueFilter{
		TargetType: &targetType,
		Statuses: []enum.ModerationCaseStatus{
			enum.ModerationCaseStatusOpen,
		},
		Search:      "medeu_%",
		CountryCode: "KZ",
		City:        "almaty",
		Signal:      "new_guide",
		Risk:        model.ModerationRiskFilterHigh,
		Sort:        model.ModerationQueueSortRiskDesc,
		Limit:       50,
		Offset:      10,
	})

	expectedSnippets := []string{
		"target_type = $1",
		"status = ANY($2)",
		"LOWER(COALESCE",
		"UPPER(COALESCE(snapshot->>'CountryCode', ''))",
		"ProductTranslations",
		"GuideNickname",
		"DepartureCityID",
		"CityID",
		"CityName",
		"BaseCityID",
		"BaseCityName",
		"ModerationReasonCodes",
		"PublishRiskScore",
		"ORDER BY CASE WHEN jsonb_typeof(snapshot->'PublishRiskScore') = 'number'",
	}
	for _, snippet := range expectedSnippets {
		if !strings.Contains(query, snippet) {
			t.Fatalf("query does not contain %q:\n%s", snippet, query)
		}
	}

	if len(args) != 11 {
		t.Fatalf("unexpected args length: got %d, args=%#v", len(args), args)
	}
	if args[2] != `%medeu\_\%%` {
		t.Fatalf("search pattern was not escaped safely: %#v", args[2])
	}
	if args[3] != "KZ" {
		t.Fatalf("country arg was not normalized: %#v", args[3])
	}
	if args[4] != "almaty" || args[5] != "%almaty%" {
		t.Fatalf("city args were not normalized: %#v %#v", args[4], args[5])
	}
	if args[6] != "almaty" || args[7] != "%almaty%" {
		t.Fatalf("guide city args were not normalized: %#v %#v", args[6], args[7])
	}
	if args[8] != "new_guide" {
		t.Fatalf("signal arg was not preserved: %#v", args[8])
	}
	if args[9] != 50 || args[10] != 10 {
		t.Fatalf("limit/offset args were not last: %#v", args)
	}
}
