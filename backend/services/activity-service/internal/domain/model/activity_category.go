package model

import "strings"

type ActivityTaxonomyItem struct {
	Slug   string
	Name   string
	NameRu string
	NameKk string
}

type ActivityCategory struct {
	Slug          string
	Name          string
	NameRu        string
	NameKk        string
	Aliases       []string
	Subcategories []ActivityTaxonomyItem
	SystemTags    []ActivityTaxonomyItem
}

var activityCategoryCatalog = []ActivityCategory{
	{
		Slug:   "food-drinks",
		Name:   "Food & Drinks",
		NameRu: "Еда и напитки",
		NameKk: "Тамақ және сусындар",
		Subcategories: []ActivityTaxonomyItem{
			taxonomyItem("coffee-meetup", "Coffee meetup", "Кофе-встреча", "Кофе кездесуі"),
			taxonomyItem("food-tasting", "Food tasting", "Дегустация", "Дәм тату"),
			taxonomyItem("dinner-club", "Dinner club", "Ужин-клуб", "Кешкі ас клубы"),
			taxonomyItem("bar-hop", "Bar hop", "Бар-хоппинг", "Барларға бару"),
		},
		SystemTags: commonTags(
			taxonomyItem("casual", "Casual", "Неформально", "Еркін"),
			taxonomyItem("evening", "Evening", "Вечером", "Кешке"),
			taxonomyItem("solo-friendly", "Solo-friendly", "Можно одному", "Жалғыз келуге болады"),
		),
	},
	{
		Slug:   "social-nightlife",
		Name:   "Social & Nightlife",
		NameRu: "Общение и ночная жизнь",
		NameKk: "Әлеуметтік қарым-қатынас және түнгі өмір",
		Subcategories: []ActivityTaxonomyItem{
			taxonomyItem("social-meetup", "Social meetup", "Встреча для общения", "Қарым-қатынас кездесуі"),
			taxonomyItem("speed-friending", "Speed friending", "Быстрые знакомства", "Жылдам танысу"),
			taxonomyItem("networking", "Networking", "Нетворкинг", "Нетворкинг"),
			taxonomyItem("party-night", "Party night", "Вечеринка", "Кеш"),
		},
		SystemTags: commonTags(
			taxonomyItem("solo-friendly", "Solo-friendly", "Можно одному", "Жалғыз келуге болады"),
			taxonomyItem("party", "Party", "Вечеринка", "Кеш"),
			taxonomyItem("new-people", "Meet new people", "Новые знакомства", "Жаңа адамдармен танысу"),
		),
	},
	{
		Slug:   "culture-art",
		Name:   "Culture & Art",
		NameRu: "Культура и искусство",
		NameKk: "Мәдениет және өнер",
		Subcategories: []ActivityTaxonomyItem{
			taxonomyItem("museum-gallery", "Museum or gallery", "Музей или галерея", "Музей немесе галерея"),
			taxonomyItem("live-music", "Live music", "Живая музыка", "Жанды музыка"),
			taxonomyItem("theatre-cinema", "Theatre or cinema", "Театр или кино", "Театр немесе кино"),
			taxonomyItem("local-culture", "Local culture", "Локальная культура", "Жергілікті мәдениет"),
		},
		SystemTags: commonTags(
			taxonomyItem("educational", "Educational", "Познавательно", "Танымдық"),
			taxonomyItem("indoor", "Indoor", "В помещении", "Ішкі кеңістікте"),
			taxonomyItem("date-friendly", "Date-friendly", "Подходит для свидания", "Кездесуге қолайлы"),
		),
	},
	{
		Slug:   "city-walks",
		Name:   "Walks & City",
		NameRu: "Прогулки и город",
		NameKk: "Серуендер және қала",
		Subcategories: []ActivityTaxonomyItem{
			taxonomyItem("city-walk", "City walk", "Городская прогулка", "Қала серуені"),
			taxonomyItem("photo-walk", "Photo walk", "Фотопрогулка", "Фото серуен"),
			taxonomyItem("architecture", "Architecture", "Архитектура", "Сәулет"),
			taxonomyItem("hidden-gems", "Hidden gems", "Неочевидные места", "Жасырын орындар"),
		},
		SystemTags: commonTags(
			taxonomyItem("walking", "Walking", "Пешком", "Жаяу"),
			taxonomyItem("outdoor", "Outdoor", "На улице", "Сыртта"),
			taxonomyItem("beginner-friendly", "Beginner-friendly", "Для новичков", "Жаңадан бастаушыларға"),
		),
	},
	{
		Slug:    "nature-outdoor",
		Name:    "Nature & Outdoor",
		NameRu:  "Природа и активный отдых",
		NameKk:  "Табиғат және белсенді демалыс",
		Aliases: []string{"adventure-sports"},
		Subcategories: []ActivityTaxonomyItem{
			taxonomyItem("hiking", "Hiking", "Хайкинг", "Жорық"),
			taxonomyItem("park-picnic", "Park or picnic", "Парк или пикник", "Саябақ немесе пикник"),
			taxonomyItem("camping", "Camping", "Кемпинг", "Кемпинг"),
			taxonomyItem("day-trip", "Day trip", "Поездка на день", "Бір күндік сапар"),
		},
		SystemTags: commonTags(
			taxonomyItem("active", "Active", "Активно", "Белсенді"),
			taxonomyItem("fresh-air", "Fresh air", "На свежем воздухе", "Таза ауада"),
			taxonomyItem("medium-intensity", "Medium intensity", "Средняя нагрузка", "Орташа қарқын"),
		),
	},
	{
		Slug:    "sports-wellness",
		Name:    "Sports & Wellness",
		NameRu:  "Спорт и здоровье",
		NameKk:  "Спорт және денсаулық",
		Aliases: []string{"health-wellness"},
		Subcategories: []ActivityTaxonomyItem{
			taxonomyItem("yoga-meditation", "Yoga or meditation", "Йога или медитация", "Йога немесе медитация"),
			taxonomyItem("running", "Running", "Бег", "Жүгіру"),
			taxonomyItem("fitness", "Fitness", "Фитнес", "Фитнес"),
			taxonomyItem("dance", "Dance", "Танцы", "Би"),
		},
		SystemTags: commonTags(
			taxonomyItem("active", "Active", "Активно", "Белсенді"),
			taxonomyItem("healthy", "Healthy", "Полезно для здоровья", "Денсаулыққа пайдалы"),
			taxonomyItem("beginner-friendly", "Beginner-friendly", "Для новичков", "Жаңадан бастаушыларға"),
		),
	},
	{
		Slug:   "workshops-learning",
		Name:   "Workshops & Learning",
		NameRu: "Мастер-классы и обучение",
		NameKk: "Шеберлік сабақтары және оқу",
		Subcategories: []ActivityTaxonomyItem{
			taxonomyItem("creative-workshop", "Creative workshop", "Творческий мастер-класс", "Шығармашылық шеберхана"),
			taxonomyItem("language-practice", "Language practice", "Языковая практика", "Тіл тәжірибесі"),
			taxonomyItem("lecture-talk", "Lecture or talk", "Лекция или встреча", "Дәріс немесе кездесу"),
			taxonomyItem("cooking-class", "Cooking class", "Кулинарный мастер-класс", "Аспаздық сабақ"),
		},
		SystemTags: commonTags(
			taxonomyItem("educational", "Educational", "Познавательно", "Танымдық"),
			taxonomyItem("hands-on", "Hands-on", "Практика", "Практикалық"),
			taxonomyItem("indoor", "Indoor", "В помещении", "Ішкі кеңістікте"),
		),
	},
	{
		Slug:   "games-entertainment",
		Name:   "Games & Entertainment",
		NameRu: "Игры и развлечения",
		NameKk: "Ойындар және ойын-сауық",
		Subcategories: []ActivityTaxonomyItem{
			taxonomyItem("quiz-trivia", "Quiz or trivia", "Квиз", "Квиз"),
			taxonomyItem("board-games", "Board games", "Настольные игры", "Үстел ойындары"),
			taxonomyItem("karaoke", "Karaoke", "Караоке", "Караоке"),
			taxonomyItem("escape-room", "Escape room", "Квест", "Квест"),
		},
		SystemTags: commonTags(
			taxonomyItem("fun", "Fun", "Весело", "Көңілді"),
			taxonomyItem("group-friendly", "Group-friendly", "Для компании", "Топқа қолайлы"),
			taxonomyItem("indoor", "Indoor", "В помещении", "Ішкі кеңістікте"),
		),
	},
	{
		Slug:   "family-kids",
		Name:   "Family & Kids",
		NameRu: "Семья и дети",
		NameKk: "Отбасы және балалар",
		Subcategories: []ActivityTaxonomyItem{
			taxonomyItem("family-walk", "Family walk", "Семейная прогулка", "Отбасылық серуен"),
			taxonomyItem("kids-workshop", "Kids workshop", "Детский мастер-класс", "Балалар шеберханасы"),
			taxonomyItem("kids-education", "Kids education", "Детское обучение", "Балаларға білім"),
			taxonomyItem("family-show", "Family show", "Семейное шоу", "Отбасылық шоу"),
		},
		SystemTags: commonTags(
			taxonomyItem("kids-friendly", "Kids-friendly", "Можно с детьми", "Балалармен болады"),
			taxonomyItem("family-friendly", "Family-friendly", "Для семьи", "Отбасына қолайлы"),
			taxonomyItem("daytime", "Daytime", "Днем", "Күндіз"),
		),
	},
	{
		Slug:   "other",
		Name:   "Other",
		NameRu: "Другое",
		NameKk: "Басқа",
		Subcategories: []ActivityTaxonomyItem{
			taxonomyItem("community-event", "Community event", "Событие сообщества", "Қауымдастық іс-шарасы"),
			taxonomyItem("special-event", "Special event", "Особое событие", "Арнайы іс-шара"),
		},
		SystemTags: commonTags(
			taxonomyItem("flexible", "Flexible", "Гибко", "Икемді"),
			taxonomyItem("community", "Community", "Сообщество", "Қауымдастық"),
		),
	},
}

