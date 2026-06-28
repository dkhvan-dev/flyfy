DROP INDEX IF EXISTS idx_help_article_feedback_article_user;

ALTER TABLE help_article_feedback
    DROP COLUMN IF EXISTS updated_at;
