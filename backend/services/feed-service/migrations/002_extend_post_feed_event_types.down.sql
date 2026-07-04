-- Keep rollback data-safe: narrowing this constraint can fail after new event
-- rows have been written and would break already accepted feed interactions.
ALTER TABLE post_feed_events
    DROP CONSTRAINT IF EXISTS post_feed_events_event_type_check;

ALTER TABLE post_feed_events
    ADD CONSTRAINT post_feed_events_event_type_check
    CHECK ((event_type = ANY (ARRAY[
        'impression'::text,
        'click'::text,
        'dwell'::text,
        'like'::text,
        'comment'::text,
        'share'::text,
        'subscribe'::text,
        'hide'::text,
        'not_interested'::text,
        'report'::text
    ])));
