INSERT INTO help_categories (id, slug, sort_order, status, created_at, updated_at)
VALUES
    ('documents_visas_entry', 'documents-visas-entry', 10, 'published', now(), now()),
    ('airport_flights_baggage', 'airport-flights-baggage', 20, 'published', now(), now()),
    ('booking_accommodation', 'booking-accommodation', 30, 'published', now(), now()),
    ('money_cards_connectivity', 'money-cards-connectivity', 40, 'published', now(), now()),
    ('health_safety_insurance', 'health-safety-insurance', 50, 'published', now(), now()),
    ('local_transport', 'local-transport', 60, 'published', now(), now()),
    ('route_budget_planning', 'route-budget-planning', 70, 'published', now(), now()),
    ('local_rules_culture_special', 'local-rules-culture-special', 80, 'published', now(), now())
ON CONFLICT (id) DO UPDATE SET
    slug = EXCLUDED.slug,
    sort_order = EXCLUDED.sort_order,
    status = 'published',
    updated_at = now();

UPDATE help_articles
SET category_id = CASE
    WHEN id BETWEEN 'tourist-faq-001' AND 'tourist-faq-018' THEN 'documents_visas_entry'
    WHEN id BETWEEN 'tourist-faq-019' AND 'tourist-faq-037' THEN 'airport_flights_baggage'
    WHEN id BETWEEN 'tourist-faq-038' AND 'tourist-faq-047' THEN 'booking_accommodation'
    WHEN id BETWEEN 'tourist-faq-048' AND 'tourist-faq-057' THEN 'money_cards_connectivity'
    WHEN id BETWEEN 'tourist-faq-058' AND 'tourist-faq-072' THEN 'health_safety_insurance'
    WHEN id BETWEEN 'tourist-faq-073' AND 'tourist-faq-080' THEN 'local_transport'
    WHEN id BETWEEN 'tourist-faq-081' AND 'tourist-faq-089' THEN 'route_budget_planning'
    WHEN id BETWEEN 'tourist-faq-090' AND 'tourist-faq-100' THEN 'local_rules_culture_special'
    ELSE category_id
END,
updated_at = now()
WHERE id LIKE 'tourist-faq-%';

DELETE FROM help_category_translations
WHERE category_id IN (
    'documents_entry',
    'flights_airports_baggage',
    'stays_accommodation',
    'money_cards',
    'travel_connectivity',
    'health_insurance',
    'travel_safety',
    'planning_budget',
    'local_rules_culture',
    'special_travel_needs',
    'travel_problems'
);

DELETE FROM help_categories
WHERE id IN (
    'documents_entry',
    'flights_airports_baggage',
    'stays_accommodation',
    'money_cards',
    'travel_connectivity',
    'health_insurance',
    'travel_safety',
    'planning_budget',
    'local_rules_culture',
    'special_travel_needs',
    'travel_problems'
)
AND NOT EXISTS (
    SELECT 1
    FROM help_articles
    WHERE help_articles.category_id = help_categories.id
);

DROP TABLE IF EXISTS help_category_translations;
