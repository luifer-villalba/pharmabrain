# Makefile

PYTHON := python3
VENV := .venv
BIN := $(VENV)/bin

.PHONY: install lint format run

$(VENV):
	$(PYTHON) -m venv $(VENV)
	$(BIN)/pip install -r requirements-dev.txt

install: $(VENV)

lint: $(VENV)
	$(BIN)/python -m ruff check .

format: $(VENV)
	$(BIN)/python -m ruff format .

run: $(VENV)
	$(BIN)/python scripts/run_analysis.py $(FILE)
