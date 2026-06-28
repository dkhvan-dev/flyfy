package data

import (
	"time"

	"kz/inflap/backend/services/checklist-service/internal/domain/model"
)

func DefaultCatalogSeed() model.CatalogSeed {
	return model.CatalogSeed{
		Templates: []model.ChecklistTemplate{
			{
				ID:       "documents.passport_id",
				Category: model.ChecklistCategoryDocuments,
				Priority: model.ChecklistPriorityCritical,
				Title: model.LocalizedText{
					EN: "Passport / ID",
					RU: "Паспорт / ID",
					KK: "Паспорт / ID",
				},
				Reason: model.LocalizedText{
					EN: "Confirm that your primary travel document is valid and easy to reach.",
					RU: "Проверьте, что основной документ действителен и находится под рукой.",
					KK: "Негізгі жол жүру құжаты жарамды әрі қолжетімді екенін тексеріңіз.",
				},
				TrustLevel:               model.TrustLevelOfficialLinkRequired,
				RequiresUserConfirmation: true,
				AppliesTo:                model.RuleCondition{Always: true},
			},
			{
				ID:       "documents.entry_requirements_self_check",
				Category: model.ChecklistCategoryDocuments,
				Priority: model.ChecklistPriorityCritical,
				Title: model.LocalizedText{
					EN: "Entry requirements check",
					RU: "Проверка требований въезда",
					KK: "Кіру талаптарын тексеру",
				},
				Reason: model.LocalizedText{
					EN: "Visa, passport validity, transit, health, and customs rules can depend on citizenship and route.",
					RU: "Виза, срок паспорта, транзит, медицина и таможня зависят от гражданства и маршрута.",
					KK: "Виза, паспорт мерзімі, транзит, медицина және кеден азаматтық пен бағытқа байланысты.",
				},
				TrustLevel:               model.TrustLevelOfficialLinkRequired,
				RequiresUserConfirmation: true,
				AppliesTo:                model.RuleCondition{InternationalTrip: true},
			},
			{
				ID:       "documents.travel_insurance",
				Category: model.ChecklistCategoryDocuments,
				Priority: model.ChecklistPriorityEssential,
				Title: model.LocalizedText{
					EN: "Travel insurance",
					RU: "Туристическая страховка",
					KK: "Саяхат сақтандыруы",
				},
				Reason: model.LocalizedText{
					EN: "Keep policy number and emergency contacts available offline.",
					RU: "Сохраните номер полиса и контакты помощи офлайн.",
					KK: "Полис нөмірі мен жедел көмек байланыстарын офлайн сақтаңыз.",
				},
				TrustLevel: model.TrustLevelGeneralAdvisory,
				AppliesTo:  model.RuleCondition{InternationalTrip: true},
			},
			{
				ID:       "documents.bookings_offline",
				Category: model.ChecklistCategoryDocuments,
				Priority: model.ChecklistPriorityRecommended,
				Title: model.LocalizedText{
					EN: "Save tickets and bookings",
					RU: "Сохранить билеты и брони",
					KK: "Билеттер мен броньдарды сақтау",
				},
				Reason: model.LocalizedText{
					EN: "Download, add to Wallet, or print tickets, accommodation bookings, activity confirmations, and transfers for poor network moments.",
					RU: "Скачайте, добавьте в Wallet или распечатайте билеты, брони жилья, активности и трансферы на случай плохой связи.",
					KK: "Байланыс нашар болғанда қажет болуы үшін билеттерді, қонақүй броньдарын, белсенділік растауларын және трансферлерді жүктеп алыңыз, Wallet-ке қосыңыз немесе басып шығарыңыз.",
				},
				TrustLevel: model.TrustLevelGeneralAdvisory,
				AppliesTo:  model.RuleCondition{Always: true},
			},
			{
				ID:       "documents.child_documents",
				Category: model.ChecklistCategoryDocuments,
				Priority: model.ChecklistPriorityCritical,
				Title: model.LocalizedText{
					EN: "Child travel documents",
					RU: "Документы ребенка",
					KK: "Баланың құжаттары",
				},
				Reason: model.LocalizedText{
					EN: "Children may need extra identity, consent, or guardianship documents.",
					RU: "Для детей могут понадобиться дополнительные документы, согласия или подтверждения опеки.",
					KK: "Балаларға қосымша жеке куәлік, келісім немесе қамқоршылық құжаттары қажет болуы мүмкін.",
				},
				TrustLevel:               model.TrustLevelOfficialLinkRequired,
				RequiresUserConfirmation: true,
				AppliesTo:                model.RuleCondition{TravelerHasChildren: true},
			},
			{
				ID:       "baggage.power_bank_carry_on",
				Category: model.ChecklistCategoryBaggage,
				Priority: model.ChecklistPriorityRecommended,
				Title: model.LocalizedText{
					EN: "Power bank in carry-on",
					RU: "Power bank в ручную кладь",
					KK: "Power bank қол жүгінде",
				},
				Reason: model.LocalizedText{
					EN: "Spare lithium batteries and power banks belong in carry-on baggage. Check airline capacity limits.",
					RU: "Запасные литиевые батареи и power bank перевозятся в ручной клади. Проверьте лимиты емкости у авиакомпании.",
					KK: "Қосымша литий батареялары мен power bank қол жүгінде болуы керек. Әуе компаниясының лимитін тексеріңіз.",
				},
				TrustLevel: model.TrustLevelVerifiedCurated,
				Source:     faaPackSafeSource(),
				AppliesTo:  model.RuleCondition{TransportMode: model.TransportModeFlight},
			},
			{
				ID:       "baggage.liquids_100ml",
				Category: model.ChecklistCategoryBaggage,
				Priority: model.ChecklistPriorityRecommended,
				Title: model.LocalizedText{
					EN: "Liquids in small containers",
					RU: "Жидкости в небольших емкостях",
					KK: "Сұйықтықтар шағын ыдыстарда",
				},
				Reason: model.LocalizedText{
					EN: "Many airports require cabin liquids to fit local security rules. Keep medicines and baby food separate for screening.",
					RU: "Во многих аэропортах жидкости в ручной клади должны соответствовать правилам досмотра. Лекарства и детское питание держите отдельно.",
					KK: "Көп әуежайда қол жүгіндегі сұйықтықтар қауіпсіздік ережелеріне сай болуы керек. Дәрі мен балалар тамағын бөлек ұстаңыз.",
				},
				TrustLevel: model.TrustLevelOfficialLinkRequired,
				Source: model.Source{
					Name:       "GOV.UK hand luggage restrictions",
					URL:        "https://www.gov.uk/hand-luggage-restrictions/liquids",
					Type:       model.SourceTypeOfficialAuthority,
					Confidence: model.SourceConfidenceHigh,
					ReviewedAt: reviewedAt(),
				},
				RequiresUserConfirmation: true,
				AppliesTo:                model.RuleCondition{TransportMode: model.TransportModeFlight},
			},
			{
				ID:       "activity.hiking_daypack",
				Category: model.ChecklistCategoryActivity,
				Priority: model.ChecklistPriorityEssential,
				Title: model.LocalizedText{
					EN: "Hiking daypack",
					RU: "Рюкзак для хайкинга",
					KK: "Жаяу серуен рюкзагы",
				},
				Reason: model.LocalizedText{
					EN: "Keep water, layers, offline maps, and first aid together.",
					RU: "Вода, слои одежды, офлайн-карты и аптечка должны быть под рукой.",
					KK: "Су, киім қабаттары, офлайн карталар және дәрі қобдишасы бірге болсын.",
				},
				TrustLevel: model.TrustLevelGeneralAdvisory,
				AppliesTo:  model.RuleCondition{ActivitySlug: "hiking"},
			},
			{
				ID:       "activity.beach_sun_protection",
				Category: model.ChecklistCategoryActivity,
				Priority: model.ChecklistPriorityImportant,
				Title: model.LocalizedText{
					EN: "Sun and water protection",
					RU: "Защита от солнца и воды",
					KK: "Күн мен судан қорғаныс",
				},
				Reason: model.LocalizedText{
					EN: "For beach plans, pack sunscreen, hat, water-safe pouch, and a dry change layer.",
					RU: "Для пляжа возьмите SPF, головной убор, водозащитный чехол и сухую сменную одежду.",
					KK: "Жағажайға SPF, бас киім, су өткізбейтін қап және құрғақ ауыстыратын киім алыңыз.",
				},
				TrustLevel: model.TrustLevelGeneralAdvisory,
				AppliesTo:  model.RuleCondition{ActivitySlug: "beach"},
			},
			{
				ID:       "money.esim_offline_map",
				Category: model.ChecklistCategoryMoney,
				Priority: model.ChecklistPriorityRecommended,
				Title: model.LocalizedText{
					EN: "Connectivity and offline maps",
					RU: "Связь и офлайн-карты",
					KK: "Байланыс және офлайн карталар",
				},
				Reason: model.LocalizedText{
					EN: "Prepare eSIM/SIM, roaming, translator, and maps before departure.",
					RU: "Подготовьте eSIM/SIM, роуминг, переводчик и карты до выезда.",
					KK: "eSIM/SIM, роуминг, аудармашы және карталарды алдын ала дайындаңыз.",
				},
				TrustLevel: model.TrustLevelGeneralAdvisory,
				AppliesTo:  model.RuleCondition{Always: true},
			},
			{
				ID:       "safety.emergency_contacts",
				Category: model.ChecklistCategorySafety,
				Priority: model.ChecklistPriorityImportant,
				Title: model.LocalizedText{
					EN: "Emergency contacts",
					RU: "Экстренные контакты",
					KK: "Төтенше байланыстар",
				},
				Reason: model.LocalizedText{
					EN: "Save insurance, local emergency, accommodation, and embassy contacts offline.",
					RU: "Сохраните контакты страховки, экстренных служб, жилья и посольства офлайн.",
					KK: "Сақтандыру, жедел қызмет, қонақүй және елшілік байланыстарын офлайн сақтаңыз.",
				},
				TrustLevel: model.TrustLevelGeneralAdvisory,
				AppliesTo:  model.RuleCondition{Always: true},
			},
			{
				ID:       "weather.tokyo_july_rain_heat",
				Category: model.ChecklistCategoryWeather,
				Priority: model.ChecklistPriorityImportant,
				Title: model.LocalizedText{
					EN: "Heat and rain kit",
					RU: "Защита от жары и дождя",
					KK: "Ыстық пен жаңбырдан қорғаныс",
				},
				Reason: model.LocalizedText{
					EN: "Tokyo in July is usually hot, humid, and often rainy.",
					RU: "В июле в Токио обычно жарко, влажно и часто дождливо.",
					KK: "Шілдеде Токиода әдетте ыстық, ылғалды және жиі жаңбырлы.",
				},
				TrustLevel: model.TrustLevelVerifiedCurated,
				Source:     worldBankClimateSource(),
				AppliesTo: model.RuleCondition{
					CountryCode: "JP",
					CityName:    "Tokyo",
					Month:       time.July,
				},
			},
		},
		SeasonalProfiles: defaultSeasonalProfiles(),
		CarryRules:       defaultCarryRules(),
	}
}

