# PharmaBrain — Architecture

## Status

Active development. Migrating from pure Python CLI to FastAPI web application.
Core decision logic (`core/`) is stable and will be reused directly.

## Goal

A web-based pharmacy inventory decision engine that:
- Accepts POS exports (XLS) via file upload
- Runs the reorder decision engine
- Displays results in a UI (Jinja2 + HTMX)
- Persists analysis history in PostgreSQL
- Is deployable on Railway

## Current State
```
pharma-brain/
├── core/
│   ├── rules.py        ✅ stable, pure Python
│   └── status.py       ✅ stable, pure Python
├── scripts/
│   └── run_analysis.py ⚠️  CLI only, will be superseded by FastAPI
├── data/
│   ├── raw/            XLS exports from Farmagic POS
│   └── processed/      CSV outputs from CLI analysis
└── outputs/            TXT reports from CLI analysis
```

## Target State
```
pharma-brain/
├── app/
│   ├── main.py              FastAPI app factory + lifespan
│   ├── db.py                Async session factory, get_db dependency
│   ├── routers/
│   │   ├── analysis.py      Upload XLS, trigger analysis, return results
│   │   └── history.py       List and retrieve past analyses
│   ├── services/
│   │   ├── analysis.py      Orchestrates XLS parsing + decision engine
│   │   └── history.py       Persist and query analysis results
│   ├── models/
│   │   ├── analysis.py      Analysis run (ORM)
│   │   └── product.py       Product result row (ORM)
│   ├── schemas/
│   │   ├── analysis.py      Request/response Pydantic models
│   │   └── product.py       Product result schema
│   └── templates/
│       ├── base.html        DaisyUI layout
│       ├── index.html       Upload form
│       └── results.html     Analysis results (HTMX-driven)
├── core/
│   ├── rules.py             ✅ unchanged — called by services/analysis.py
│   └── status.py            ✅ unchanged — called by services/analysis.py
├── alembic/                 Migrations
├── tests/
│   ├── conftest.py          Async DB fixture, test client
│   ├── test_core/
│   │   ├── test_rules.py
│   │   └── test_status.py
│   └── test_app/
│       ├── test_routers_analysis.py
│       └── test_services_analysis.py
├── Dockerfile
├── docker-compose.yml
├── Makefile
└── AGENTS.md
```

## Layer Responsibilities

| Layer        | Location            | Rule                                      |
|--------------|---------------------|-------------------------------------------|
| HTTP         | `app/routers/`      | Handle request/response only, no logic    |
| Business     | `app/services/`     | Orchestrate, validate, persist            |
| Decision     | `core/`             | Pure Python, zero framework deps, stable  |
| Data         | `app/models/`       | ORM models, no business logic             |
| Contracts    | `app/schemas/`      | Pydantic only, no ORM imports             |
| Persistence  | `app/db.py`         | Session factory, single source of truth   |

## Data Flow
```
User uploads XLS
    → router receives file
    → service parses XLS (pandas + xlrd)
    → service calls core/rules.py + core/status.py per row
    → service persists Analysis + ProductResult rows to PostgreSQL
    → router returns TemplateResponse with results
    → HTMX updates results table without full page reload
```

## Database (planned)

Two tables:

**analysis_runs**
- id, created_at, filename, total_products, critico_count,
  reposicion_count, buffer_minimo_count, ok_count, revisar_stock_count

**product_results**
- id, analysis_run_id (FK), codigo, producto, cant, costo,
  stock, ventas, envios, status, pedido

## Stack Decisions

| Decision | Choice | Reason |
|----------|--------|--------|
| Framework | FastAPI | Async, Pydantic native, portfolio value |
| ORM | SQLAlchemy 2.0 async | Consistent with CashPilot |
| DB | PostgreSQL | Railway native, relational fits domain |
| Migrations | Alembic | Industry standard, pairs with SQLAlchemy |
| Frontend | Jinja2 + HTMX + DaisyUI | No JS build step, interactive enough |
| Deploy | Railway | Already used for CashPilot |
| Sync tool | Ruler | Single source for all AI agent configs |

## Guardrails

- `core/` is immutable from a deps perspective — never add framework imports
- All DB interactions are async — no exceptions
- Alembic for all schema changes — never ALTER TABLE in app code
- Services orchestrate, routers delegate — business logic never leaks up

## Migration Path from CLI

The CLI script (`scripts/run_analysis.py`) is not the target architecture.
The analysis pipeline it contains will be reimplemented in `app/services/analysis.py`.
`core/rules.py` and `core/status.py` are reused as-is — no changes needed.