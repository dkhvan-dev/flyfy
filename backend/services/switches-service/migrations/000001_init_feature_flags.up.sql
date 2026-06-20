create extension if not exists pg_trgm;

create table if not exists dict_domains (
    id bigserial primary key not null,
    created_at timestamp not null default now(),
    created_by varchar(100) not null,
    updated_at timestamp,
    updated_by varchar(100),
    code varchar(70) unique not null,
    description varchar(100) not null
);

create or replace procedure create_feature_flags_table(p_prefix text)
language plpgsql
as $$
declare
    ff_table_name text := lower(p_prefix) || '_feature_flags';
    ff_history_table_name text := lower(p_prefix) || '_feature_flags_history';
begin
    execute format(
        'create table if not exists %I (
            code varchar(70) primary key not null,
            created_at timestamp not null default now(),
            created_by varchar(100) not null,
            updated_at timestamp,
            updated_by varchar(100),
            name varchar(100) not null,
            "group" varchar(100) not null,
            "type" varchar(30) not null,
            enabled boolean not null default true,
            action_start_date timestamp not null default date_trunc(''minute'', now()),
            action_end_date timestamp,
            value text[] not null default ''{}'',
            is_deleted boolean not null default false
        )',
        ff_table_name
    );

    execute format('create index if not exists %I on %I("group")', 'idx_' || ff_table_name || '_group', ff_table_name);
    execute format('create index if not exists %I on %I(action_start_date)', 'idx_' || ff_table_name || '_action_start_date', ff_table_name);
    execute format('create index if not exists %I on %I(action_end_date)', 'idx_' || ff_table_name || '_action_end_date', ff_table_name);
    execute format('create index if not exists %I on %I using gin(name gin_trgm_ops)', 'idx_' || ff_table_name || '_name_trgm', ff_table_name);

    execute format(
        'create table if not exists %I (
            id bigint generated always as identity primary key not null,
            code varchar(70) not null references %I(code) on delete cascade,
            updated_at timestamp not null default now(),
            updated_by varchar(100) not null,
            name varchar(100) not null,
            "group" varchar(100) not null,
            "type" varchar(30) not null,
            enabled boolean not null default true,
            action_start_date timestamp not null default date_trunc(''minute'', now()),
            action_end_date timestamp,
            value text[] not null default ''{}'',
            is_deleted boolean not null default false
        )',
        ff_history_table_name,
        ff_table_name
    );

    execute format('create index if not exists %I on %I(code, updated_at desc, id desc)', 'idx_' || ff_history_table_name || '_code_updated_at', ff_history_table_name);
end;
$$;

insert into dict_domains(created_by, updated_at, updated_by, code, description)
values ('system', now(), 'system', 'CORE', 'Общие'),
       ('system', now(), 'system', 'ONBOARDING', 'Онбординг'),
       ('system', now(), 'system', 'ACTIVITY', 'Активности'),
       ('system', now(), 'system', 'EXCURSION', 'Экскурсии'),
       ('system', now(), 'system', 'CHAT', 'Чаты'),
       ('system', now(), 'system', 'MAP', 'Карта'),
       ('system', now(), 'system', 'PAYMENT', 'Платежи'),
       ('system', now(), 'system', 'ATTRACTION', 'Достопримечательности'),
       ('system', now(), 'system', 'EXCHANGE_RATE', 'Конвертер валют'),
       ('system', now(), 'system', 'FEED', 'Лента'),
       ('system', now(), 'system', 'NOTIFICATION', 'Уведомления'),
       ('system', now(), 'system', 'GUIDE', 'Гиды')
on conflict (code) do nothing;

call create_feature_flags_table('core');
call create_feature_flags_table('onboarding');
call create_feature_flags_table('activity');
call create_feature_flags_table('excursion');
call create_feature_flags_table('chat');
call create_feature_flags_table('map');
call create_feature_flags_table('payment');
call create_feature_flags_table('attraction');
call create_feature_flags_table('exchange_rate');
call create_feature_flags_table('feed');
call create_feature_flags_table('notification');
call create_feature_flags_table('guide');
