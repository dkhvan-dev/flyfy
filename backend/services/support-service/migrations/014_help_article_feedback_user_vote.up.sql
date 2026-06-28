ALTER TABLE help_article_feedback
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ;

UPDATE help_article_feedback
SET updated_at = COALESCE(updated_at, created_at, now())
WHERE updated_at IS NULL;

ALTER TABLE help_article_feedback
    ALTER COLUMN updated_at SET DEFAULT now(),
    ALTER COLUMN updated_at SET NOT NULL;

WITH ranked_feedback AS (
    SELECT
        id,
        row_number() over (
            PARTITION BY article_id, user_id
            ORDER BY updated_at DESC, created_at DESC, id DESC
        ) AS row_number
    FROM help_article_feedback
)
DELETE FROM help_article_feedback
USING ranked_feedback
WHERE help_article_feedback.id = ranked_feedback.id
  AND ranked_feedback.row_number > 1;

CREATE UNIQUE INDEX IF NOT EXISTS idx_help_article_feedback_article_user
    ON help_article_feedback(article_id, user_id);
