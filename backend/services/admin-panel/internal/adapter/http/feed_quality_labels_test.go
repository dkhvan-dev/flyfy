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
			want: "Карточка поста",
		},
		{
			name: "russian action",
			got:  feedQualityActionText(localeRU, "conversion"),
			want: "Конверсионный клик",
		},
		{
			name: "russian dwell action",
			got:  feedQualityActionText(localeRU, "dwell"),
			want: "Просмотр по времени",
		},
		{
			name: "russian subscribe action",
			got:  feedQualityActionText(localeRU, "subscribe"),
			want: "Подписка",
		},
		{
			name: "russian tab",
			got:  feedQualityTabText(localeRU, "for_you"),
			want: "Для вас",
		},
		{
			name: "russian post profile",
			got:  feedQualityPostProfileText(localeRU, "event_announcement_v1"),
			want: "Анонс события",
		},
		{
			name: "russian ranking experiment",
			got:  feedQualityExperimentText(localeRU, "control"),
			want: "Контроль",
		},
		{
			name: "russian candidate source",
			got:  feedQualityCandidateSourceText(localeRU, "social"),
			want: "Друзья и подписки",
		},
		{
			name: "unknown ranking experiment fallback",
			got:  feedQualityExperimentText(localeRU, "rank-v2"),
			want: "Rank V2",
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