func defaultCarryRules() []model.CarryRule {
	return []model.CarryRule{
		{
			ItemSlug:             "power_bank",
			Aliases:              []string{"power bank", "powerbank", "portable charger", "battery pack", "повербанк", "повер банк", "пауэрбанк", "пауэр банк"},
			TransportMode:        model.TransportModeFlight,
			CarryOn:              model.CarryPolicyAllowedWithConditions,
			CheckedBaggage:       model.CarryPolicyProhibited,
			RequiresAirlineCheck: true,
			ConditionSummary: model.LocalizedText{
				EN: "Carry-on only. Check airline capacity limits.",
				RU: "Только ручная кладь. Проверьте лимиты емкости у авиакомпании.",
				KK: "Тек қол жүгінде. Сыйымдылық лимитін әуе компаниясынан тексеріңіз.",
			},
			Source: faaPackSafeSource(),
		},
		{
			ItemSlug:       "travel_visa",
			Aliases:        []string{"visa", "entry visa", "travel visa", "виза", "е-виза", "e visa", "e-visa", "документы", "паспорт"},
			TransportMode:  model.TransportModeFlight,
			CarryOn:        model.CarryPolicyAllowed,
			CheckedBaggage: model.CarryPolicyCheckAuthority,
			ConditionSummary: model.LocalizedText{
				EN: "Keep travel documents in carry-on and confirm entry requirements with official sources.",
				RU: "Документы держите в ручной клади и проверьте требования въезда по официальным источникам.",
				KK: "Құжаттарды қол жүгінде ұстаңыз және кіру талаптарын ресми дереккөздерден тексеріңіз.",
			},
			Source: model.Source{
				Name:       "Inflap curated document guidance",
				Type:       model.SourceTypeCurated,
				Confidence: model.SourceConfidenceMedium,
				ReviewedAt: reviewedAt(),
			},
		},
		{
			ItemSlug:       "liquids",
			Aliases:        []string{"liquid", "liquids", "shampoo", "perfume", "cream", "gel", "жидкость", "жидкости", "шампунь", "духи", "крем", "гель"},
			TransportMode:  model.TransportModeFlight,
			CarryOn:        model.CarryPolicyAllowedWithConditions,
			CheckedBaggage: model.CarryPolicyAllowed,
			ConditionSummary: model.LocalizedText{
				EN: "Cabin liquids usually need to meet airport security limits and exceptions.",
				RU: "Жидкости в салоне обычно должны соответствовать лимитам и исключениям досмотра.",
				KK: "Салондағы сұйықтықтар әдетте қауіпсіздік лимиттері мен ерекшеліктеріне сай болуы керек.",
			},
			Source: model.Source{
				Name:       "GOV.UK hand luggage restrictions",
				URL:        "https://www.gov.uk/hand-luggage-restrictions/liquids",
				Type:       model.SourceTypeOfficialAuthority,
				Confidence: model.SourceConfidenceHigh,
				ReviewedAt: reviewedAt(),
			},
		},
		{
			ItemSlug:       "sharp_items",
			Aliases:        []string{"knife", "scissors", "blade", "multitool", "нож", "ножницы", "лезвие", "мультитул"},
			TransportMode:  model.TransportModeFlight,
			CarryOn:        model.CarryPolicyProhibited,
			CheckedBaggage: model.CarryPolicyAllowedWithConditions,
			ConditionSummary: model.LocalizedText{
				EN: "Sharp items are usually not allowed in cabin baggage; pack only if local and airline rules permit.",
				RU: "Острые предметы обычно нельзя брать в салон; перевозите только если это разрешено правилами.",
				KK: "Өткір заттарды әдетте салонға алуға болмайды; тек ережелер рұқсат етсе ғана салыңыз.",
			},
			Source: model.Source{
				Name:       "TSA What Can I Bring",
				URL:        "https://www.tsa.gov/travel/security-screening/whatcanibring/all",
				Type:       model.SourceTypeOfficialAuthority,
				Confidence: model.SourceConfidenceMedium,
				ReviewedAt: reviewedAt(),
			},
		},
	}
}

