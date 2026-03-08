-- ============================================================================
-- Version: v1.2.0
-- Delta: 03-seed-i18n.sql
-- Feature: Seed i18n Descriptions (6 languages × 100k parts)
-- Owner: Gennady Konev
-- Date: 2026-01-25
-- Note: This may take 60-120 seconds depending on hardware
-- Languages: en, de, fr, es, it, uk
-- ============================================================================

-- Precondition: i18n schema must exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'part_descriptions') THEN
        RAISE EXCEPTION 'i18n schema not initialized. Run 01-i18n-schema.sql first.';
    END IF;
END $$;

-- ============================================================================
-- Generate i18n descriptions for all existing parts
-- Uses template-based translations (pattern matching for demo purposes)
-- ============================================================================

-- English (already exists from migration, skip)
-- German
INSERT INTO part_descriptions (part_id, language_code, description, is_default)
SELECT 
    pc.id, 
    'de', 
    'Ersatzteil #' || pc.id || ' Hochlast-Test Seed',
    FALSE
FROM parts_catalog pc
WHERE NOT EXISTS (
    SELECT 1 FROM part_descriptions pd 
    WHERE pd.part_id = pc.id AND pd.language_code = 'de'
);

-- French
INSERT INTO part_descriptions (part_id, language_code, description, is_default)
SELECT 
    pc.id, 
    'fr', 
    'Pièce de rechange #' || pc.id || ' Test haute charge',
    FALSE
FROM parts_catalog pc
WHERE NOT EXISTS (
    SELECT 1 FROM part_descriptions pd 
    WHERE pd.part_id = pc.id AND pd.language_code = 'fr'
);

-- Spanish
INSERT INTO part_descriptions (part_id, language_code, description, is_default)
SELECT 
    pc.id, 
    'es', 
    'Pieza de repuesto #' || pc.id || ' Prueba de alta carga',
    FALSE
FROM parts_catalog pc
WHERE NOT EXISTS (
    SELECT 1 FROM part_descriptions pd 
    WHERE pd.part_id = pc.id AND pd.language_code = 'es'
);

-- Italian
INSERT INTO part_descriptions (part_id, language_code, description, is_default)
SELECT 
    pc.id, 
    'it', 
    'Pezzo di ricambio #' || pc.id || ' Test ad alto carico',
    FALSE
FROM parts_catalog pc
WHERE NOT EXISTS (
    SELECT 1 FROM part_descriptions pd 
    WHERE pd.part_id = pc.id AND pd.language_code = 'it'
);

-- Ukrainian
INSERT INTO part_descriptions (part_id, language_code, description, is_default)
SELECT 
    pc.id, 
    'uk', 
    'Запасна частина #' || pc.id || ' Тест високого навантаження',
    FALSE
FROM parts_catalog pc
WHERE NOT EXISTS (
    SELECT 1 FROM part_descriptions pd 
    WHERE pd.part_id = pc.id AND pd.language_code = 'uk'
);

-- ============================================================================
-- Create index for fast language lookup
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_part_descriptions_lang 
ON part_descriptions(language_code, part_id);

-- ============================================================================
-- Verify i18n data
-- ============================================================================
DO $$
DECLARE
    v_total_parts INT;
    v_total_descriptions INT;
    v_expected INT;
BEGIN
    SELECT COUNT(*) INTO v_total_parts FROM parts_catalog;
    SELECT COUNT(*) INTO v_total_descriptions FROM part_descriptions;
    v_expected := v_total_parts * 6;  -- 6 languages
    
    RAISE NOTICE 'Parts: %, Descriptions: %, Expected: %', 
                 v_total_parts, v_total_descriptions, v_expected;
    
    IF v_total_descriptions < v_expected THEN
        RAISE WARNING 'Not all i18n descriptions created. Check constraints.';
    ELSE
        RAISE NOTICE 'i18n seed complete: 6 languages × % parts = % descriptions', 
                     v_total_parts, v_total_descriptions;
    END IF;
END $$;
