"""FastAPI application entrypoint for PharmaBrain."""

from contextlib import asynccontextmanager

from fastapi import FastAPI

from app.db import init_db
from app.routers.health import router as health_router


@asynccontextmanager
async def lifespan(_: FastAPI):
    """Run startup and shutdown application hooks."""
    await init_db()
    yield


def create_app() -> FastAPI:
    """Build and configure the FastAPI application instance."""
    app = FastAPI(title="PharmaBrain", lifespan=lifespan)
    app.include_router(health_router)
    return app


app = create_app()
