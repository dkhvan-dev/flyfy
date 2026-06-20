do $$
declare
    domain record;
    tech_break_table_name text;
begin
    for domain in select code from dict_domains loop
        tech_break_table_name := lower(domain.code) || '_tech_breaks';
        execute format('drop index if exists %I', 'idx_' || tech_break_table_name || '_active_window');
        execute format('drop index if exists %I', 'idx_' || tech_break_table_name || '_scope_codes_gin');
        execute format('drop index if exists %I', 'idx_' || tech_break_table_name || '_exclude_emails_gin');
        execute format('drop index if exists %I', 'idx_' || tech_break_table_name || '_exclude_nicknames_gin');
    end loop;
end;
$$;
