delete from onboarding_feature_flags
where code in (
    'SKIP_SENDING_PHONE_OTP',
    'SKIP_SENDING_EMAIL_OTP'
);

delete from payment_feature_flags
where code in (
    'SKIP_PAYMENT'
);
