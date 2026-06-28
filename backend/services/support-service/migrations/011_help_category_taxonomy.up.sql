CREATE TABLE IF NOT EXISTS help_category_translations (
    category_id TEXT NOT NULL REFERENCES help_categories(id) ON DELETE CASCADE,
    locale TEXT NOT NULL CHECK (locale IN ('en', 'ru', 'kk')),
    title TEXT NOT NULL CHECK (length(title) BETWEEN 2 AND 120),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (category_id, locale)
);

CREATE TEMP TABLE help_category_taxonomy_seed (
    id TEXT PRIMARY KEY,
    slug TEXT NOT NULL,
    sort_order INTEGER NOT NULL,
    title_ru TEXT NOT NULL,
    title_en TEXT NOT NULL,
    title_kk TEXT NOT NULL
);

INSERT INTO help_category_taxonomy_seed (id, slug, sort_order, title_ru, title_en, title_kk)
VALUES
    ('documents_entry', 'documents-entry', 10, 'Документы и въезд', 'Documents and entry', 'Құжаттар және кіру'),
    ('flights_airports_baggage', 'flights-airports-baggage', 20, 'Рейсы, аэропорт и багаж', 'Flights, airport and baggage', 'Рейстер, әуежай және багаж'),
    ('stays_accommodation', 'stays-accommodation', 30, 'Проживание', 'Accommodation', 'Тұру'),
    ('money_cards', 'money-cards', 40, 'Деньги и карты', 'Money and cards', 'Ақша және карталар'),
    ('travel_connectivity', 'travel-connectivity', 50, 'Связь и интернет', 'Connection and SIM/eSIM', 'Байланыс және интернет'),
    ('health_insurance', 'health-insurance', 60, 'Здоровье и страховка', 'Health and insurance', 'Денсаулық және сақтандыру'),
    ('travel_safety', 'travel-safety', 70, 'Безопасность', 'Safety', 'Қауіпсіздік'),
    ('local_transport', 'local-transport', 80, 'Транспорт на месте', 'Local transport', 'Жергілікті көлік'),
    ('planning_budget', 'planning-budget', 90, 'Маршрут и бюджет', 'Route and budget', 'Маршрут және бюджет'),
    ('local_rules_culture', 'local-rules-culture', 100, 'Правила и культура', 'Rules and culture', 'Ережелер және мәдениет'),
    ('special_travel_needs', 'special-travel-needs', 110, 'Дети, животные и особые случаи', 'Children, pets and special cases', 'Балалар, жануарлар және ерекше жағдайлар'),
    ('travel_problems', 'travel-problems', 120, 'Проблемы в поездке', 'Trip problems', 'Сапардағы мәселелер');

INSERT INTO help_categories (id, slug, sort_order, status, created_at, updated_at)
SELECT id, slug, sort_order, 'published', now(), now()
FROM help_category_taxonomy_seed
ON CONFLICT (id) DO UPDATE SET
    slug = EXCLUDED.slug,
    sort_order = EXCLUDED.sort_order,
    status = 'published',
    updated_at = now();

INSERT INTO help_category_translations (category_id, locale, title, created_at, updated_at)
SELECT id, 'ru', title_ru, now(), now()
FROM help_category_taxonomy_seed
UNION ALL
SELECT id, 'en', title_en, now(), now()
FROM help_category_taxonomy_seed
UNION ALL
SELECT id, 'kk', title_kk, now(), now()
FROM help_category_taxonomy_seed
ON CONFLICT (category_id, locale) DO UPDATE SET
    title = EXCLUDED.title,
    updated_at = now();

CREATE TEMP TABLE help_category_article_remap (
    article_id TEXT PRIMARY KEY,
    category_id TEXT NOT NULL
);