func defaultSeasonalProfiles() []model.SeasonalProfile {
	return []model.SeasonalProfile{
		seasonal("KZ", "Almaty", time.January, model.TemperatureCold, model.PrecipitationSnow, model.SkyCloudy, []string{"icy", "cold"}, []model.LocalizedText{
			{EN: "Warm waterproof shoes", RU: "Теплая непромокаемая обувь", KK: "Жылы су өткізбейтін аяқ киім"},
			{EN: "Gloves and warm layer", RU: "Перчатки и теплый слой", KK: "Қолғап және жылы қабат"},
		}),
		seasonal("TR", "Istanbul", time.November, model.TemperatureMild, model.PrecipitationOccasionalRain, model.SkyMixed, []string{"windy", "rain"}, []model.LocalizedText{
			{EN: "Light jacket", RU: "Легкая куртка", KK: "Жеңіл күрте"},
			{EN: "Compact umbrella", RU: "Компактный зонт", KK: "Ықшам қолшатыр"},
		}),
		seasonal("AE", "Dubai", time.August, model.TemperatureVeryHot, model.PrecipitationDry, model.SkySunny, []string{"high_uv", "heat"}, []model.LocalizedText{
			{EN: "Sun protection", RU: "Защита от солнца", KK: "Күннен қорғаныс"},
			{EN: "Breathable clothes", RU: "Дышащая одежда", KK: "Демалатын киім"},
		}),
		seasonal("TH", "Bangkok", time.September, model.TemperatureHot, model.PrecipitationRainy, model.SkyMixed, []string{"humid", "rain"}, []model.LocalizedText{
			{EN: "Quick-dry clothes", RU: "Быстросохнущая одежда", KK: "Тез кебетін киім"},
			{EN: "Rain protection", RU: "Защита от дождя", KK: "Жаңбырдан қорғаныс"},
		}),
		seasonal("JP", "Tokyo", time.July, model.TemperatureHot, model.PrecipitationRainy, model.SkyMixed, []string{"humid", "high_uv", "rain"}, []model.LocalizedText{
			{EN: "Light breathable clothes", RU: "Легкая дышащая одежда", KK: "Жеңіл демалатын киім"},
			{EN: "Compact rain protection", RU: "Компактная защита от дождя", KK: "Ықшам жаңбыр қорғанысы"},
		}),
		seasonal("KR", "Seoul", time.December, model.TemperatureCold, model.PrecipitationSnow, model.SkyCloudy, []string{"cold", "icy"}, []model.LocalizedText{
			{EN: "Warm coat", RU: "Теплое пальто", KK: "Жылы пальто"},
			{EN: "Thermal layer", RU: "Термослой", KK: "Термоқабат"},
		}),
		seasonal("GE", "Tbilisi", time.May, model.TemperatureWarm, model.PrecipitationOccasionalRain, model.SkyMixed, []string{"mixed_weather"}, []model.LocalizedText{
			{EN: "Layered clothes", RU: "Одежда слоями", KK: "Қабаттап киім"},
			{EN: "Comfortable walking shoes", RU: "Удобная обувь для прогулок", KK: "Жаяу жүруге ыңғайлы аяқ киім"},
		}),
		seasonal("UZ", "Tashkent", time.July, model.TemperatureVeryHot, model.PrecipitationDry, model.SkySunny, []string{"heat", "dry", "high_uv"}, []model.LocalizedText{
			{EN: "Sun hat", RU: "Головной убор от солнца", KK: "Күннен қорғайтын бас киім"},
			{EN: "Reusable water bottle", RU: "Многоразовая бутылка для воды", KK: "Қайта қолданылатын су бөтелкесі"},
		}),
		seasonal("ID", "Bali", time.January, model.TemperatureHot, model.PrecipitationRainy, model.SkyMixed, []string{"humid", "high_uv", "rain"}, []model.LocalizedText{
			{EN: "Light breathable clothes", RU: "Легкая дышащая одежда", KK: "Жеңіл демалатын киім"},
			{EN: "Water-safe pouch", RU: "Водозащитный чехол", KK: "Су өткізбейтін қап"},
		}),
	}
}

