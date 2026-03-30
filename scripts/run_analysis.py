# scripts/run_analysis.py

import sys
from pathlib import Path
from collections import Counter

import pandas as pd

sys.path.insert(0, str(Path(__file__).parent.parent))

from core.rules import calculate_order
from core.status import classify_status


def run(filepath: str) -> None:
    path = Path(filepath)
    if not path.exists():
        print(f"File not found: {filepath}")
        sys.exit(1)

    df = pd.read_excel(path, engine="xlrd")
    df = df.rename(columns={"cant": "pos_sugerido", "ventas": "ventas_2d", "envios": "envios_2d"})

    results = []
    for _, row in df.iterrows():
        stock = int(row["stock"])
        sales = int(row["ventas_2d"])
        status = classify_status(stock, sales)
        order = calculate_order(stock, sales)
        results.append({
            "codigo": row["codigo"],
            "producto": row["producto"],
            "stock": stock,
            "ventas_2d": sales,
            "status": status,
            "pedido": order,
        })

    counts = Counter(r["status"] for r in results)

    print("RESUMEN:\n")
    for status in ["CRITICO", "REPOSICION", "BUFFER_MINIMO", "OK", "REVISAR_STOCK"]:
        count = counts.get(status, 0)
        if count:
            print(f"  {status}: {count} productos")

    print("\n---\n")

    for r in results:
        if r["status"] != "OK":
            line = (
                f"  [{r['status']}] {r['producto']} "
                f"| stock={r['stock']} ventas={r['ventas_2d']} pedido={r['pedido']}"
            )
            print(line)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python scripts/run_analysis.py <xls_path>")
        sys.exit(1)
    run(sys.argv[1])