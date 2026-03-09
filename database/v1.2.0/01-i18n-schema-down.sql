-- ================================================================================
-- Delta: 01-i18n-schema-down.sql
-- Version: v1.2.0 (Rollback)
-- Feature: Internationalization (i18n) - Remove multi-language support
-- Owner: Gennady Konev
-- Date: 2026-01-25
-- Note: Rolls back to v1.1.0 schema
-- ================================================================================

-- Precondition: Check current schema version
DO $$
BEGIN
    IF get_schema_version() != 'v1.2.0' THEN
        RAISE EXCEPTION 'Invalid schema version. Expected v1.2.0, got %', 
                        get_schema_version();
    END IF;
END $$;

-- ================================================================================
-- i18n: Drop part_descriptions table
-- Preserves original descriptions in parts_catalog
-- ================================================================================
DROP TABLE IF EXISTS part_descriptions CASCADE;

-- ================================================================================
-- i18n: Revert handle_request() to v1.1.0 signature (3 parameters)
-- Removes language parameter support
-- ================================================================================
CREATE OR REPLACE FUNCTION handle_request(
    p_method TEXT, 
    p_query TEXT, 
    p_payload JSONB
)
RETURNS JSONB AS $$
DECLARE
    v_result JSONB;
BEGIN
    -- Normalize language code (fallback to English)
    -- In rollback, we always use English descriptions from parts_catalog
    
    CASE p_method
        WHEN 'GET' THEN
            SELECT jsonb_build_object(
                'status', 'success',
                'data', COALESCE(jsonb_agg(res), '[]'::jsonb)
            ) INTO v_result
            FROM (
                SELECT 
                    id, 
                    part_number, 
                    description,
                    to_char(updated_at, 'YYYY-MM-DD HH24:MI:SS') as last_update
                FROM parts_catalog
                WHERE id IN (
                    SELECT part_id FROM triad_index
                    WHERE triad_hash = abs(hashtext(substring(p_query from 1 for 3)))
                )
                AND part_number ILIKE '%' || COALESCE(p_query, '') || '%'
                ORDER BY part_number LIMIT 50
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
                )
                SELECT jsonb_build_object('status', 'bulk_created', 'count', count(*)) 
                INTO v_result FROM inserted;
            ELSE
                INSERT INTO parts_catalog (part_number, description)
                VALUES (p_payload->>'part_number', p_payload->>'description')
                RETURNING jsonb_build_object('status', 'created', 'id', id) INTO v_result;
            END IF;

        WHEN 'PUT' THEN 
            IF jsonb_typeof(p_payload) = 'array' THEN
                UPDATE parts_catalog p
                SET description = x.description,
                    updated_at = CURRENT_TIMESTAMP
                FROM jsonb_to_recordset(p_payload) AS x(id INT, description TEXT)
                WHERE p.id = x.id;
                
                v_result := jsonb_build_object('status', 'bulk_updated');
            ELSE
                UPDATE parts_catalog
                SET description = p_payload->>'description',
                    updated_at = CURRENT_TIMESTAMP
                WHERE id = (p_payload->>'id')::INT
                RETURNING jsonb_build_object('status', 'updated', 'id', id) INTO v_result;
            END IF;

        ELSE
            v_result := jsonb_build_object('status', 'error', 'message', 'Method not allowed');
    END CASE;
    
    RETURN v_result;
END;
$$ LANGUAGE plpgsql;

-- ================================================================================
-- Update Schema Version (back to v1.1.0)
-- ================================================================================
CREATE OR REPLACE FUNCTION get_schema_version() 
RETURNS TEXT AS $$
BEGIN
    RETURN 'v1.1.0';
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ================================================================================
-- Rollback Complete Notification
-- ================================================================================
DO $$
DECLARE
    v_parts_count INT;
BEGIN
    SELECT COUNT(*) INTO v_parts_count FROM parts_catalog;
    
    RAISE NOTICE 'Rollback to v1.1.0 complete. Parts preserved: %', v_parts_count;
    RAISE NOTICE 'i18n descriptions removed. Original descriptions retained in parts_catalog.';
END $$;
