# API Parts Catalog Demo

## High-Performance Search Service (Java 21 + Helidon 4 + PostgreSQL 17)

**License:** MIT  
**Java:** 21  
**Helidon:** 4.3.3  
**PostgreSQL:** 17  

---

## Overview

This project demonstrates a High-Load Parts Search Architecture based on the "Data Triad" principle. Unlike standard ORM-based applications, this system delegates search logic to the database layer (PostgreSQL PL/pgSQL) to maximize performance and data integrity.

### Key Features

- **Triad-Based Search:** Optimized for partial matching on 1M+ records with sub-second response
- **Database-Centric Logic:** Complex business logic implemented in PL/pgSQL (handle_request function)
- **Zero-Defect Design:** Automated indexing via triggers ensures data consistency
- **Cloud-Ready:** Docker Compose and Kubernetes manifests included
- **OpenAPI/Swagger:** Interactive API documentation available at runtime
- **Internationalization (i18n):** 6 languages supported (EN/DE/FR/ES/IT/UK)
- **Enterprise Migrations:** Oracle OFS style versioned delta scripts with auto-migration

---

## Architecture

Client (Browser/cURL) → Helidon 4 (Java Thin Proxy) → PostgreSQL 17 (Triad Engine)

### Database Components

- `parts_catalog` (Table) - Main parts data
- `triad_index` (Search Index) - Sub-string hashing for fast lookup
- `part_descriptions` (i18n Table) - Multi-language descriptions
- `handle_request()` (PL/pgSQL Function) - Universal API router

---

## Quick Start

### Prerequisites

- Docker and Docker Compose
- Git

### 1. Clone and Run

```bash
git clone https://github.com/gennorse/api-partscatalog-demo.git
cd api-partscatalog-demo
docker compose up --build
```

### 2. Verify Health

The service is ready when you see:

    Container triad-db        Healthy
    Container triad-helidon   Healthy

Wait for the database seed (100k records) to complete (about 30-60 seconds).

### 3. Access the Application

| Endpoint | Description |
|----------|-------------|
| http://localhost:8080/ | Landing page with navigation |
| http://localhost:8080/search/ui | Interactive parts search UI |
| http://localhost:8080/swagger-ui | Swagger API documentation |
| http://localhost:8080/openapi | OpenAPI 3.0 YAML specification |

---

## API Usage (CRUD Examples)

Base URL: `http://localhost:8080/search`

### 1. SEARCH (GET)

Search by part number (supports partial match via Triad index).

```bash
# Default language (English)
curl -X GET "http://localhost:8080/search?q=PART-100" -H "Accept: application/json"

# German
curl -X GET "http://localhost:8080/search?q=PART-100" -H "Accept-Language: de"

# Ukrainian
curl -X GET "http://localhost:8080/search?q=PART-100" -H "Accept-Language: uk"
```

Response Example:

```json
{
    "status": "success",
    "data": [
        {
            "id": 1234,
            "part_number": "PART-100500-X",
            "description": "Spare part #1234 High-Load Test Seed",
            "last_update": "2026-01-25 10:00:00"
        }
    ],
    "language": "en"
}
```

### 2. CREATE (POST)

Create a single part or bulk insert.

```bash
# Single Insert
curl -X POST "http://localhost:8080/search" \
    -H "Content-Type: application/json" \
    -d '{"part_number": "TEST-001-A", "description": "Manual test part"}'

# Bulk Insert (Array)
curl -X POST "http://localhost:8080/search" \
    -H "Content-Type: application/json" \
    -d '[{"part_number": "BULK-001", "description": "Bulk item 1"}, {"part_number": "BULK-002", "description": "Bulk item 2"}]'
```

Response Example:

```json
{
    "status": "created",
    "id": 100001
}
```

### 3. UPDATE (PUT)

Update description by ID.

```bash
curl -X PUT "http://localhost:8080/search" \
    -H "Content-Type: application/json" \
    -d '{"id": 1234, "description": "Updated description for part #1234"}'
```

Response Example:

```json
{
    "status": "updated",
    "id": 1234
}
```

### 4. DELETE (DELETE)

Remove a part by ID.

```bash
curl -X DELETE "http://localhost:8080/search?q=1234" -H "Accept: application/json"
```

Response Example:

```json
{
    "status": "deleted",
    "id": "1234"
}
```

---

## Internationalization (i18n)

### Supported Languages

| Code | Language | Flag |
|------|----------|------|
| en | English | 🇬🇧 |
| de | Deutsch | 🇩🇪 |
| fr | Français | 🇫🇷 |
| es | Español | 🇪🇸 |
| it | Italiano | 🇮🇹 |
| uk | Українська | 🇺🇦 |

### How It Works

1. Client sends `Accept-Language` header (e.g., `de`, `fr`, `uk`)
2. Backend passes language to `handle_request()` function
3. Database returns description in requested language
4. Falls back to English if translation not found

### Frontend Language Switcher

The Search UI (`/search/ui`) includes a language selector that:
- Persists preference in localStorage
- Re-fetches data with correct `Accept-Language` header
- Translates all UI elements (buttons, labels, messages)

---

## Database Migration System

### Oracle OFS Style Architecture

This project uses enterprise-grade migration practices from Oracle Field Service:

