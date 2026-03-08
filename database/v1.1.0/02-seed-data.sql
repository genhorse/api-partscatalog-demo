-- ============================================================================
-- Version: v1.1.0
-- Delta: 02-seed-data.sql
-- Feature: Seed Data (100k records for high-load testing)
-- Owner: Gennady Konev
-- Date: 2026-01-25
-- Note: This may take 30-60 seconds depending on hardware
-- ============================================================================

-- Precondition: Schema must exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'parts_catalog') THEN
        RAISE EXCEPTION 'Schema not initialized. Run 01-schema.sql first.';
    END IF;
END $$;

-- Seed 100,000 records
INSERT INTO parts_catalog (part_number, description)
SELECT
    'PART-' || (100000 + n) || '-' || (CASE WHEN n % 3 = 0 THEN 'X' WHEN n % 3 = 1 THEN 'Y' ELSE 'Z' END),
    'Spare part #' || n || ' High-Load Test Seed'
FROM generate_series(1, 100000) n;

-- Mark startup as complete (signals Helidon that data is ready)
-- FIXED: Now works because startup_completed has PRIMARY KEY
INSERT INTO startup_completed (id) VALUES (1) ON CONFLICT (id) DO NOTHING;
