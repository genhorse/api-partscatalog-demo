-- ============================================================================
-- Version: v1.1.0
-- Delta: 01-schema.sql
-- Feature: Base Schema (Triad Search Engine)
-- Owner: Gennady Konev
-- Date: 2026-01-25
-- ============================================================================

-- Schema version function
CREATE OR REPLACE FUNCTION get_schema_version() 
RETURNS TEXT AS $$
BEGIN
    RETURN 'v1.1.0';
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- 1. Data Schema
CREATE TABLE IF NOT EXISTS parts_catalog (
    id SERIAL PRIMARY KEY,
    part_number TEXT NOT NULL,
    description TEXT,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Index table for Triad-based search
CREATE TABLE IF NOT EXISTS triad_index (
    triad_hash INT NOT NULL,
    part_id INT REFERENCES parts_catalog(id) ON DELETE CASCADE
);

-- Fast lookup index
CREATE INDEX IF NOT EXISTS idx_triad_hash ON triad_index(triad_hash);

-- 2. Indexing Trigger
CREATE OR REPLACE FUNCTION trigger_index_triads()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        DELETE FROM triad_index WHERE part_id = OLD.id;
    END IF;
    
    INSERT INTO triad_index (triad_hash, part_id)
    SELECT DISTINCT abs(hashtext(substring(NEW.part_number from i for 3))), NEW.id
    FROM generate_series(1, length(NEW.part_number) - 2) AS i;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_parts_catalog_index ON parts_catalog;
CREATE TRIGGER trg_parts_catalog_index
AFTER INSERT OR UPDATE ON parts_catalog
FOR EACH ROW EXECUTE FUNCTION trigger_index_triads();

-- 3. Universal API Router
CREATE OR REPLACE FUNCTION handle_request(p_method TEXT, p_query TEXT, p_payload JSONB)
RETURNS JSONB AS $$
DECLARE
    v_result JSONB;
BEGIN
    CASE p_method
        WHEN 'GET' THEN
            SELECT jsonb_build_object(
                'status', 'success',
                'data', COALESCE(jsonb_agg(res), '[]'::jsonb)
            ) INTO v_result
            FROM (
                SELECT id, part_number, description,
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

-- 4. Readiness Marker (for healthcheck)
-- FIXED: Added PRIMARY KEY for ON CONFLICT to work
CREATE TABLE IF NOT EXISTS startup_completed (
    id INT PRIMARY KEY
);
