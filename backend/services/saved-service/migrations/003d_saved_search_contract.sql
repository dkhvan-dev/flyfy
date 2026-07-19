-- Manual contract phase. This file intentionally does not end in .up.sql, so
-- the automatic migrator cannot validate before the bounded backfill finishes.
ALTER TABLE saved_content_projections
    VALIDATE CONSTRAINT saved_content_projections_search_parity_v1_check;
