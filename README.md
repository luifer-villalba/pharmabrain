# PharmaBrain

Pharmacy inventory replenishment decision engine. Analyzes stock and sales to generate reorder decisions.

## How It Works

Users upload a Farmagic POS export (XLS) via the web interface. The decision engine classifies each product into an actionable status (critical, reorder, buffer, or OK) and suggests an order quantity based on current stock and 2-day sales window. Results are displayed in the browser and persisted for history and audit.

## Stack

- **Backend:** FastAPI, SQLAlchemy (async), PostgreSQL, Alembic
- **Frontend:** Jinja2, HTMX, DaisyUI/Tailwind CSS
- **Testing:** pytest (async), httpx
- **Tools:** ruff, black, isort, pre-commit
- **Deploy:** Railway

## Decision Rules

| Status         | Meaning                             | Action                |
|----------------|-------------------------------------|-----------------------|
| REVISAR_STOCK  | Negative stock — data inconsistency | Audit POS system      |
| CRITICO        | Zero stock, product was selling     | Order immediately     |
| REPOSICION     | Stock below recent demand           | Order to cover gap    |
| BUFFER_MINIMO  | One unit left, risk of stockout     | Order one unit buffer |
| OK             | Stock covers recent demand          | No action             |

## Project Structure

```
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
├── data/raw/                # POS export files
├── data/processed/          # Processed CSVs
├── outputs/                 # Analysis reports
└── notes/                   # Decision log and findings
```

## Running Locally

### Install dependencies
```bash
make install
```

### Start PostgreSQL + app with Docker
```bash
make docker-up
```

### Run migrations
```bash
make migrate
```

### Start development server
```bash
make run
```

The app will be available at `http://localhost:8000`.

### Other commands
```bash
make test       # Run test suite
make lint       # Check code quality
make format     # Auto-format code
make docker-down  # Stop containers
```

## Environment Variables

| Variable      | Required | Description                     | Example                   |
|---------------|----------|---------------------------------|---------------------------|
| DATABASE_URL  | Yes      | PostgreSQL connection string    | `postgresql+asyncpg://...` |
| DEBUG         | No       | Enable debug mode (bool)        | `True` or `False`         |

## Development

- All DB calls and route handlers must be async/await
- Business logic lives in `app/services/`; routers handle HTTP only
- `core/` is pure Python with zero framework dependencies
- Pydantic models for every request body and response
- Type hints on all function signatures
- Tests mirror source structure (`tests/test_services_*.py` → `app/services/*.py`)

For architecture details, see [docs/architecture.md](docs/architecture.md).