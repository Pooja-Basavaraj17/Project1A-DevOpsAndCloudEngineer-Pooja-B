-- EXPAND PHASE: Add new encrypted_email column alongside existing email
-- This migration is backward compatible: App V(N-1) ignores the new column

ALTER TABLE customer_profiles
  ADD COLUMN encrypted_email BYTEA;

CREATE INDEX CONCURRENTLY idx_customer_encrypted_email
  ON customer_profiles (encrypted_email);

INSERT INTO schema_audit_log (migration_id, description, executed_by, phase)
VALUES ('V2.0', 'Add encrypted_email column', current_user, 'EXPAND');

-- IMPORTANT: Do NOT drop the old email column yet.
-- That happens in V2.2 (CONTRACT phase) after all services migrate.
