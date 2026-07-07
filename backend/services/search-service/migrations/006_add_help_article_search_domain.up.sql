ALTER TABLE search_documents
    DROP CONSTRAINT IF EXISTS search_documents_domain_check;

ALTER TABLE search_documents
    ADD CONSTRAINT search_documents_domain_check CHECK (
        domain IN ('activity', 'excursion', 'place', 'guide', 'community', 'user', 'help_article')
    ) NOT VALID;

ALTER TABLE search_documents
    VALIDATE CONSTRAINT search_documents_domain_check;
