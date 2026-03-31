---
name: pharma-domain
description: |
  PharmaBrain business domain knowledge. Load this skill when working on
  anything related to inventory decisions, status classification, order
  calculation, CSV processing, or pharmacy business logic.
---

# PharmaBrain — Domain Knowledge

## What This System Does

Processes daily POS exports from Farmagic (XLS format) and produces
a reorder list with quantities and status classifications.

Real use: family pharmacy in Paraguay, run daily before placing supplier orders.
Decisions are cash-conservative — over-ordering is a bigger risk than under-ordering.

## Data Source

- POS system: Farmagic
- Export format: XLS (legacy .xls, not .xlsx)
- Read with: pandas + xlrd engine
- Typical export: 100–150 products per order cycle
- Key columns: `codigo`, `producto`, `cant`, `costo`, `stock`, `ventas`, `envios`

## Column Definitions

| Column    | Type | Meaning                                      |
|-----------|------|----------------------------------------------|
| codigo    | str  | Product code (unique identifier)             |
| producto  | str  | Product name                                 |
| cant      | int  | Pack quantity (units per order pack)         |
| costo     | int  | Unit cost in PYG (Paraguayan Guaraní)        |
| stock     | int  | Current stock on hand                        |
| ventas    | int  | Units sold in the last 2 days                |
| envios    | int  | Units in transit (ordered, not yet received) |

## Decision Logic (core/rules.py + core/status.py)

This logic is the heart of the system. Never change without a Linear ticket + tests.

    if stock < 0:
        status = REVISAR_STOCK
        order  = 0               # Do not order — fix data first

    elif stock == 0:
        status = CRITICO
        order  = sales           # Out of stock — order exactly what sold

    elif stock == 1 and sales >= 1:
        status = BUFFER_MINIMO
        order  = 1               # One unit left — order one to prevent stockout

    elif stock >= sales:
        status = OK
        order  = 0               # Covered — no action needed

    else:  # 0 < stock < sales
        status = REPOSICION
        order  = sales - stock   # Partial coverage — fill the gap

## Status Meanings

| Status         | Meaning                              | Action                  |
|----------------|--------------------------------------|-------------------------|
| REVISAR_STOCK  | Negative stock — data inconsistency  | Audit POS system        |
| CRITICO        | Zero stock, product was selling      | Order immediately       |
| REPOSICION     | Stock below recent demand            | Order to cover gap      |
| BUFFER_MINIMO  | One unit left, risk of stockout      | Order one unit buffer   |
| OK             | Stock covers recent demand           | No action               |

## Business Constraints

- Sales window: 2 days (snapshot from POS export)
- Currency: PYG (Paraguayan Guaraní) — costs are large integers, normal
- Negative stock: happens due to POS sync issues — treat as data error
- `envios > 0` means product is already on order — factor into UI display
- `cant` is the supplier pack size — order quantities should respect this
  (future rule, not yet implemented)
- Over-ordering is the primary risk — always prefer conservative quantities

## Output Format

Each product in the analysis result has:
```python
{
    "codigo": str,
    "producto": str,
    "cant": int,
    "costo": int,
    "stock": int,
    "ventas": int,
    "envios": int,
    "status": Literal["CRITICO", "REPOSICION", "BUFFER_MINIMO", "OK", "REVISAR_STOCK"],
    "pedido": int,   # suggested order quantity
}
```

## Known Edge Cases

- `stock == 0 and sales == 0` → CRITICO with `order = 0`
  (product exists in system but had no recent activity — include in report)
- `stock < 0` → always REVISAR_STOCK regardless of sales value
- `envios > 0 and stock == 0` → CRITICO but product is already on order
  (display warning in UI, do not double-order)

## Future Rules (not yet implemented)

- Monthly reposition: first day of month uses 30-day sales window
- Pack size rounding: round order up to nearest `cant`
- Dead stock detection: stock > 0 and ventas == 0 for N days
- Supplier lead time: adjust buffer based on delivery frequency