DELETE FROM help_articles
WHERE id LIKE 'tourist-faq-%';

DELETE FROM help_categories
WHERE id IN ('documents_visas_entry', 'airport_flights_baggage', 'booking_accommodation', 'money_cards_connectivity', 'health_safety_insurance', 'local_transport', 'route_budget_planning', 'local_rules_culture_special')
  AND NOT EXISTS (
      SELECT 1
      FROM help_articles
      WHERE help_articles.category_id = help_categories.id
  );
