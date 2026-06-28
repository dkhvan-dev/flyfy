DELETE FROM support_saved_replies
WHERE id IN (
    'account_login_issue',
    'account_profile_update',
    'activity_meeting_point',
    'activity_cancellation_policy',
    'excursion_booking_question',
    'excursion_guide_contact',
    'place_hours_or_price_check',
    'place_info_correction',
    'payment_refund_status',
    'payment_failed_charge',
    'currency_rate_notice',
    'technical_app_issue',
    'technical_notifications_issue',
    'technical_need_more_details'
);
