UPDATE places p
SET
    visit_info = p.visit_info - 'feeDetails',
    price_amount = CASE
        WHEN p.category IN ('BEACH','FOOD','MARKET','SHOPPING') THEN 0::numeric
        WHEN p.category = 'ENTERTAINMENT' THEN 2000::numeric
        ELSE 1000::numeric
    END,
    price_currency = 'KZT',
    updated_at = NOW()
WHERE p.country_code = 'KZ'
  AND p.source = 'IMPORT'
  AND COALESCE(p.visit_info, '{}'::jsonb) ? 'feeDetails'
  AND EXISTS (
      SELECT 1
      FROM jsonb_array_elements(COALESCE(p.visit_info, '{}'::jsonb)->'feeDetails') AS fee(item)
      WHERE (fee.item->>'sortOrder') ~ '^[0-9]+$'
        AND (fee.item->>'sortOrder')::int BETWEEN 1000 AND 1399
  );
