drop trigger if exists trg_platform_personal_data_policy_history_truncate
    on platform_personal_data_policy_history;
drop trigger if exists trg_platform_personal_data_policy_history_update
    on platform_personal_data_policy_history;
drop trigger if exists trg_platform_personal_data_policy_state_truncate
    on platform_personal_data_policy_state;
drop trigger if exists trg_platform_personal_data_policy_state_delete
    on platform_personal_data_policy_state;
drop trigger if exists trg_platform_personal_data_policy_state_update
    on platform_personal_data_policy_state;

drop function if exists reject_platform_personal_data_policy_history_mutation();
drop function if exists reject_platform_personal_data_policy_state_removal();
drop function if exists enforce_platform_personal_data_policy_state_update();

drop table if exists platform_personal_data_policy_history;
drop table if exists platform_personal_data_policy_state;
