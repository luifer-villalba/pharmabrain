"""Healthcheck endpoints."""

from fastapi import APIRouter
from fastapi.responses import JSONResponse

router = APIRouter(tags=["health"])


@router.get("/health")
async def health() -> JSONResponse:
    """Return API health status."""
    return JSONResponse(content={"status": "ok"})
