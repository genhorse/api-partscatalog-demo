# Database Migration System

## Overview

Enterprise-grade database migration system following Oracle Field Service (OFS) practices.

## Structure
```bash
database/
├── v1.1.0/           # Base version (fresh install)
│   └── 01-init.sql
├── v1.2.0/           # i18n feature delta
│   ├── 01-i18n-schema.sql
│   └── 01-i18n-schema-down.sql
├── v1.3.0/           # Future: OpenID feature
├── migrate.sh        # Migration controller
├── validators/       # Schema & data validation
└── README.md
```
## Key Principles

| Principle | Implementation |
|-----------|----------------|
| Version tracking | get_schema_version() function (no extra table) |
| Delta scripts | Numbered files per feature (01-*.sql, 02-*.sql) |
| Rollback | Single-step only (*-down.sql) |
| Validation | Built-in preconditions in each delta |
| Data preservation | Customer data never lost on upgrade/downgrade |

## Usage

### Environment Variables

export DB_HOST=localhost
export DB_PORT=5432
export DB_NAME=parts_catalog
export DB_USER=admin
export DB_PASSWORD=password

### Commands

# Check current version
```bash
./migrate.sh status
```
# Upgrade to latest version
```bash
./migrate.sh upgrade
```
# Upgrade to specific version
```bash
./migrate.sh upgrade v1.2.0
```
# Downgrade one version
```bash
./migrate.sh downgrade
```
# Validate schema and data
```bash
./migrate.sh validate
```
## For Integrators

### Fresh Install (New Customer)

```bash
psql -U admin -d parts_catalog -f v1.1.0/01-init.sql
```
### Upgrade Existing Installation

# Customer has v1.1.0 with custom data
```bash
./migrate.sh upgrade v1.2.0
```
# No data loss - existing descriptions migrated to English

### Rollback (Emergency)

# Something went wrong with v1.2.0
```bash
./migrate.sh downgrade
```
# Returns to v1.1.0, preserves customer data

## Version History

| Version | Date | Feature | Owner |
|---------|------|---------|-------|
| v1.1.0 | 2026-01-25 | Triad Search Engine | G. Konev |
| v1.2.0 | 2026-01-25 | i18n (6 languages) | G. Konev |
| v1.3.0 | TBD | OpenID Connect | TBD |

## Support

For migration issues, contact the database owner.
