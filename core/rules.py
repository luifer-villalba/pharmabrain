# core/rules.py


def calculate_order(stock: int, sales: int) -> int:
    if stock < 0:
        return 0
    elif stock == 0:
        return sales
    elif stock >= sales:
        if stock == 1 and sales >= 1:
            return 1
        return 0
    else:
        return sales - stock
