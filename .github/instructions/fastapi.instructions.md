---
applyTo: "app/**/*.py"
---

# FastAPI conventions — PharmaBrain

## App Structure

- `app/main.py` — app factory, router registration, lifespan events
- `app/routers/` — one file per route group, use `APIRouter`
- `app/services/` — all business logic, no FastAPI imports
- `app/models/` — SQLAlchemy ORM models only
- `app/schemas/` — Pydantic request/response models only
- `app/db.py` — async session factory and `get_db` dependency
- `core/` — pure Python decision logic, zero framework deps

## Routers

- Always use `APIRouter`, never instantiate `FastAPI()` in routers
- Register all routers in `app/main.py`
- Use prefix and tags on every router
- Routers call services — never DB or business logic directly
```python
# Good
router = APIRouter(prefix="/analysis", tags=["analysis"])

@router.post("/", response_model=AnalysisResponse)
async def run_analysis(payload: AnalysisRequest, db: AsyncSession = Depends(get_db)):
    return await analysis_service.run(db, payload)
```

## Services

- All service functions are `async def`
- Accept `AsyncSession` as first argument after `self`
- Never import from `fastapi` inside services
- Return domain objects or Pydantic schemas, not ORM models directly
```python
# Good
async def run(db: AsyncSession, payload: AnalysisRequest) -> AnalysisResponse:
    ...

# Bad
async def run(request: Request, payload: AnalysisRequest):
    ...
```

## Database

- Use SQLAlchemy 2.0 async style exclusively
- Session via `Depends(get_db)` in routers only
- Never create sessions manually outside of `db.py`
- All queries use `await session.execute()`
- Commits in services, not routers
```python
# Good
result = await db.execute(select(Product).where(Product.id == id))
product = result.scalar_one_or_none()
```

## Schemas

- Separate request and response Pydantic models
- Never expose ORM models directly in responses
- Use `model_config = ConfigDict(from_attributes=True)` for ORM reads
- Validate inputs strictly — no `Any` types
```python
class AnalysisRequest(BaseModel):
    stock: int
    sales: int

class AnalysisResponse(BaseModel):
    status: str
    order: int
    model_config = ConfigDict(from_attributes=True)
```

## Lifespan & Startup

- Use `lifespan` context manager, not deprecated `@app.on_event`
- Initialize DB connection pool in lifespan
```python
@asynccontextmanager
async def lifespan(app: FastAPI):
    # startup
    yield
    # shutdown
```

## Error Handling

- Use `HTTPException` for HTTP errors in routers
- Raise domain exceptions in services, catch in routers
- Add global exception handlers in `main.py` for unhandled errors
- Always return consistent error response shape

## Templates (Jinja2 + HTMX)

- Templates in `app/templates/`
- Use `TemplateResponse` for full-page renders
- Use HTMX partial responses for dynamic updates
- Keep template logic minimal — compute in services

## Migrations

- Alembic for all schema changes
- Never use `Base.metadata.create_all()` in production
- Migration naming: `alembic revision --autogenerate -m "MIZ-XXX: description"`

## Testing

- Use `httpx.AsyncClient` with `ASGITransport`
- Override `get_db` dependency in conftest.py
- Use a separate test database
- Never hit production DB in tests
```python
@pytest.fixture
async def client(db_session):
    app.dependency_overrides[get_db] = lambda: db_session
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as c:
        yield c
    app.dependency_overrides.clear()
```

## What Not To Do

- No sync route handlers or DB calls
- No business logic in routers
- No ORM models in response schemas
- No `Base.metadata.create_all()` outside tests
- No direct SQLAlchemy imports in `core/`
- Do not use `@app.on_event` — deprecated