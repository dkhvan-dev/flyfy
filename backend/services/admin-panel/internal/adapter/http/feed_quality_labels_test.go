package http

import "testing"

func TestFeedQualityLabelsUseRequestedLocale(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name string
		got  string
		want string
	}{
		{
			name: "russian surface",
			got:  feedQualitySurfaceText(localeRU, "home"),
			want: "Главная лента",
		},
		{
			name: "russian block type",
			got:  feedQualityBlockTypeText(localeRU, "post_card"),
			want: "Карточка истории",
		},
		{
			name: "russian action",
			got:  feedQualityActionText(localeRU, "conversion"),
			want: "Конверсионный клик",
		},
		{
			name: "unknown code fallback",
			got:  feedQualityBlockTypeText(localeRU, "custom_block"),
			want: "Custom Block",
		},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			t.Parallel()
			if test.got != test.want {
				t.Fatalf("label = %q, want %q", test.got, test.want)
			}
		})
	}
}
