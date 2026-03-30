# scripts/run_analysis.py

import sys
import warnings
from collections import Counter
from datetime import datetime
from pathlib import Path

import pandas as pd

sys.path.insert(0, str(Path(__file__).parent.parent))

from core.rules import calculate_order
from core.status import classify_status

OUTPUTS_DIR = Path(__file__).parent.parent / "outputs"
PROCESSED_DIR = Path(__file__).parent.parent / "data" / "processed"


def format_report(results: list) -> str:
    counts = Counter(r["status"] for r in results)
    lines = ["RESUMEN:\n"]

    for status in ["CRITICO", "REPOSICION", "BUFFER_MINIMO", "OK", "REVISAR_STOCK"]:
        count = counts.get(status, 0)
        if count:
            lines.append(f"  {status}: {count} productos")

    lines.append("\n---\n")

    for r in results:
        if r["status"] != "OK":
            line = (
                f"  [{r['status']}] {r['producto']} "
                f"| stock={r['stock']} ventas={r['ventas']} pedido={r['pedido']}"
            )
            lines.append(line)

    return "\n".join(lines)


def run(filepath: str) -> None:
    path = Path(filepath)
    if not path.exists():
        print(f"File not found: {filepath}")
        sys.exit(1)

    with warnings.catch_warnings():
        warnings.simplefilter("ignore")
        df = pd.read_excel(path, engine="xlrd")

    results = []
    for _, row in df.iterrows():
        stock = int(row["stock"])
        sales = int(row["ventas"])
        results.append({
            "codigo": row["codigo"],
            "producto": row["producto"],
            "cant": row["cant"],
            "costo": row["costo"],
            "stock": stock,
            "ventas": sales,
            "envios": row["envios"],
            "status": classify_status(stock, sales),
            "pedido": calculate_order(stock, sales),
        })

    report = format_report(results)
    print(report)

    OUTPUTS_DIR.mkdir(exist_ok=True)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    stem = path.stem

    output_path = OUTPUTS_DIR / f"analysis_{stem}_{timestamp}.txt"
    output_path.write_text(report, encoding="utf-8")
    print(f"\n✅ Report saved to {output_path}")

    PROCESSED_DIR.mkdir(parents=True, exist_ok=True)
    processed_path = PROCESSED_DIR / f"{stem}_processed.csv"
    pd.DataFrame(results).to_csv(processed_path, index=False, encoding="utf-8")
    print(f"✅ Processed CSV saved to {processed_path}")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python scripts/run_analysis.py <xls_path>")
        sys.exit(1)
    run(sys.argv[1])