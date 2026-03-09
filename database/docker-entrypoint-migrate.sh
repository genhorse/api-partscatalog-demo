#!/bin/bash
# ================================================================================
# Auto-Migration Entry Point for PostgreSQL
# Wrapper around migrate.sh for Docker automation
# Owner: Gennady Konev
# ================================================================================

set -e

echo "================================================"
echo "  Database Auto-Migration System"
echo "  Oracle OFS Style"
echo "================================================"

DB_NAME="${POSTGRES_DB:-parts_catalog}"
MIGRATIONS_DIR="/opt/migrations"

# Wait for PostgreSQL to be ready (local connection during init)
echo "Waiting for PostgreSQL..."
until psql -U "$POSTGRES_USER" -d "$DB_NAME" -c "SELECT 1" > /dev/null 2>&1; do
    sleep 1
done
echo "PostgreSQL is ready!"

# Check if get_schema_version function exists (fresh install check)
VERSION_CHECK=$(psql -U "$POSTGRES_USER" -d "$DB_NAME" -t -c "SELECT CASE WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'get_schema_version') THEN 'exists' ELSE 'not_exists' END;" 2>/dev/null | tr -d ' ')

if [ "$VERSION_CHECK" = "not_exists" ]; then
    echo "Fresh install detected - applying base schema v1.1.0..."
    
    # Apply schema first (fast)
    psql -U "$POSTGRES_USER" -d "$DB_NAME" -f "$MIGRATIONS_DIR/v1.1.0/01-schema.sql"
    echo "  ✓ Schema v1.1.0 applied"
    
    # Apply seed data (slow - 30-60 seconds)
    echo "  Seeding 100k records..."
    psql -U "$POSTGRES_USER" -d "$DB_NAME" -f "$MIGRATIONS_DIR/v1.1.0/02-seed-data.sql"
    echo "  ✓ Seed data applied"
fi

# Run migrate.sh upgrade for any pending versions
echo "Running auto-migration..."
cd "$MIGRATIONS_DIR"
export DB_HOST=""
export DB_PORT=""
export DB_USER="$POSTGRES_USER"
export DB_PASSWORD="$POSTGRES_PASSWORD"
export DB_NAME="$DB_NAME"
bash ./migrate.sh upgrade || exit 1

echo "================================================"
echo "  Migration Complete!"
echo "  Schema version: $(psql -U "$POSTGRES_USER" -d "$DB_NAME" -t -c "SELECT get_schema_version();" 2>/dev/null | tr -d ' ')"
echo "  Triad index count: $(psql -U "$POSTGRES_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM triad_index;" 2>/dev/null | tr -d ' ')"
echo "================================================"

# DO NOT exec postgres here - let the main entrypoint continue
# The script runs as part of /docker-entrypoint-initdb.d/ which completes before postgres starts serving
