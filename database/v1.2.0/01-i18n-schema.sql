-- ============================================================================
-- Delta: 01-i18n-schema.sql
-- Version: v1.2.0
-- Feature: Internationalization (i18n) - Multi-language descriptions
-- Owner: Gennady Konev
-- Date: 2026-01-25
-- Languages: en, de, fr, es, it, uk
-- ============================================================================

-- Precondition: Check current schema version
DO $$
BEGIN
    IF get_schema_version() != 'v1.1.0' THEN
        RAISE EXCEPTION 'Invalid schema version. Expected v1.1.0, got %', 
                        get_schema_version();
    END IF;
END $$;

-- ============================================================================
-- i18n: Part Descriptions Table
-- Separates language-independent data (part_number) from translatable data
-- ============================================================================
CREATE TABLE part_descriptions (
    part_id INT NOT NULL REFERENCES parts_catalog(id) ON DELETE CASCADE,
    language_code CHAR(2) NOT NULL CHECK (language_code IN ('en', 'de', 'fr', 'es', 'it', 'uk')),
    description TEXT NOT NULL,
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (part_id, language_code)
);

-- Index for fast language lookup
CREATE INDEX idx_part_descriptions_lang ON part_descriptions(language_code, part_id);

-- ============================================================================
-- i18n: Migrate existing descriptions to English (default)
-- Preserves customer data during upgrade
-- ============================================================================
INSERT INTO part_descriptions (part_id, language_code, description, is_default)
SELECT id, 'en', COALESCE(description, ''), TRUE
FROM parts_catalog
WHERE description IS NOT NULL;

-- ============================================================================
-- i18n: Update handle_request() to support Accept-Language header
-- New signature: handle_request(p_method, p_query, p_payload, p_language)
-- ============================================================================
CREATE OR REPLACE FUNCTION handle_request(
    p_method TEXT, 
    p_query TEXT, 
    p_payload JSONB,
    p_language TEXT DEFAULT 'en'
)
RETURNS JSONB AS $$
DECLARE
    v_result JSONB;
    v_lang CHAR(2);
BEGIN
    -- Normalize language code (accept-Language: de-DE -> de)
    v_lang := SUBSTRING(COALESCE(p_language, 'en') FROM 1 FOR 2);
    
    -- Validate language code
    IF v_lang NOT IN ('en', 'de', 'fr', 'es', 'it', 'uk') THEN
        v_lang := 'en';  -- Fallback to default
    END IF;

    CASE p_method
        WHEN 'GET' THEN
            SELECT jsonb_build_object(
                'status', 'success',
                'data', COALESCE(jsonb_agg(res), '[]'::jsonb),
                'language', v_lang
            ) INTO v_result
            FROM (
                SELECT 
                    pc.id, 
                    pc.part_number, 
                    COALESCE(pd.description, pc.description) as description,
                    to_char(pc.updated_at, 'YYYY-MM-DD HH24:MI:SS') as last_update
                FROM parts_catalog pc
                LEFT JOIN part_descriptions pd 
                    ON pc.id = pd.part_id AND pd.language_code = v_lang
                WHERE pc.id IN (
                    SELECT part_id FROM triad_index
                    WHERE triad_hash = abs(hashtext(substring(p_query from 1 for 3)))
                )
                AND pc.part_number ILIKE '%' || COALESCE(p_query, '') || '%'
                ORDER BY pc.part_number LIMIT 50
            ) res;

        WHEN 'DELETE' THEN
            DELETE FROM parts_catalog WHERE id = p_query::INT;
            v_result := jsonb_build_object('status', 'deleted', 'id', p_query);

        WHEN 'POST' THEN 
            IF jsonb_typeof(p_payload) = 'array' THEN
                WITH inserted AS (
                    INSERT INTO parts_catalog (part_number, description)
                    SELECT x->>'part_number', x->>'description'
                    FROM jsonb_array_elements(p_payload) x
                    RETURNING id
                ),
                lang_insert AS (
                    INSERT INTO part_descriptions (part_id, language_code, description, is_default)
                    SELECT i.id, v_lang, x->>'description', TRUE
                    FROM jsonb_array_elements(p_payload) x, inserted i
                )
                SELECT jsonb_build_object('status', 'bulk_created', 'count', count(*), 'language', v_lang) 
                INTO v_result FROM inserted;
            ELSE
                WITH inserted AS (
                    INSERT INTO parts_catalog (part_number, description)
                    VALUES (p_payload->>'part_number', p_payload->>'description')
                    RETURNING id
                )
                INSERT INTO part_descriptions (part_id, language_code, description, is_default)
                SELECT i.id, v_lang, p_payload->>'description', TRUE FROM inserted i
                RETURNING jsonb_build_object('status', 'created', 'id', id, 'language', v_lang) INTO v_result;
            END IF;

        WHEN 'PUT' THEN 
            IF jsonb_typeof(p_payload) = 'array' THEN
                UPDATE parts_catalog p
                SET description = x.description,
                    updated_at = CURRENT_TIMESTAMP
                FROM jsonb_to_recordset(p_payload) AS x(id INT, description TEXT)
                WHERE p.id = x.id;
                
                UPDATE part_descriptions pd
                SET description = x.description
                FROM jsonb_to_recordset(p_payload) AS x(id INT, description TEXT)
                WHERE pd.part_id = x.id AND pd.language_code = v_lang;
                
                v_result := jsonb_build_object('status', 'bulk_updated', 'language', v_lang);
            ELSE
                UPDATE parts_catalog
                SET description = p_payload->>'description',
                    updated_at = CURRENT_TIMESTAMP
                WHERE id = (p_payload->>'id')::INT;
                
                UPDATE part_descriptions
                SET description = p_payload->>'description'
                WHERE part_id = (p_payload->>'id')::INT AND language_code = v_lang;
                
                v_result := jsonb_build_object('status', 'updated', 'id', p_payload->>'id', 'language', v_lang);
            END IF;

        ELSE
            v_result := jsonb_build_object('status', 'error', 'message', 'Method not allowed');
    END CASE;
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- Update Schema Version
-- ============================================================================
CREATE OR REPLACE FUNCTION get_schema_version() 
RETURNS TEXT AS $$
BEGIN
    RETURN 'v1.2.0';
END;
$$ LANGUAGE plpgsql IMMUTABLE;
