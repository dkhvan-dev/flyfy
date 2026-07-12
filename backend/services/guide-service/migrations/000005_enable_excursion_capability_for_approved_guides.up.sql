UPDATE guide_profiles AS profile
SET is_excursion_guide_available = TRUE
WHERE profile.status = 'ACTIVE'
  AND profile.is_private_guide_available = FALSE
  AND profile.is_activity_host_available = FALSE
  AND profile.is_excursion_guide_available = FALSE
  AND EXISTS (
      SELECT 1
      FROM guide_verification_requests AS verification
      WHERE verification.guide_profile_id = profile.id
        AND verification.status = 'APPROVED'
  );
