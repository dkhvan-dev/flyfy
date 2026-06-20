do $$
declare
    domain record;
    tech_break_table_name text;
begin
    for domain in select code from dict_domains loop
        tech_break_table_name := lower(domain.code) || '_tech_breaks';
        execute format('create index if not exists %I on %I(action_start_date, action_end_date) where enabled is true', 'idx_' || tech_break_table_name || '_active_window', tech_break_table_name);
        execute format('create index if not exists %I on %I using gin(scope_codes)', 'idx_' || tech_break_table_name || '_scope_codes_gin', tech_break_table_name);
        execute format('create index if not exists %I on %I using gin(exclude_emails)', 'idx_' || tech_break_table_name || '_exclude_emails_gin', tech_break_table_name);
        execute format('create index if not exists %I on %I using gin(exclude_nicknames)', 'idx_' || tech_break_table_name || '_exclude_nicknames_gin', tech_break_table_name);
    end loop;
end;
$$;
