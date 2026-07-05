call create_feature_flags_table('onboarding');
call create_feature_flags_table('payment');

with inserted as (
    insert into onboarding_feature_flags
        (code, created_by, updated_at, updated_by, name, "group", "type", enabled, action_start_date, action_end_date, value, is_deleted)
    values
        (
            'SKIP_SENDING_PHONE_OTP',
            'system',
            now(),
            'system',
            'Skip sending phone OTP for selected phones',
            'Testing bypasses',
            'ARRAY_STRING',
            false,
            date_trunc('minute', now()),
            null,
            '{}'::text[],
            false
        ),
        (
            'SKIP_SENDING_EMAIL_OTP',
            'system',
            now(),
            'system',
            'Skip sending email OTP for selected emails',
            'Testing bypasses',
            'ARRAY_STRING',
            false,
            date_trunc('minute', now()),
            null,
            '{}'::text[],
            false
        )
    on conflict (code) do nothing
    returning code, name, "group", "type", enabled, action_start_date, action_end_date, value, is_deleted
)
insert into onboarding_feature_flags_history
    (code, updated_at, updated_by, name, "group", "type", enabled, action_start_date, action_end_date, value, is_deleted)
select
    code,
    now(),
    'system',
    name,
    "group",
    "type",
    enabled,
    action_start_date,
    action_end_date,
    value,
    is_deleted
from inserted;

with inserted as (
    insert into payment_feature_flags
        (code, created_by, updated_at, updated_by, name, "group", "type", enabled, action_start_date, action_end_date, value, is_deleted)
    values
        (
            'SKIP_PAYMENT',
            'system',
            now(),
            'system',
            'Skip payment for selected user emails',
            'Testing bypasses',
            'ARRAY_STRING',
            false,
            date_trunc('minute', now()),
            null,
            '{}'::text[],
            false
        )
    on conflict (code) do nothing
    returning code, name, "group", "type", enabled, action_start_date, action_end_date, value, is_deleted
)
insert into payment_feature_flags_history
    (code, updated_at, updated_by, name, "group", "type", enabled, action_start_date, action_end_date, value, is_deleted)
select
    code,
    now(),
    'system',
    name,
    "group",
    "type",
    enabled,
    action_start_date,
    action_end_date,
    value,
    is_deleted
from inserted;
