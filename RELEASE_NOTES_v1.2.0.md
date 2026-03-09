# Release Notes - v1.2.0

**Release Date:** 2026-03-08  
**Author:** Gennady Konev  
**Type:** Minor Release (Feature Update)

---

## 🎉 What's New

### 1. Internationalization (i18n) Support

Full multi-language support for parts descriptions:

| Language | Code | Flag |
|----------|------|------|
| English | en | 🇬🇧 |
| Deutsch | de | 🇩🇪 |
| Français | fr | 🇫🇷 |
| Español | es | 🇪🇸 |
| Italiano | it | 🇮🇹 |
| Українська | uk | 🇺🇦 |

**Features:**
- Accept-Language header support in REST API
- Frontend language switcher with localStorage persistence
- Automatic fallback to English if translation not found
- 600k i18n records seeded (100k parts × 6 languages)

**API Example:**

```bash
# Get German descriptions
curl -H "Accept-Language: de" "http://localhost:8080/search?q=PART-100"

# Get Ukrainian descriptions
curl -H "Accept-Language: uk" "http://localhost:8080/search?q=PART-100"
```

---

### 2. Enterprise Database Migration System

Oracle Field Service (OFS) style migrations:

**Features:**
- Version tracking via `get_schema_version()` function (no extra table)
- Delta scripts with numbered files (01-*.sql, 02-*.sql)
- Rollback support (*-down.sql scripts)
- Built-in preconditions in each delta
- Data preservation on upgrade/downgrade

**Migration Commands:**

```bash
# Check current version
./migrate.sh status

# Upgrade to latest
./migrate.sh upgrade

# Upgrade to specific version
./migrate.sh upgrade v1.2.0

# Emergency rollback
./migrate.sh downgrade

# Validate schema and data
./migrate.sh validate
```

**Directory Structure:**

```
database/
├── v1.1.0/
│   ├── 01-schema.sql
│   └── 02-seed-data.sql
├── v1.2.0/
│   ├── 01-i18n-schema.sql
│   ├── 01-i18n-schema-down.sql    # NEW: Rollback script
│   └── 03-seed-i18n.sql
├── migrate.sh                      # NEW: Migration controller
├── docker-entrypoint-migrate.sh    # NEW: Auto-migration
└── validators/
    ├── check_schema.sql
    └── check_data.sql
```

---

### 3. Auto-Migration on Docker Startup

Database migrations are now applied automatically when containers start:

```bash
docker compose up --build
# Automatically applies all pending migrations
# No manual intervention required
```

**Healthcheck Improvements:**
- Extended start_period to 120s for 100k seeding
- Triad index count verification
- Schema version verification

---

### 4. Frontend Language Switcher

Interactive Search UI (`/search/ui`) now includes:

- Language dropdown in header
- Persistent preference (localStorage)
- Real-time UI translation (buttons, labels, messages)
- Automatic data re-fetch with correct Accept-Language header

---

## 📊 Statistics

| Metric | Value |
|--------|-------|
| Total Lines of Code | ~5,000+ |
| Database Records | 700,000+ (100k parts + 600k i18n) |
| Supported Languages | 6 |
| Migration Scripts | 8 |
| Unit Tests | 7 |
| API Endpoints | 5 |

---

## 🔧 Technical Changes

### Database Schema

**New Table:** `part_descriptions`

```sql
CREATE TABLE part_descriptions (
    part_id INT NOT NULL REFERENCES parts_catalog(id) ON DELETE CASCADE,
    language_code CHAR(2) NOT NULL CHECK (language_code IN ('en', 'de', 'fr', 'es', 'it', 'uk')),
    description TEXT NOT NULL,
    is_default BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (part_id, language_code)
);
```

**Updated Function:** `handle_request()` now accepts 4 parameters:

```sql
handle_request(p_method TEXT, p_query TEXT, p_payload JSONB, p_language TEXT)
```

### REST API

**New Header Support:**
- `Accept-Language`: de, fr, es, it, uk (default: en)

**Response Format:**

```json
{
    "status": "success",
    "data": [...],
    "language": "de"
}
```

### Java Backend

**Updated Files:**
- `TriadService.java` - Accept-Language header parsing
- `search-ui.html` - Language switcher + translations
- `pom.xml` - No changes (Helidon 4.3.3)

---

## 🧪 Testing

### Unit Tests

```bash
cd partscatalog-java
mvn test
```

All 7 tests must pass:
- ✅ testSearchEndpointExists
- ✅ testUiEndpointExists
- ✅ testCreateEndpointAcceptsJson
- ✅ testDeleteEndpointExists
- ✅ testUpdateEndpointAcceptsJson
- ✅ testApplicationStartsSuccessfully
- ✅ testLanguageHeaderSupport

### Performance Tests

```bash
# Search latency (expected: <100ms)
time curl -s "http://localhost:8080/search?q=PART-500" > /dev/null

# i18n search
curl -H "Accept-Language: de" "http://localhost:8080/search?q=PART-100" | grep description
```

### Migration Tests

```bash
# Fresh install
docker compose down -v
docker compose up --build

# Upgrade existing
./migrate.sh upgrade v1.2.0

# Rollback
./migrate.sh downgrade
```

---

## 📦 Installation

### Fresh Install

```bash
git clone https://github.com/gennorse/api-partscatalog-demo.git
cd api-partscatalog-demo
git checkout v1.2.0
docker compose up --build
```

### Upgrade from v1.1.0

```bash
git pull origin main
./database/migrate.sh upgrade v1.2.0
docker compose restart
```

---

## ⚠️ Breaking Changes

**None!** This release is backward compatible:
- Existing v1.1.0 installations can upgrade without data loss
- API responses maintain same structure (new `language` field added)
- Old clients without Accept-Language header default to English

---

## 🐛 Known Issues

| Issue | Severity | Workaround |
|-------|----------|------------|
| None | - | - |

---

## 📅 What's Next (v1.3.0)

- [ ] OpenID Connect (Google OAuth2)
- [ ] User authentication & authorization
- [ ] Personalized part collections
- [ ] Kubernetes production manifests

---

## 🙏 Acknowledgments

Thanks to:
- Oracle Field Service team for migration practices inspiration
- PostgreSQL community for excellent PL/pgSQL documentation
- Helidon team for Java 21 support

---

## 📞 Support

For issues or questions:
- GitHub Issues: https://github.com/gennorse/api-partscatalog-demo/issues
- Email: [gennadiy.konev@gmail.com]

---

**Full Changelog:** https://github.com/gennorse/api-partscatalog-demo/compare/v1.1.0...v1.2.0