INSERT INTO help_category_article_remap (article_id, category_id)
VALUES
    ('tourist-faq-001', 'documents_entry'),
    ('tourist-faq-002', 'documents_entry'),
    ('tourist-faq-003', 'documents_entry'),
    ('tourist-faq-004', 'documents_entry'),
    ('tourist-faq-005', 'documents_entry'),
    ('tourist-faq-006', 'documents_entry'),
    ('tourist-faq-007', 'documents_entry'),
    ('tourist-faq-008', 'documents_entry'),
    ('tourist-faq-009', 'documents_entry'),
    ('tourist-faq-010', 'documents_entry'),
    ('tourist-faq-011', 'documents_entry'),
    ('tourist-faq-012', 'documents_entry'),
    ('tourist-faq-013', 'documents_entry'),
    ('tourist-faq-014', 'documents_entry'),
    ('tourist-faq-015', 'documents_entry'),
    ('tourist-faq-016', 'documents_entry'),
    ('tourist-faq-017', 'documents_entry'),
    ('tourist-faq-018', 'documents_entry'),
    ('tourist-faq-019', 'flights_airports_baggage'),
    ('tourist-faq-020', 'flights_airports_baggage'),
    ('tourist-faq-021', 'flights_airports_baggage'),
    ('tourist-faq-022', 'flights_airports_baggage'),
    ('tourist-faq-023', 'flights_airports_baggage'),
    ('tourist-faq-024', 'flights_airports_baggage'),
    ('tourist-faq-025', 'flights_airports_baggage'),
    ('tourist-faq-026', 'flights_airports_baggage'),
    ('tourist-faq-027', 'flights_airports_baggage'),
    ('tourist-faq-028', 'flights_airports_baggage'),
    ('tourist-faq-029', 'flights_airports_baggage'),
    ('tourist-faq-030', 'flights_airports_baggage'),
    ('tourist-faq-032', 'flights_airports_baggage'),
    ('tourist-faq-033', 'flights_airports_baggage'),
    ('tourist-faq-035', 'flights_airports_baggage'),
    ('tourist-faq-036', 'flights_airports_baggage'),
    ('tourist-faq-037', 'flights_airports_baggage'),
    ('tourist-faq-038', 'stays_accommodation'),
    ('tourist-faq-039', 'stays_accommodation'),
    ('tourist-faq-040', 'stays_accommodation'),
    ('tourist-faq-041', 'stays_accommodation'),
    ('tourist-faq-042', 'stays_accommodation'),
    ('tourist-faq-043', 'stays_accommodation'),
    ('tourist-faq-045', 'stays_accommodation'),
    ('tourist-faq-046', 'stays_accommodation'),
    ('tourist-faq-048', 'money_cards'),
    ('tourist-faq-049', 'money_cards'),
    ('tourist-faq-050', 'money_cards'),
    ('tourist-faq-051', 'money_cards'),
    ('tourist-faq-052', 'money_cards'),
    ('tourist-faq-055', 'money_cards'),
    ('tourist-faq-057', 'money_cards'),
    ('tourist-faq-053', 'travel_connectivity'),
    ('tourist-faq-054', 'travel_connectivity'),
    ('tourist-faq-087', 'travel_connectivity'),
    ('tourist-faq-058', 'health_insurance'),
    ('tourist-faq-059', 'health_insurance'),
    ('tourist-faq-060', 'health_insurance'),
    ('tourist-faq-061', 'health_insurance'),
    ('tourist-faq-062', 'health_insurance'),
    ('tourist-faq-063', 'health_insurance'),
    ('tourist-faq-064', 'health_insurance'),
    ('tourist-faq-065', 'health_insurance'),
    ('tourist-faq-066', 'health_insurance'),
    ('tourist-faq-067', 'health_insurance'),
    ('tourist-faq-071', 'health_insurance'),
    ('tourist-faq-072', 'health_insurance'),
    ('tourist-faq-068', 'travel_safety'),
    ('tourist-faq-069', 'travel_safety'),
    ('tourist-faq-070', 'travel_safety'),
    ('tourist-faq-073', 'local_transport'),
    ('tourist-faq-074', 'local_transport'),
    ('tourist-faq-075', 'local_transport'),
    ('tourist-faq-076', 'local_transport'),
    ('tourist-faq-077', 'local_transport'),
    ('tourist-faq-078', 'local_transport'),
    ('tourist-faq-079', 'local_transport'),
    ('tourist-faq-080', 'local_transport'),
    ('tourist-faq-081', 'planning_budget'),
    ('tourist-faq-082', 'planning_budget'),
    ('tourist-faq-083', 'planning_budget'),
    ('tourist-faq-084', 'planning_budget'),
    ('tourist-faq-085', 'planning_budget'),
    ('tourist-faq-086', 'planning_budget'),
    ('tourist-faq-056', 'local_rules_culture'),
    ('tourist-faq-089', 'local_rules_culture'),
    ('tourist-faq-090', 'local_rules_culture'),
    ('tourist-faq-091', 'local_rules_culture'),
    ('tourist-faq-092', 'local_rules_culture'),
    ('tourist-faq-093', 'local_rules_culture'),
    ('tourist-faq-098', 'local_rules_culture'),
    ('tourist-faq-094', 'special_travel_needs'),
    ('tourist-faq-095', 'special_travel_needs'),
    ('tourist-faq-096', 'special_travel_needs'),
    ('tourist-faq-097', 'special_travel_needs'),
    ('tourist-faq-100', 'special_travel_needs'),
    ('tourist-faq-031', 'travel_problems'),
    ('tourist-faq-034', 'travel_problems'),
    ('tourist-faq-044', 'travel_problems'),
    ('tourist-faq-047', 'travel_problems'),
    ('tourist-faq-088', 'travel_problems'),
    ('tourist-faq-099', 'travel_problems');

UPDATE help_articles
SET category_id = help_category_article_remap.category_id,
    updated_at = now()
FROM help_category_article_remap
WHERE help_articles.id = help_category_article_remap.article_id;

DELETE FROM help_categories
WHERE id IN (
    'documents_visas_entry',
    'airport_flights_baggage',
    'booking_accommodation',
    'money_cards_connectivity',
    'health_safety_insurance',
    'route_budget_planning',
    'local_rules_culture_special'
)
AND NOT EXISTS (
    SELECT 1
    FROM help_articles
    WHERE help_articles.category_id = help_categories.id
);
