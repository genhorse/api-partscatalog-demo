#!/usr/bin/env bash
# ================================================================================
# Migration Script for Parts Catalog Database
# Oracle OFS Style - Versioned Deltas with Rollback Support
# Owner: Gennady Konev
# ================================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_HOST="${DB_HOST:-}"
DB_PORT="${DB_PORT:-}"
DB_NAME="${DB_NAME:-parts_catalog}"
DB_USER="${DB_USER:-admin}"
DB_PASSWORD="${DB_PASSWORD:-password}"

export PGPASSWORD="$DB_PASSWORD"

# Build psql command (use local socket if no host specified)
if [ -z "$DB_HOST" ]; then
    PSQL_CMD="psql -U $DB_USER -d $DB_NAME"
else
    PSQL_CMD="psql -h $DB_HOST -p ${DB_PORT:-5432} -U $DB_USER -d $DB_NAME"
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Get current schema version from database
get_current_version() {
    $PSQL_CMD -t -c "SELECT CASE WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'get_schema_version') THEN get_schema_version() ELSE 'v0.0.0' END;" 2>/dev/null | tr -d ' ' || echo "v0.0.0"
}

# Compare versions (returns 0 if v1 >= v2)
version_gte() {
    [ "$1" = "$2" ] || [ "$(printf '%s\n' "$2" "$1" | sort -V | head -n1)" = "$2" ]
}

# Show current status
cmd_status() {
    log_info "Database: $DB_NAME"
    log_info "Current schema version: $(get_current_version)"
    
    echo ""
    echo "Available versions:"
    for dir in "$SCRIPT_DIR"/v*/; do
        if [ -d "$dir" ]; then
            version=$(basename "$dir")
            echo "  - $version"
        fi
    done
}

# Run upgrade migrations
cmd_upgrade() {
    local target_version="$1"
    local current=$(get_current_version)
    
    log_info "Current version: $current"
    
    # Find all version directories and sort them
    for dir in $(ls -d "$SCRIPT_DIR"/v*/ 2>/dev/null | sort -V); do
        version=$(basename "$dir")
        
        # Skip if already at or beyond this version
        if version_gte "$current" "$version"; then
            continue
        fi
        
        # If target specified, stop when reached
        if [ -n "$target_version" ] && ! version_gte "$target_version" "$version"; then
            break
        fi
        
        log_info "Migrating to $version..."
        
        # Execute all SQL files in version directory (sorted, exclude down scripts)
        for sql_file in $(ls "$dir"/*.sql 2>/dev/null | grep -v down | sort -V); do
            if [ -f "$sql_file" ]; then
                log_info "  Applying: $(basename "$sql_file")"
                $PSQL_CMD -f "$sql_file"
            fi
        done
        
        log_info "  ✓ Version $version applied"
    done
    
    log_info "Migration complete. Current version: $(get_current_version)"
}

# Run downgrade (one version back)
cmd_downgrade() {
    local current=$(get_current_version)
    
    if [ "$current" = "v0.0.0" ] || [ "$current" = "v1.1.0" ]; then
        log_error "Cannot downgrade from $current"
        exit 1
    fi
    
    # Find the previous version directory
    local prev_version=""
    for dir in $(ls -d "$SCRIPT_DIR"/v*/ 2>/dev/null | sort -V); do
        version=$(basename "$dir")
        if version_gte "$current" "$version" && [ "$version" != "$current" ]; then
            prev_version="$version"
        fi
    done
    
    if [ -z "$prev_version" ]; then
        log_error "No previous version found"
        exit 1
    fi
    
    log_info "Downgrading from $current to $prev_version..."
    
    # Find and execute down script for current version
    local current_dir="$SCRIPT_DIR/$current"
    for down_file in "$current_dir"/*-down.sql; do
        if [ -f "$down_file" ]; then
            log_info "  Applying: $(basename "$down_file")"
            $PSQL_CMD -f "$down_file"
        fi
    done
    
    log_info "Downgrade complete. Current version: $(get_current_version)"
}

# Validate schema and data
cmd_validate() {
    log_info "Running validation checks..."
    
    if [ -f "$SCRIPT_DIR/validators/check_schema.sql" ]; then
        log_info "  Checking schema structure..."
        $PSQL_CMD -f "$SCRIPT_DIR/validators/check_schema.sql"
        log_info "  ✓ Schema validation passed"
    fi
    
    if [ -f "$SCRIPT_DIR/validators/check_data.sql" ]; then
        log_info "  Checking data integrity..."
        $PSQL_CMD -f "$SCRIPT_DIR/validators/check_data.sql"
        log_info "  ✓ Data validation passed"
    fi
    
    log_info "All validations passed!"
}

# Show help
cmd_help() {
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  status              Show current schema version"
    echo "  upgrade [version]   Apply migrations up to version (or latest)"
    echo "  downgrade           Rollback one version"
    echo "  validate            Run schema and data validation"
    echo "  help                Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  DB_HOST             Database host (default: local socket)"
    echo "  DB_PORT             Database port (default: 5432)"
    echo "  DB_NAME             Database name (default: parts_catalog)"
    echo "  DB_USER             Database user (default: admin)"
    echo "  DB_PASSWORD         Database password (default: password)"
    echo ""
    echo "Examples:"
    echo "  ./migrate.sh status"
    echo "  ./migrate.sh upgrade"
    echo "  ./migrate.sh upgrade v1.2.0"
    echo "  ./migrate.sh downgrade"
    echo "  ./migrate.sh validate"
}

# Main command dispatcher
case "${1:-help}" in
    status)   cmd_status ;;
    upgrade)  cmd_upgrade "$2" ;;
    downgrade) cmd_downgrade ;;
    validate) cmd_validate ;;
    help)     cmd_help ;;
    *)        log_error "Unknown command: $1"; cmd_help; exit 1 ;;
esac
