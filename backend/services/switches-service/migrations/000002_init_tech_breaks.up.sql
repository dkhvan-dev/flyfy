create extension if not exists pg_trgm;

create table if not exists dict_tech_break_scopes (
    id bigserial primary key not null,
    created_at timestamp not null default now(),
    created_by varchar(100) not null,
    updated_at timestamp,
    updated_by varchar(100),
    code varchar(70) not null,
    name varchar(255) not null,
    domain_code varchar(70) not null references dict_domains(code)
);

create unique index if not exists udx_dict_tech_break_scopes_domain_code
    on dict_tech_break_scopes(code, domain_code);

create or replace procedure create_tech_breaks_table(p_prefix text)
language plpgsql
as $$
declare
    tech_break_table_name text := lower(p_prefix) || '_tech_breaks';
begin
    execute format(
        'create table if not exists %I (
            id bigint generated always as identity primary key not null,
            created_at timestamp not null default now(),
            created_by varchar(100) not null,
            updated_at timestamp,
            updated_by varchar(100),
            name text unique not null,
            enabled boolean not null default false,
            action_start_date timestamp not null default date_trunc(''minute'', now()),
            action_end_date timestamp,
            exclude_emails text[] not null default ''{}'',
            exclude_nicknames text[] not null default ''{}'',
            scope_codes text[] not null default ''{}''
        )',
        tech_break_table_name
    );

    execute format('create index if not exists %I on %I(action_start_date)', 'idx_' || tech_break_table_name || '_action_start_date', tech_break_table_name);
    execute format('create index if not exists %I on %I(action_end_date)', 'idx_' || tech_break_table_name || '_action_end_date', tech_break_table_name);
    execute format('create index if not exists %I on %I(action_start_date, action_end_date) where enabled is true', 'idx_' || tech_break_table_name || '_active_window', tech_break_table_name);
    execute format('create index if not exists %I on %I using gin(scope_codes)', 'idx_' || tech_break_table_name || '_scope_codes_gin', tech_break_table_name);
    execute format('create index if not exists %I on %I using gin(exclude_emails)', 'idx_' || tech_break_table_name || '_exclude_emails_gin', tech_break_table_name);
    execute format('create index if not exists %I on %I using gin(exclude_nicknames)', 'idx_' || tech_break_table_name || '_exclude_nicknames_gin', tech_break_table_name);
    execute format('create index if not exists %I on %I using gin(name gin_trgm_ops)', 'idx_' || tech_break_table_name || '_name_trgm', tech_break_table_name);
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
       ('system', now(), 'system', 'PLACE', 'Достопримечательности'),
       ('system', now(), 'system', 'EXCHANGE_RATE', 'Конвертер валют'),
       ('system', now(), 'system', 'FEED', 'Лента'),
       ('system', now(), 'system', 'NOTIFICATION', 'Уведомления'),
       ('system', now(), 'system', 'GUIDE', 'Гиды')
on conflict (code) do nothing;

insert into dict_tech_break_scopes(created_by, code, name, domain_code)
values ('system', 'REGISTRATION', 'Регистрация', 'ONBOARDING'),
       ('system', 'AUTHORIZATION', 'Авторизация', 'ONBOARDING'),
       ('system', 'EDIT_PROFILE', 'Редактирование профиля', 'ONBOARDING'),
       ('system', 'GENERATION_QR_PROFILE', 'Генерация QR профиля', 'ONBOARDING'),
       ('system', 'SCAN_QR_PROFILE', 'Сканирование QR профиля', 'ONBOARDING'),
       ('system', 'EMAIL_OTP', 'Отправка OTP на email', 'CORE'),
       ('system', 'PHONE_OTP', 'Отправка OTP на номер телефона', 'CORE'),
       ('system', 'UPLOAD_FILE', 'Загрузка файлов', 'CORE'),
       ('system', 'ALL_QR', 'Сканирование и генерация всех QR', 'CORE'),
       ('system', 'MODIFY_ACTIVITY', 'Создание/Редактирование активности', 'ACTIVITY'),
       ('system', 'MY_ACTIVITIES', 'Просмотр моих активностей', 'ACTIVITY'),
       ('system', 'GENERATION_QR_ACTIVITY', 'Генерация QR активности', 'ACTIVITY'),
       ('system', 'SCAN_QR_ACTIVITY', 'Сканирование QR активности', 'ACTIVITY'),
       ('system', 'MODIFY_EXCURSION', 'Создание/Редактирование экскурсии', 'EXCURSION'),
       ('system', 'MY_EXCURSION', 'Просмотр моих экскурсий', 'EXCURSION'),
       ('system', 'GENERATION_QR_EXCURSION', 'Генерация QR экскурсии', 'EXCURSION'),
       ('system', 'SCAN_QR_EXCURSION', 'Сканирование QR экскурсии', 'EXCURSION'),
       ('system', 'MY_POSTS', 'Просмотр моих постов', 'FEED'),
       ('system', 'MY_STORIES', 'Просмотр моих историй', 'FEED'),
       ('system', 'CREATE_STORY', 'Создание истории', 'FEED'),
       ('system', 'MODIFY_POST', 'Создание/Редактирование поста', 'FEED'),
       ('system', 'COMMUNITIES', 'Просмотр сообществ', 'FEED'),
       ('system', 'MODIFY_COMMUNITY', 'Создание/Редактирование сообщества', 'FEED'),
       ('system', 'MODIFY_PLACE', 'Создание/Редактирование достопримечательности', 'PLACE'),
       ('system', 'CREATE_GUIDE_STATUS', 'Создание заявки на статус гида', 'GUIDE')
on conflict do nothing;

call create_tech_breaks_table('core');
call create_tech_breaks_table('onboarding');
call create_tech_breaks_table('activity');
call create_tech_breaks_table('excursion');
call create_tech_breaks_table('chat');
call create_tech_breaks_table('map');
call create_tech_breaks_table('payment');
call create_tech_breaks_table('place');
call create_tech_breaks_table('exchange_rate');
call create_tech_breaks_table('feed');
call create_tech_breaks_table('notification');
call create_tech_breaks_table('guide');
