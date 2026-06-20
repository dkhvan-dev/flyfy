do $$
declare
    domain record;
    history_table_name text;
begin
    for domain in select code from dict_domains loop
        history_table_name := lower(domain.code) || '_feature_flags_history';
        execute format('drop index if exists %I', 'idx_' || history_table_name || '_code_updated_at');
    end loop;
end;
$$;
