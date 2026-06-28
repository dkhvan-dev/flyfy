DELETE FROM help_articles
WHERE id LIKE 'app-faq-%';

DELETE FROM help_category_translations
WHERE category_id IN (
    'app_getting_started',
    'app_account_profile',
    'app_activities_excursions',
    'app_chats_support',
    'app_services_notifications'
)
AND NOT EXISTS (
    SELECT 1
    FROM help_articles
    WHERE help_articles.category_id = help_category_translations.category_id
);

DELETE FROM help_categories
WHERE id IN (
    'app_getting_started',
    'app_account_profile',
    'app_activities_excursions',
    'app_chats_support',
    'app_services_notifications'
)
AND NOT EXISTS (
    SELECT 1
    FROM help_articles
    WHERE help_articles.category_id = help_categories.id
);
