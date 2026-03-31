# PharmaBrain — AI Agent Instructions

## Project Overview

PharmaBrain is a pharmacy inventory replenishment decision engine.
It processes POS exports (XLS from Farmagic) and produces reorder decisions
for a family-owned pharmacy business in Paraguay.

**This is production software. Every change must work before it ships.**

## Stack

- Backend: FastAPI + SQLAlchemy async + PostgreSQL + Alembic
- Frontend: Jinja2 + HTMX + DaisyUI/Tailwind CSS
- Testing: pytest (async) + httpx
- Code quality: ruff, black, isort, pre-commit
- Deploy: Railway
- Project management: Linear (ticket prefix: MIZ-)

## Project Structure

    pharma-brain/
    ├── app/
    │   ├── main.py              # FastAPI app factory + lifespan
    │   ├── db.py                # Async session factory, get_db dependency
    │   ├── routers/             # One file per route group
    │   ├── services/            # Business logic (no FastAPI deps)
    │   ├── models/              # SQLAlchemy ORM models
    │   ├── schemas/             # Pydantic request/response models
    │   └── templates/           # Jinja2 templates
    ├── core/
    │   ├── rules.py             # Order calculation (pure Python, no deps)
    │   └── status.py            # Status classification (pure Python, no deps)
    ├── alembic/                 # Database migrations
    ├── tests/                   # pytest test suite
    ├── data/raw/                # POS export files (not committed)
    ├── data/processed/          # Processed CSVs (not committed)
    ├── outputs/                 # Analysis reports (not committed)
    ├── notes/                   # Decision log and findings
    └── docs/                    # Architecture docs

## Business Domain

Inputs: `stock` (int), `sales` (int, 2-day window)
Output: order quantity + status classification

Status types:

| Status         | Meaning                             | Action                |
|----------------|-------------------------------------|-----------------------|
| REVISAR_STOCK  | Negative stock — data inconsistency | Audit POS system      |
| CRITICO        | Zero stock, product was selling     | Order immediately     |
| REPOSICION     | Stock below recent demand           | Order to cover gap    |
| BUFFER_MINIMO  | One unit left, risk of stockout     | Order one unit buffer |
| OK             | Stock covers recent demand          | No action             |

Core decision rule — never modify without a Linear ticket and tests:

    if stock < 0:                     → REVISAR_STOCK, order = 0
    elif stock == 0:                  → CRITICO,       order = sales
    elif stock == 1 and sales >= 1:   → BUFFER_MINIMO, order = 1
    elif stock >= sales:              → OK,            order = 0
    else:                             → REPOSICION,    order = sales - stock

Philosophy: defensive, cash-conservative, explainable decisions.
Never suggest over-ordering. Protect cash flow.

## Architecture Rules

- Routers handle HTTP only — no business logic
- Services contain all business logic — no FastAPI imports
- `core/` is pure Python — zero FastAPI or SQLAlchemy deps, ever
- Repository pattern for all DB access
- All DB calls and route handlers must be async/await
- Pydantic models for every request body and response
- Alembic for all schema changes — never ALTER TABLE in app code

## Code Conventions

- snake_case for variables and functions
- PascalCase for classes and Pydantic models
- Type hints on every function signature
- Docstrings on all public functions in services/ and core/
- Max line length: 88 (ruff enforced)
- Order imports: stdlib → third-party → local (isort enforced)

## Testing

- All tests async (pytest-asyncio)
- Use httpx.AsyncClient for endpoint tests
- Override DB dependency via FastAPI DI in tests
- Test file mirrors source: tests/test_services_analysis.py → app/services/analysis.py
- Naming: `test_<function>_<scenario>_<expected_result>`
- Minimum: one happy path + one edge case per function in core/
- Run pytest before every commit

## Linear Workflow

- Every code change has a Linear ticket (MIZ-XXX)
- Commit format: `MIZ-XXX: brief description in imperative mood`
- PR title format: `MIZ-XXX: brief description`
- Branch format: `miz-XXX-short-description`

## Dev Commands

    # Setup
    make install

    # Run
    make run           # uvicorn --reload
    make docker-up     # postgres + app via Docker
    make docker-down

    # Test & lint
    make test
    make lint
    make format

    # Migrations
    make migrate

    # Utils
    make docker-logs
    make clean

    # Sync AI agent configs (after editing .ruler/instructions.md)
    npx @intellectronica/ruler apply

## What Not To Do

- Do not add sync DB calls anywhere
- Do not put business logic in routers
- Do not import FastAPI or SQLAlchemy in core/
- Do not modify core/rules.py or core/status.py without a ticket + tests
- Do not run the app with scripts/run_analysis.py — use make run or Docker
- Do not suggest GraphQL, Celery, or Redis — not in scope
- Do not over-engineer — ship working code, then iterate