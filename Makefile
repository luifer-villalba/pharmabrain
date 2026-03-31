# Makefile

PYTHON := python3
VENV := .venv
BIN := $(VENV)/bin

.PHONY: install run test lint format migrate \
        docker-build docker-up docker-down docker-logs \
        clean help

# ── Local ────────────────────────────────────────────────────────────────────

$(VENV):
	$(PYTHON) -m venv $(VENV)
	$(BIN)/pip install --upgrade pip
	$(BIN)/pip install -r requirements-dev.txt

install: $(VENV)

run: $(VENV)
	$(BIN)/uvicorn app.main:app --reload

test: $(VENV)
	$(BIN)/pytest

lint: $(VENV)
	$(BIN)/ruff check .

format: $(VENV)
	$(BIN)/ruff format .

migrate: $(VENV)
	$(BIN)/alembic upgrade head

# ── Docker ───────────────────────────────────────────────────────────────────

docker-build:
	docker compose build

docker-up:
	docker compose up -d

docker-down:
	docker compose down

docker-logs:
	docker compose logs -f app

# ── Utils ────────────────────────────────────────────────────────────────────

clean:
	find . -type d -name __pycache__ -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete
	rm -rf .venv dist build *.egg-info

help:
	@echo ""
	@echo "  install       set up venv and install deps"
	@echo "  run           start uvicorn with --reload"
	@echo "  test          run pytest"
	@echo "  lint          ruff check"
	@echo "  format        ruff format"
	@echo "  migrate       alembic upgrade head"
	@echo "  docker-build  build docker image"
	@echo "  docker-up     start containers (detached)"
	@echo "  docker-down   stop containers"
	@echo "  docker-logs   tail app logs"
	@echo "  clean         remove caches and venv"
	@echo ""