# Pharmabrain

Pharmabrain is a decision-support engine for pharmacy sales and inventory.

The goal is to transform raw transactional data into actionable insights:
- What products are selling?
- What is underperforming?
- What should be reordered?

This project focuses on building strong backend and data-processing fundamentals, before layering AI capabilities on top.

## Features (current)

- CSV-based sales ingestion
- Aggregation by product
- Revenue calculation

## Planned

- Stock recommendations
- Low-rotation detection
- Weekly summaries
- AI-generated explanations (RAG)

## Tech

- Python (core focus)
- No heavy frameworks (yet)
- Designed for incremental complexity

## How to run

```bash
python scripts/run_analysis.py
