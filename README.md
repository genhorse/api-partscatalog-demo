# API Parts Catalog Demo
### High-Performance Search Service (Java 21 + Helidon 4 + PostgreSQL)

License: MIT
Java: 21
Helidon: 4.x

## Overview

This project demonstrates a High-Load Parts Search Architecture based on the "Data Triad" principle. Unlike standard ORM-based applications, this system delegates search logic to the database layer (PostgreSQL PL/pgSQL) to maximize performance and data integrity.

Key Features:
- Triad-Based Search: Optimized for partial matching on 1M+ records with sub-second response.
- Database-Centric Logic: Complex business logic implemented in PL/pgSQL (handle_request).
- Zero-Defect Design: Automated indexing via triggers ensures data consistency.
- Cloud-Ready: Docker Compose and Kubernetes manifests included.

---

## Architecture

Client (Browser/cURL) -> Helidon 4 (Java Thin Proxy) -> PostgreSQL 17 (Triad Engine)

Database Components:
- parts_catalog (Table)
- triad_index (Search Index)
- handle_request() (PL/pgSQL Function)

---

## Quick Start

### Prerequisites
- Docker and Docker Compose
- Git

### 1. Clone and Run

git clone https://github.com/genhorse/api-partscatalog-demo.git
cd api-partscatalog-demo
docker-compose up --build

### 2. Verify Health

The service is ready when you see:

curl http://localhost:8080/search/ui

Wait for the database seed (100k records) to complete (about 30 seconds).

---

## API Usage (CRUD Examples)

Base URL: http://localhost:8080/search

### 1. SEARCH (GET)

Search by part number (supports partial match via Triad index).

curl -X GET "http://localhost:8080/search?q=PART-100" -H "Accept: application/json"

Response Example:

{
  "status": "success",
  "data": [
    {
      "id": 1234,
      "part_number": "PART-100500-X",
      "description": "Spare part #1234 High-Load Test Seed",
      "last_update": "2026-01-25 10:00:00"
    }
  ]
}

### 2. CREATE (POST)

Create a single part or bulk insert.

Single Insert:

curl -X POST "http://localhost:8080/search" -H "Content-Type: application/json" -d '{"part_number": "TEST-001-A", "description": "Manual test part"}'

Bulk Insert (Array):

curl -X POST "http://localhost:8080/search" -H "Content-Type: application/json" -d '[{"part_number": "BULK-001", "description": "Bulk item 1"}, {"part_number": "BULK-002", "description": "Bulk item 2"}]'

Response Example:

{
  "status": "created",
  "id": 100001
}

### 3. UPDATE (PUT)

Update description by ID.

curl -X PUT "http://localhost:8080/search" -H "Content-Type: application/json" -d '{"id": 1234, "description": "Updated description for part #1234"}'

Response Example:

{
  "status": "updated",
  "id": 1234
}

### 4. DELETE (DELETE)

Remove a part by ID.

curl -X DELETE "http://localhost:8080/search?q=1234" -H "Accept: application/json"

Response Example:

{
  "status": "deleted",
  "id": "1234"
}

---

## Performance Testing

The database is pre-seeded with 100,000 records on startup.

Test search latency:

time curl -s "http://localhost:8080/search?q=PART-500" > /dev/null

Expected: less than 100ms for indexed queries.

---

## Project Structure

api-partscatalog-demo/
├── database/
│   └── init.sql              # Schema, Triggers, PL/pgSQL Logic
├── partscatalog-java/
│   ├── src/main/java/...
│   │   └── TriadService.java # REST Controller
│   ├── pom.xml               # Maven (Java 21, Helidon 4)
│   └── dockerfile            # Multi-stage build
├── k8s/
│   ├── java-service.yaml     # Kubernetes Deployment
│   └── ingress.yaml          # K8s Ingress
├── docker-compose.yml        # Local Dev Environment
└── README.md

---

## Why This Architecture

Traditional ORM Approach vs This Project (DB-Centric):

| Aspect | Traditional ORM | This Project |
|--------|-----------------|--------------|
| Filtering | Data fetched to Java | Done in PostgreSQL |
| Round-trips | Multiple calls | Single function call |
| Index management | In code | Automated via Triggers |
| Data consistency | Risk of errors | ACID guaranteed at DB level |

Best For: High-load search systems, catalog services, inventory management.

---

## License

MIT License (c) 2026 Gennady Konev
