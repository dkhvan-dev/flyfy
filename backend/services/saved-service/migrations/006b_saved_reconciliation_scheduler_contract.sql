-- Run after every Saved instance understands the scheduler columns. Validation
-- is online for reads/writes and bounded so deployment automation can retry it.
SET lock_timeout = '5s';
SET statement_timeout = '5min';

ALTER TABLE saved_content_projections
    VALIDATE CONSTRAINT saved_content_projections_reconciliation_lease_v1_check;
ALTER TABLE saved_content_projections
    VALIDATE CONSTRAINT saved_content_projections_reconciliation_schedule_v1_check;
ALTER TABLE saved_content_projections
    VALIDATE CONSTRAINT saved_content_projections_reconciliation_quarantine_v1_check;
ALTER TABLE saved_content_projections
    VALIDATE CONSTRAINT saved_content_projections_reconciliation_fail_closed_v1_check;
ALTER TABLE saved_content_projections
    VALIDATE CONSTRAINT saved_content_projections_public_title_check;