var activityCategoryBySlug = func() map[string]ActivityCategory {
	items := make(map[string]ActivityCategory, len(activityCategoryCatalog))
	for _, item := range activityCategoryCatalog {
		items[item.Slug] = item
	}
	return items
}()

var activityCategoryCanonicalSlug = func() map[string]string {
	items := make(map[string]string, len(activityCategoryCatalog))
	for _, item := range activityCategoryCatalog {
		items[item.Slug] = item.Slug
		for _, alias := range item.Aliases {
			items[NormalizeActivityCategorySlug(alias)] = item.Slug
		}
	}
	return items
}()

func ListActivityCategories() []ActivityCategory {
	items := make([]ActivityCategory, len(activityCategoryCatalog))
	for i, item := range activityCategoryCatalog {
		items[i] = copyActivityCategory(item)
	}
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

	if canonicalSlug, ok := activityCategoryCanonicalSlug[slug]; ok {
		return canonicalSlug, nil
	}

	if _, ok := activityCategoryBySlug[slug]; !ok {
		return "", ErrInvalidCategorySlug
	}

	return slug, nil
}

func NormalizeAndValidateActivitySubCategorySlug(categorySlug string, raw string) (string, error) {
	slug := NormalizeActivityTagSlug(raw)
	if slug == "" {
		return "", nil
	}

	canonicalCategorySlug, err := NormalizeAndValidateActivityCategorySlug(categorySlug)
	if err != nil {
		return "", err
	}

	category, ok := activityCategoryBySlug[canonicalCategorySlug]
	if !ok {
		return "", ErrInvalidCategorySlug
	}

	for _, item := range category.Subcategories {
		if item.Slug == slug {
			return slug, nil
		}
	}

	return "", ErrInvalidActivitySubcategorySlug
}

func NormalizeActivityTagSlug(raw string) string {
	value := strings.ToLower(strings.TrimSpace(raw))
	value = strings.ReplaceAll(value, "_", "-")
	value = strings.Join(strings.Fields(value), "-")
	for strings.Contains(value, "--") {
		value = strings.ReplaceAll(value, "--", "-")
	}
	return strings.Trim(value, "-")
}

func taxonomyItem(slug, name, nameRu, nameKk string) ActivityTaxonomyItem {
	return ActivityTaxonomyItem{
		Slug:   slug,
		Name:   name,
		NameRu: nameRu,
		NameKk: nameKk,
	}
}

func commonTags(items ...ActivityTaxonomyItem) []ActivityTaxonomyItem {
	return items
}

func copyActivityCategory(item ActivityCategory) ActivityCategory {
	item.Aliases = append([]string(nil), item.Aliases...)
	item.Subcategories = append([]ActivityTaxonomyItem(nil), item.Subcategories...)
	item.SystemTags = append([]ActivityTaxonomyItem(nil), item.SystemTags...)
	return item
}
