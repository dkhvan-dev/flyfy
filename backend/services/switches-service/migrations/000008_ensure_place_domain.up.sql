insert into dict_domains(created_by, updated_at, updated_by, code, description)
values ('system', now(), 'system', 'PLACE', 'Достопримечательности')
on conflict (code) do update
set description = excluded.description,
    updated_at = now(),
    updated_by = 'system';

call create_feature_flags_table('place');
call create_tech_breaks_table('place');

insert into dict_tech_break_scopes(created_by, updated_at, updated_by, code, name, domain_code)
values ('system', now(), 'system', 'MODIFY_PLACE', 'Создание/Редактирование достопримечательности', 'PLACE')
on conflict (code, domain_code) do update
set name = excluded.name,
    updated_at = now(),
    updated_by = 'system';
