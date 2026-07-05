-- MIGRATE PHASE: Backfill encrypted_email from existing email column
-- Run as a throttled batch job to avoid production impact

DO $$
DECLARE
    batch_size INT := 500;
    total_migrated INT := 0;
    batch_count INT;
BEGIN
    LOOP
        UPDATE customer_profiles
        SET encrypted_email = pgp_sym_encrypt(email, current_setting('app.encryption_key'))
        WHERE encrypted_email IS NULL
        AND id IN (
            SELECT id FROM customer_profiles
            WHERE encrypted_email IS NULL
            LIMIT batch_size
            FOR UPDATE SKIP LOCKED
        );

        GET DIAGNOSTICS batch_count = ROW_COUNT;
        total_migrated := total_migrated + batch_count;
        RAISE NOTICE 'Migrated % rows (total: %)', batch_count, total_migrated;

        EXIT WHEN batch_count = 0;
        PERFORM pg_sleep(0.1); -- Throttle: 100ms pause between batches
    END LOOP;
END $$;

-- Verify migration completeness before marking phase done
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM customer_profiles WHERE encrypted_email IS NULL AND email IS NOT NULL) THEN
        RAISE EXCEPTION 'Migration incomplete: rows with email but no encrypted_email';
    END IF;
END $$;
