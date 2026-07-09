ALTER TABLE messages
    ADD COLUMN send_status TEXT NOT NULL DEFAULT 'SENT';

ALTER TABLE messages
    ADD CONSTRAINT chk_messages_send_status
        CHECK (send_status IN ('SENT', 'PENDING_ATTACHMENTS')) NOT VALID;

ALTER TABLE messages
    VALIDATE CONSTRAINT chk_messages_send_status;
