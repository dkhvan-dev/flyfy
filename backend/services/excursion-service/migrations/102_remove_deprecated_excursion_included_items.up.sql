DELETE FROM excursion_offer_included_items
WHERE LOWER(BTRIM(SPLIT_PART(item_text, ':', 1))) IN (
    'guide',
    'photo',
    'photos',
    'гид',
    'фото'
);

DELETE FROM excursion_included_items
WHERE LOWER(BTRIM(SPLIT_PART(item_text, ':', 1))) IN (
    'guide',
    'photo',
    'photos',
    'гид',
    'фото'
);
