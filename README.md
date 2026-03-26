# PharmaBrain

PharmaBrain is a decision-support engine for pharmacy inventory replenishment.

It models how real-world pharmacy operators make daily purchasing decisions using simple, reliable inputs:
- current stock
- recent sales (2-day window)

The goal is not theoretical optimization, but practical, defensible decisions under uncertainty.

---

## What this actually does

PharmaBrain is not a dashboard.

It is a decision engine that:

- suggests how much to reorder per product
- classifies each product into actionable states
- detects operational issues in the data

---

## Core idea

Pharmacy operations in this context are:

- reactive (short time window)
- cash-sensitive (avoid overstock)
- uncertain (supplier variability)
- data-limited (no historical persistence)

Instead of complex forecasting, PharmaBrain focuses on:

simple rules + real constraints + explainability

---

## Decision Rules (v4)

    if stock < 0:
        order = 0
        status = "REVISAR_STOCK"

    elif stock == 0:
        order = sales
        status = "CRITICO"

    elif stock >= sales:
        if stock == 1 and sales >= 1:
            order = 1
            status = "BUFFER_MINIMO"
        else:
            order = 0
            status = "OK"

    else:
        order = sales - stock
        status = "REPOSICION"

---

## Status Meaning

| Status         | Meaning |
|----------------|--------|
| REVISAR_STOCK  | Data inconsistency (negative stock) |
| CRITICO        | Out of stock |
| REPOSICION     | Need to cover missing demand |
| BUFFER_MINIMO  | Prevent stockout |
| OK             | No action required |

---

## Example Output

    SUMMARY

    CRITICO: 3
    REPOSICION: 8
    BUFFER_MINIMO: 5
    OK: 22
    REVISAR_STOCK: 1

    ---

    KEY FINDINGS

    - Negative stock detected → requires audit
    - Low-stock products stabilized with buffer rule
    - POS system recommendations are not aligned with real decisions

---

## Project Structure

    pharma-brain/
    │
    ├── data/
    │   ├── raw/
    │   ├── processed/
    │
    ├── core/
    │   ├── rules.py
    │   ├── status.py
    │
    ├── scripts/
    │   ├── run_analysis.py
    │
    ├── outputs/
    │   ├── analysis_*.txt
    │
    ├── notes/
    │   ├── decisions.md
    │   ├── findings.md
    │
    └── README.md

---

## How to run

    python scripts/run_analysis.py data/raw/pedido_10727.csv

---

## Key Findings

- POS system does not store historical decision context
- Decisions are ephemeral (lost after execution)
- Default behavior is no reorder
- Over-ordering is a risk with naive rules
- Negative stock appears and requires auditing

---

## Tech

- Python
- CSV-based processing
- No heavy frameworks (by design)

---

## Philosophy

- Keep it simple
- Stay close to reality
- Avoid over-engineering
- Optimize for usability, not theory

---

## Author

Built as part of a transition back to hands-on engineering, focusing on:
- backend fundamentals
- real-world data processing
- decision systems design