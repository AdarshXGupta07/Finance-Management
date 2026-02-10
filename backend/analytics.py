from collections import defaultdict
from datetime import date
from decimal import Decimal

from sqlalchemy import extract, func

from models import db, Transaction, Budget, FinancialInsight, Category


def _to_float(value):
    return float(value or 0)


def calculate_monthly_summary(user_id: int, month: int, year: int):
    base = Transaction.query.filter(
        Transaction.user_id == user_id,
        extract("month", Transaction.transaction_date) == month,
        extract("year", Transaction.transaction_date) == year,
    )

    total_income = _to_float(
        base.with_entities(func.sum(Transaction.amount)).filter(Transaction.transaction_type == "income").scalar()
    )
    total_expense = _to_float(
        base.with_entities(func.sum(Transaction.amount)).filter(Transaction.transaction_type == "expense").scalar()
    )
    savings = total_income - total_expense

    budget_limit = _to_float(
        Budget.query.with_entities(func.sum(Budget.limit_amount)).filter_by(
            user_id=user_id, period_month=month, period_year=year
        ).scalar()
    )
    overspending = bool(budget_limit and total_expense > budget_limit)

    consistency_score = 0.0
    if total_income > 0:
        consistency_score = max(0.0, min(100.0, (savings / total_income) * 100))

    if overspending:
        msg = "You are overspending this month"
    elif consistency_score >= 25:
        msg = "Your savings are improving"
    else:
        msg = "Track expenses closely to improve savings"

    return {
        "total_income": total_income,
        "total_expense": total_expense,
        "savings": savings,
        "savings_consistency_score": round(consistency_score, 2),
        "overspending_flag": overspending,
        "generated_message": msg,
        "budget_limit": budget_limit,
    }


def upsert_financial_insight(user_id: int, month: int, year: int):
    summary = calculate_monthly_summary(user_id, month, year)
    insight = FinancialInsight.query.filter_by(user_id=user_id, insight_month=month, insight_year=year).first()
    if not insight:
        insight = FinancialInsight(user_id=user_id, insight_month=month, insight_year=year, generated_message="")
        db.session.add(insight)

    insight.total_income = Decimal(str(summary["total_income"]))
    insight.total_expense = Decimal(str(summary["total_expense"]))
    insight.savings = Decimal(str(summary["savings"]))
    insight.savings_consistency_score = Decimal(str(summary["savings_consistency_score"]))
    insight.overspending_flag = summary["overspending_flag"]
    insight.generated_message = summary["generated_message"]
    db.session.commit()
    return summary


def chart_data(user_id: int, year: int):
    monthly_income = defaultdict(float)
    monthly_expense = defaultdict(float)

    rows = (
        db.session.query(
            extract("month", Transaction.transaction_date).label("month"),
            Transaction.transaction_type,
            func.sum(Transaction.amount).label("total"),
        )
        .filter(Transaction.user_id == user_id, extract("year", Transaction.transaction_date) == year)
        .group_by("month", Transaction.transaction_type)
        .all()
    )

    for month, t_type, total in rows:
        if t_type == "income":
            monthly_income[int(month)] = _to_float(total)
        else:
            monthly_expense[int(month)] = _to_float(total)

    return {
        "months": list(range(1, 13)),
        "income": [monthly_income[m] for m in range(1, 13)],
        "expense": [monthly_expense[m] for m in range(1, 13)],
    }


def category_expense_data(user_id: int, month: int, year: int):
    data = (
        db.session.query(
            Transaction.category_id,
            func.sum(Transaction.amount).label("total"),
        )
        .filter(
            Transaction.user_id == user_id,
            Transaction.transaction_type == "expense",
            extract("month", Transaction.transaction_date) == month,
            extract("year", Transaction.transaction_date) == year,
        )
        .group_by(Transaction.category_id)
        .all()
    )

    labels, values = [], []
    for cat_id, total in data:
        if cat_id is None:
            labels.append("Uncategorized")
        else:
            category = Category.query.get(cat_id)
            labels.append(category.category_name if category else "Unknown")
        values.append(_to_float(total))

    return {"labels": labels, "values": values}


def expense_heavy_days(user_id: int, month: int, year: int):
    rows = (
        db.session.query(Transaction.transaction_date, func.sum(Transaction.amount).label("daily_expense"))
        .filter(
            Transaction.user_id == user_id,
            Transaction.transaction_type == "expense",
            extract("month", Transaction.transaction_date) == month,
            extract("year", Transaction.transaction_date) == year,
        )
        .group_by(Transaction.transaction_date)
        .order_by(func.sum(Transaction.amount).desc())
        .limit(5)
        .all()
    )
    return [{"date": d.isoformat(), "amount": _to_float(a)} for d, a in rows]


def current_period():
    today = date.today()
    return today.month, today.year
