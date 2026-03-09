# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.2.0] - 2026-03-08

### Added

- **Internationalization (i18n)**
  - Support for 6 languages (EN, DE, FR, ES, IT, UK)
  - Accept-Language header in REST API
  - Frontend language switcher with localStorage persistence
  - 600k i18n records (100k parts × 6 languages)
  
- **Database Migrations**
  - Oracle OFS style versioned delta scripts
  - `migrate.sh` controller for manual upgrades
  - `docker-entrypoint-migrate.sh` for auto-migration
  - Rollback support (*-down.sql scripts)
  - Schema/data validators
  
- **Documentation**
  - RELEASE_NOTES_v1.2.0.md
  - GIT_RELEASE_COMMANDS.md
  - Updated database/README.md

### Changed

- Updated `handle_request()` function signature (3 → 4 parameters)
- Extended healthcheck start_period to 120s
- Improved search-ui.html with language selector

### Fixed

- Healthcheck timeout for large data seeding
- Language fallback when translation not found

### Security

- No security changes in this release

### Deprecated

- Nothing deprecated

### Removed

- Nothing removed

---

## [1.1.0] - 2026-01-25

### Added

- Swagger UI documentation (/swagger-ui)
- OpenAPI 3.0 specification (/openapi)
- Unit tests (JUnit 5)
- Landing page at root (/)
- Search UI at /search/ui
- Docker Compose with healthcheck
- CI/CD pipeline (GitHub Actions)

### Changed

- Updated pom.xml for Helidon 4.3.3
- Improved Docker build with multi-stage

### Fixed

- Healthcheck for database seeding
- Maven test execution in Docker build

---

## [1.0.0] - 2026-01-25

### Added

- Initial release
- Triad Search Engine (core)
- PostgreSQL PL/pgSQL business logic
- Helidon 4 REST API
- 100k seed records
- Docker Compose configuration

---

## [Unreleased]

### Planned for v1.3.0

- OpenID Connect (Google OAuth2)
- User authentication
- Personalized collections

### Planned for v1.4.0

- Node.js implementation

### Planned for v1.5.0

- Python implementation

---

## Version History Summary

| Version | Date | Feature | Owner |
|---------|------|---------|-------|
| v1.0.0 | 2026-01-25 | Triad Search Engine (core) | G. Konev |
| v1.1.0 | 2026-01-25 | Swagger UI + Unit Tests | G. Konev |
| v1.2.0 | 2026-03-08 | i18n + Enterprise Migrations | G. Konev |
| v1.3.0 | TBD | OpenID Connect | Planned |
| v1.4.0 | TBD | Node.js | Planned |
| v1.5.0 | TBD | Python | Planned |