func seasonal(
	countryCode string,
	cityName string,
	month time.Month,
	temperature model.TemperatureBand,
	precipitation model.PrecipitationBand,
	sky model.SkyBand,
	riskTags []string,
	implications []model.LocalizedText,
) model.SeasonalProfile {
	return model.SeasonalProfile{
		Destination:         model.TripDestination{CountryCode: countryCode, CityName: cityName},
		Month:               month,
		TemperatureBand:     temperature,
		PrecipitationBand:   precipitation,
		SkyBand:             sky,
		RiskTags:            riskTags,
		PackingImplications: implications,
		Source:              worldBankClimateSource(),
	}
}

func faaPackSafeSource() model.Source {
	return model.Source{
		Name:       "FAA PackSafe",
		URL:        "https://www.faa.gov/hazmat/packsafe/lithium-batteries",
		Type:       model.SourceTypeOfficialAuthority,
		Confidence: model.SourceConfidenceHigh,
		ReviewedAt: reviewedAt(),
	}
}

func worldBankClimateSource() model.Source {
	return model.Source{
		Name:       "World Bank Climate Change Knowledge Portal",
		URL:        "https://climateknowledgeportal.worldbank.org/download-data",
		Type:       model.SourceTypeOpenData,
		Confidence: model.SourceConfidenceMedium,
		ReviewedAt: reviewedAt(),
	}
}

func reviewedAt() time.Time {
	return time.Date(2026, time.June, 20, 0, 0, 0, 0, time.UTC)
}
