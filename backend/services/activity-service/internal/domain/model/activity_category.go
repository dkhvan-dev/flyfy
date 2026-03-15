package model

import "strings"

type ActivityCategory struct {
	Slug   string
	Name   string
	NameRu string
	NameKk string
}

var activityCategoryCatalog = []ActivityCategory{
	{
		Slug:   "health-wellness",
		Name:   "Health & Wellness",
		NameRu: "Здоровье и благополучие",
		NameKk: "Денсаулық және амандық",
	},
	{
		Slug:   "social-nightlife",
		Name:   "Social & Nightlife",
		NameRu: "Общение и ночная жизнь",
		NameKk: "Әлеуметтік қарым-қатынас және түнгі өмір",
	},
	{
		Slug:   "adventure-sports",
		Name:   "Adventure & Sports",
		NameRu: "Приключения и спорт",
		NameKk: "Шытырман және спорт",
	},
	{
		Slug:   "workshops-learning",
		Name:   "Workshops & Learning",
		NameRu: "Мастер-классы и обучение",
		NameKk: "Шеберлік сабақтары және оқу",
	},
}

var activityCategoryBySlug = func() map[string]ActivityCategory {
	items := make(map[string]ActivityCategory, len(activityCategoryCatalog))
	for _, item := range activityCategoryCatalog {
		items[item.Slug] = item
	}
	return items
}()

func ListActivityCategories() []ActivityCategory {
	items := make([]ActivityCategory, len(activityCategoryCatalog))
	copy(items, activityCategoryCatalog)
	return items
}

func NormalizeActivityCategorySlug(raw string) string {
	return strings.ToLower(strings.TrimSpace(raw))
}

func NormalizeAndValidateActivityCategorySlug(raw string) (string, error) {
	slug := NormalizeActivityCategorySlug(raw)
	if slug == "" {
		return "", ErrInvalidCategorySlug
	}

	if _, ok := activityCategoryBySlug[slug]; !ok {
		return "", ErrInvalidCategorySlug
	}

	return slug, nil
}
