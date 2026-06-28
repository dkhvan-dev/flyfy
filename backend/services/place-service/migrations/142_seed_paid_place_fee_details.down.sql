UPDATE places
SET
    visit_info = visit_info - 'feeDetails',
    updated_at = NOW()
WHERE visit_info ? 'feeDetails'
  AND EXISTS (
      SELECT 1
      FROM jsonb_array_elements(visit_info->'feeDetails') AS fee(item)
      WHERE fee.item->>'sortOrder' = '10'
        AND fee.item->>'isApproximate' = 'true'
        AND fee.item->'title'->>'en' IN (
            'Museum or heritage ticket',
            'Attraction ticket',
            'Tasting or experience ticket',
            'Natural area access',
            'Entry or basic access'
        )
  );
