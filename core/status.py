# core/status.py


def classify_status(stock: int, sales: int) -> str:
    if stock < 0:
        return "REVISAR_STOCK"
    elif stock == 0:
        return "CRITICO"
    elif stock >= sales:
        if stock == 1 and sales >= 1:
            return "BUFFER_MINIMO"
        return "OK"
    else:
        return "REPOSICION"
