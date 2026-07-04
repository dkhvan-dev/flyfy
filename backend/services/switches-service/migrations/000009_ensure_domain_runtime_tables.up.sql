DO $$
DECLARE
    domain_record RECORD;
BEGIN
    FOR domain_record IN SELECT code FROM dict_domains LOOP
        CALL create_feature_flags_table(domain_record.code);
        CALL create_tech_breaks_table(domain_record.code);
    END LOOP;
END $$;
