# Decisions Log – Pharma Brain

This document captures the operational rules derived from real pharmacy workflows.

## 1. Source of Truth
- Current stock
- Recent sales (2-day window)

## 2. Core Rule
if stock == 0:
    order = sales
elif stock >= sales:
    order = 0
else:
    order = sales - stock

## 3. Defensive Strategy
- Small orders
- Avoid overstock
- Protect cash

## 4. Buffer Rule
stock == 1 and sales >= 1 → order = 1

## 5. Stock Integrity
stock < 0 → REVISAR_STOCK

## 6. Status Types
- REVISAR_STOCK
- CRITICO
- REPOSICION
- BUFFER_MINIMO
- OK
