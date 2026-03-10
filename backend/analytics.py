from collections import defaultdict
from datetime import date
from decimal import Decimal
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import seaborn as sns
from sqlalchemy import extract, func

from models import db, Transaction, Budget, Category


def _to_float(value):
    if value is None:
        return 0.0
    if isinstance(value, Decimal):
        return float(value)
    return float(value)


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
    # Kept for route compatibility: now computes analytics on demand
    return calculate_monthly_summary(user_id, month, year)


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


def render_analytics_plots(user_id: int, month: int, year: int):
    sns.set_theme(style="whitegrid")
    annual = chart_data(user_id, year)
    category = category_expense_data(user_id, month, year)

    out_dir = Path(__file__).resolve().parent.parent / "frontend" / "static" / "generated"
    out_dir.mkdir(parents=True, exist_ok=True)

    income_expense_path = out_dir / f"income_expense_{user_id}.png"
    category_path = out_dir / f"category_{user_id}.png"
    trend_path = out_dir / f"trend_{user_id}.png"

    plt.figure(figsize=(6, 4))
    sns.barplot(x=["Income", "Expense"], y=[sum(annual["income"]), sum(annual["expense"])], palette=["#198754", "#dc3545"])
    plt.title("Annual Income vs Expense")
    plt.tight_layout()
    plt.savefig(income_expense_path)
    plt.close()

    plt.figure(figsize=(6, 4))
    if category["values"]:
        plt.pie(category["values"], labels=category["labels"], autopct="%1.1f%%")
        plt.title("Category-wise Expense")
    else:
        plt.text(0.5, 0.5, "No expense data", ha="center", va="center")
        plt.axis("off")
    plt.tight_layout()
    plt.savefig(category_path)
    plt.close()

    plt.figure(figsize=(8, 4))
    sns.lineplot(x=annual["months"], y=annual["income"], label="Income", color="#198754")
    sns.lineplot(x=annual["months"], y=annual["expense"], label="Expense", color="#dc3545")
    plt.title("Monthly Trend")
    plt.xlabel("Month")
    plt.ylabel("Amount")
    plt.tight_layout()
    plt.savefig(trend_path)
    plt.close()

    return {
        "income_expense_plot": f"generated/{income_expense_path.name}",
        "category_plot": f"generated/{category_path.name}",
        "trend_plot": f"generated/{trend_path.name}",
    }


def current_period():
    today = date.today()
    return today.month, today.year
