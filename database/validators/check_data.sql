-- ============================================================================
-- Data Validation Script
-- Verifies data integrity and consistency
-- Owner: Gennady Konev
-- ============================================================================

DO $$
DECLARE
    v_parts_count INT;
    v_triad_count INT;
    v_orphan_count INT;
BEGIN
    -- Check parts_catalog has data
    SELECT COUNT(*) INTO v_parts_count FROM parts_catalog;
    
    IF v_parts_count = 0 THEN
        RAISE WARNING 'parts_catalog is empty - this may be expected for fresh install';
    END IF;
    
    -- Check triad_index has data (if parts exist)
    IF v_parts_count > 0 THEN
        SELECT COUNT(*) INTO v_triad_count FROM triad_index;
        
        IF v_triad_count = 0 THEN
            RAISE EXCEPTION 'triad_index is empty but parts_catalog has data - trigger may be broken';
        END IF;
    END IF;
    
    -- Check for orphaned triad_index entries
    SELECT COUNT(*) INTO v_orphan_count
    FROM triad_index t
    LEFT JOIN parts_catalog p ON t.part_id = p.id
    WHERE p.id IS NULL;
    
    IF v_orphan_count > 0 THEN
        RAISE WARNING 'Found % orphaned triad_index entries', v_orphan_count;
    END IF;
    
    -- Check i18n consistency (if part_descriptions exists)
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'part_descriptions') THEN
        DECLARE
            v_missing_default INT;
        BEGIN
            -- Check every part has at least one description
            SELECT COUNT(*) INTO v_missing_default
            FROM parts_catalog p
            WHERE NOT EXISTS (
                SELECT 1 FROM part_descriptions pd WHERE pd.part_id = p.id
            );
            
            IF v_missing_default > 0 THEN
                RAISE WARNING '% parts missing i18n descriptions', v_missing_default;
            END IF;
        END;
    END IF;
    
    RAISE NOTICE 'Data validation PASSED';
END $$;
