# Database Migration System

## Overview

Enterprise-grade database migration system following Oracle Field Service (OFS) practices.

## Structure

```bash
database/
├── v1.1.0/              # Base version (fresh install)
│   ├── 01-schema.sql    # Tables, functions, triggers
│   └── 02-seed-data.sql # 100k test records
├── v1.2.0/              # i18n feature delta
│   ├── 01-i18n-schema.sql       # part_descriptions table
│   ├── 01-i18n-schema-down.sql  # Rollback script
│   └── 03-seed-i18n.sql         # 600k i18n records
├── v1.3.0/              # Future: OpenID feature
├── migrate.sh           # Migration controller
├── docker-entrypoint-migrate.sh # Auto-migration for Docker
├── validators/          # Schema & data validation
│   ├── check_schema.sql
│   └── check_data.sql
└── README.md
```

## Key Principles

| Principle | Implementation |
|-----------|----------------|
| Version tracking | `get_schema_version()` function (no extra table) |
| Delta scripts | Numbered files per feature (01-*.sql, 02-*.sql) |
| Rollback | Single-step only (*-down.sql) |
| Validation | Built-in preconditions in each delta |
| Data preservation | Customer data never lost on upgrade/downgrade |

## Usage

### Environment Variables

```bash
export DB_HOST=localhost
export DB_PORT=5432
export DB_NAME=parts_catalog
export DB_USER=admin
export DB_PASSWORD=password
```

### Commands

```bash
# Check current version
./migrate.sh status

# Upgrade to latest version
./migrate.sh upgrade

# Upgrade to specific version
./migrate.sh upgrade v1.2.0

# Downgrade one version (emergency rollback)
./migrate.sh downgrade

# Validate schema and data
./migrate.sh validate
```

## For Integrators

### Fresh Install (New Customer)

```bash
docker compose up --build
# Applies v1.1.0 schema + seed data automatically
```

### Upgrade Existing Installation

```bash
# Customer has v1.1.0 with custom data
./migrate.sh upgrade v1.2.0
# No data loss - existing descriptions migrated to English
```

### Rollback (Emergency)

```bash
# Something went wrong with v1.2.0
./migrate.sh downgrade
# Returns to v1.1.0, preserves customer data
```

## Version History

| Version | Date | Feature | Owner |
|---------|------|---------|-------|
| v1.1.0 | 2026-01-25 | Triad Search Engine | G. Konev |
| v1.2.0 | 2026-03-08 | i18n (6 languages) | G. Konev |
| v1.3.0 | TBD | OpenID Connect (Google OAuth) | Planned |

## Support

For migration issues, contact the database owner.