| Principle | Implementation |
|-----------|----------------|
| Version tracking | `get_schema_version()` function (no extra table) |
| Delta scripts | Numbered files per feature (01-*.sql, 02-*.sql) |
| Rollback | Single-step only (*-down.sql) |
| Validation | Built-in preconditions in each delta |
| Data preservation | Customer data never lost on upgrade/downgrade |

### Directory Structure

```bash
database/
├── v1.1.0/                    # Base version
│   ├── 01-schema.sql          # Tables, functions, triggers
│   └── 02-seed-data.sql       # 100k test records
├── v1.2.0/                    # i18n version
│   ├── 01-i18n-schema.sql     # part_descriptions table
│   ├── 01-i18n-schema-down.sql # Rollback script
│   └── 03-seed-i18n.sql       # 600k i18n records
├── migrate.sh                 # Migration controller
├── docker-entrypoint-migrate.sh # Auto-migration for Docker
├── validators/
│   ├── check_schema.sql       # Structure validation
│   └── check_data.sql         # Data integrity validation
└── README.md                  # Migration documentation
```

### Auto-Migration (Docker)

On container startup, migrations are applied automatically:

```bash
docker compose up --build
# Automatically applies all pending migrations
```

### Manual Migration (Production)

For existing installations with custom data:

```bash
# Check current version
./migrate.sh status

# Upgrade to latest
./migrate.sh upgrade

# Upgrade to specific version
./migrate.sh upgrade v1.2.0

# Downgrade one version (emergency rollback)
./migrate.sh downgrade

# Validate schema and data
./migrate.sh validate
```

### For Integrators

**Fresh Install (New Customer):**

```bash
docker compose up --build
# Applies v1.1.0 schema + seed data automatically
```

**Upgrade Existing Installation:**

```bash
# Customer has v1.1.0 with custom data
./migrate.sh upgrade v1.2.0
# No data loss - existing descriptions migrated to English
```

**Rollback (Emergency):**

```bash
# Something went wrong with v1.2.0
./migrate.sh downgrade
# Returns to v1.1.0, preserves customer data
```

---

## Testing

### Unit Tests

Tests run automatically during Docker build. If tests fail, the image will not be built.

Run tests locally:

```bash
cd partscatalog-java
mvn test
```

Build with tests (Docker):

```bash
docker compose build
```

### Performance Testing

The database is pre-seeded with 100,000 records on startup.

Test search latency:

```bash
time curl -s "http://localhost:8080/search?q=PART-500" > /dev/null
```

Expected: less than 100ms for indexed queries.

### i18n Testing

```bash
# English
curl -H "Accept-Language: en" "http://localhost:8080/search?q=PART-100" | grep description

# German
curl -H "Accept-Language: de" "http://localhost:8080/search?q=PART-100" | grep description

# Ukrainian
curl -H "Accept-Language: uk" "http://localhost:8080/search?q=PART-100" | grep description
```

---

## Project Structure

```
api-partscatalog-demo/
├── database/                      # SQL migrations (PostgreSQL)
│   ├── v1.1.0/                   # Base version
│   ├── v1.2.0/                   # i18n version
│   ├── migrate.sh                # Migration controller
│   └── validators/               # Schema & data validation
├── k8s/                          # Kubernetes manifests
│   ├── java-service.yaml         # K8s Deployment
│   └── ingress.yaml              # K8s Ingress
├── partscatalog-java/            # Helidon 4 implementation (v1.2.0)
│   ├── src/main/java/...         # REST controllers
│   ├── src/main/resources/web/   # Static HTML files
│   ├── src/test/java/...         # Unit tests (JUnit 5)
│   ├── pom.xml                   # Maven (Java 21, Helidon 4)
│   └── dockerfile                # Multi-stage build
├── partscatalog-nodejs/          # Future implementation
├── partscatalog-python/          # Future implementation
├── partscatalog-php/             # Future implementation
├── partscatalog-c++/             # Future implementation
├── .github/workflows/            # CI/CD pipeline
├── .gitignore                    # Standard exclusions
├── docker-compose.yml            # Local development environment
├── LICENSE                       # MIT License
└── README.md                     # This file
```

---

## Why This Architecture

Traditional ORM Approach vs This Project (DB-Centric):

| Aspect | Traditional ORM | This Project |
|--------|-----------------|--------------|
| Filtering | Data fetched to Java | Done in PostgreSQL |
| Round-trips | Multiple calls | Single function call |
| Index management | In code | Automated via Triggers |
| Data consistency | Risk of errors | ACID guaranteed at DB level |

**Best For:** High-load search systems, catalog services, inventory management.

---

## CI/CD (GitHub Actions)

Tests run on every push:

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [main]
    tags: ['v*']
  pull_request:
    branches: [main]

jobs:
  build-and-test:
    runs-on: ubuntu-latest
    steps:
      - Checkout code
      - Set up JDK 21
      - Run Maven tests
      - Build Docker image
```

---

## Version History

| Version | Date | Feature | Owner |
|---------|------|---------|-------|
| v1.0.0 | 2026-01-25 | Triad Search Engine (core) | G. Konev |
| v1.1.0 | 2026-01-25 | Swagger UI + Unit Tests | G. Konev |
| v1.2.0 | 2026-03-08 | i18n (6 languages) + Auto-Migration | G. Konev |
| v1.3.0 | TBD | OpenID Connect (Google OAuth) | Planned |
| v1.4.0 | TBD | Node.js implementation | Planned |
| v1.5.0 | TBD | Python implementation | Planned |

---

## License

MIT License (c) 2026 Gennady Konev

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
