# Makefile — PharmaBrain Inventory Decision Engine

PYTHON := python3
VENV := .venv
BIN := $(VENV)/bin

.PHONY: install run dev test lint format migrate migration \
        docker-build docker-up docker-down docker-logs sh \
        db-reset clean help

# ---------- Setup ----------

$(VENV):
	@echo "📦 Creating virtual environment..."
	$(PYTHON) -m venv $(VENV)
	$(BIN)/pip install --upgrade pip
	$(BIN)/pip install -r requirements-dev.txt
	@echo "✅ Virtual environment ready"

install: $(VENV)  ## Set up venv and install dependencies

# ---------- Local Development ----------

run: $(VENV)  ## Start uvicorn with auto-reload
	@echo "🚀 Starting FastAPI with auto-reload..."
	@echo "📍 Dashboard: http://127.0.0.1:8888"
	@echo "📍 Docs: http://127.0.0.1:8888/docs"
	$(BIN)/uvicorn app.main:app --reload --port 8888

dev: run  ## Alias for run

test: $(VENV)  ## Run pytest
	@echo "🧪 Running tests..."
	PYTHONPATH=. $(BIN)/pytest || test $$? -eq 5

lint: $(VENV)  ## Check code quality with ruff
	@echo "🔍 Linting with ruff..."
	$(BIN)/ruff check .
	@echo "✅ Lint passed"

format: $(VENV)  ## Format code with ruff
	@echo "🎨 Formatting code..."
	$(BIN)/ruff format .
	@echo "✅ Format complete"

# ---------- Migrations ----------

migration: $(VENV)  ## Create new migration (autogenerate)
	@read -p "Migration name: " name; \
	$(BIN)/alembic revision --autogenerate -m "$$name"

migrate: $(VENV)  ## Apply all pending migrations
	@echo "📋 Running alembic upgrade head..."
	$(BIN)/alembic upgrade head
	@echo "✅ Migrations applied"

# ---------- Docker ----------

docker-build:  ## Build Docker image
	@echo "🏗️  Building Docker image..."
	docker compose build
	@echo "✅ Build complete"

docker-up:  ## Start all services (detached)
	@echo "🚀 Starting services..."
	docker compose up -d
	@echo "✅ Services running"
	@echo "📍 App: http://127.0.0.1:8888"
	@echo "📍 Docs: http://127.0.0.1:8888/docs"

docker-down:  ## Stop all services
	@echo "⏹️  Stopping services..."
	docker compose down
	@echo "✅ Stopped"

docker-logs:  ## Tail app container logs
	docker compose logs -f app

sh:  ## Open shell in app container
	docker compose exec app bash

# ---------- Database ----------

db-reset:  ## Reset database (drops volume, recreates, applies migrations)
	@echo "🔄 Resetting database..."
	docker compose down -v
	docker compose up -d db app
	@echo "⏳ Waiting for database to be ready..."
	@sleep 5
	@$(MAKE) migrate
	@echo "✅ Database reset complete"

# ---------- Cleanup ----------

clean:  ## Remove caches and virtual environment
	@echo "🧹 Cleaning up..."
	find . -type d -name __pycache__ -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete
	rm -rf .venv dist build *.egg-info
	@echo "✅ Cleanup complete"

# ---------- Help ----------

help:  ## Show this help message
	@echo ""
	@echo "  PharmaBrain — Inventory Replenishment Engine"
	@echo ""
	@echo "  Setup:"
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | grep -E '(install|help)' | awk 'BEGIN {FS = ":.*?## "} {printf "    %-20s %s\n", $$1, $$2}'
	@echo ""
	@echo "  Development:"
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | grep -vE '(install|help|docker|db-reset|clean|dev)' | head -10 | awk 'BEGIN {FS = ":.*?## "} {printf "    %-20s %s\n", $$1, $$2}'
	@echo ""
	@echo "  Docker:"
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | grep -E '(docker|sh|db-reset)' | awk 'BEGIN {FS = ":.*?## "} {printf "    %-20s %s\n", $$1, $$2}'
	@echo ""
	@echo "  Maintenance:"
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | grep -E '(clean|help)' | awk 'BEGIN {FS = ":.*?## "} {printf "    %-20s %s\n", $$1, $$2}'
	@echo ""