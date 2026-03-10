from datetime import datetime

from flask import Blueprint, render_template, request, redirect, url_for, flash, jsonify
from flask_login import login_required, current_user

from models import db, Account, Category, Transaction, Budget, Goal, Bill
from analytics import (
    current_period,
    upsert_financial_insight,
    chart_data,
    category_expense_data,
    expense_heavy_days,
    render_analytics_plots,
)


main_bp = Blueprint("main", __name__)


def _get_or_create_default_categories():
    defaults = [
        ("Salary", "income"),
        ("Freelance", "income"),
        ("Food", "expense"),
        ("Transport", "expense"),
        ("Utilities", "expense"),
        ("Entertainment", "expense"),
    ]
    for name, ctype in defaults:
        if not Category.query.filter_by(category_name=name, category_type=ctype).first():
            db.session.add(Category(category_name=name, category_type=ctype, is_default=True))
    db.session.commit()


@main_bp.route("/")
def home():
    return redirect(url_for("auth.login"))


@main_bp.route("/dashboard")
@login_required
def dashboard():
    month, year = current_period()
    summary = upsert_financial_insight(current_user.user_id, month, year)
    recent_transactions = (
        Transaction.query.filter_by(user_id=current_user.user_id)
        .order_by(Transaction.transaction_date.desc())
        .limit(10)
        .all()
    )
    upcoming_bills = (
        Bill.query.filter_by(user_id=current_user.user_id, status="pending")
        .order_by(Bill.due_date.asc())
        .limit(5)
        .all()
    )
    return render_template(
        "dashboard.html",
        summary=summary,
        recent_transactions=recent_transactions,
        upcoming_bills=upcoming_bills,
        month=month,
        year=year,
    )


@main_bp.route("/expenses", methods=["GET", "POST"])
@login_required
def expenses():
    _get_or_create_default_categories()
    if request.method == "POST":
        amount = float(request.form["amount"])
        category_id = request.form.get("category_id") or None
        other_category = request.form.get("other_category", "").strip()
        transaction_date = datetime.strptime(request.form["transaction_date"], "%Y-%m-%d").date()
        description = request.form.get("description", "")

        # Handle "Other" category
        final_category_id = None
        if category_id == "other" and other_category:
            # Create new category
            new_cat = Category(
                category_name=other_category,
                category_type="expense",
                is_default=False
            )
            db.session.add(new_cat)
            db.session.commit()
            final_category_id = new_cat.category_id
        elif category_id and category_id != "other":
            final_category_id = int(category_id)

        txn = Transaction(
            user_id=current_user.user_id,
            category_id=final_category_id,
            transaction_type="expense",
            amount=amount,
            transaction_date=transaction_date,
            description=description,
        )
        db.session.add(txn)
        db.session.commit()
        flash("Expense added.", "success")
        return redirect(url_for("main.expenses"))

    categories = Category.query.filter_by(category_type="expense").all()
    records = (
        Transaction.query.filter_by(user_id=current_user.user_id, transaction_type="expense")
        .order_by(Transaction.transaction_date.desc())
        .all()
    )
    return render_template("expenses.html", categories=categories, records=records)


@main_bp.route("/income", methods=["GET", "POST"])
@login_required
def income():
    _get_or_create_default_categories()
    if request.method == "POST":
        amount = float(request.form["amount"])
        category_id = request.form.get("category_id") or None
        other_category = request.form.get("other_category", "").strip()
        transaction_date = datetime.strptime(request.form["transaction_date"], "%Y-%m-%d").date()
        description = request.form.get("description", "")

        # Handle "Other" category
        final_category_id = None
        if category_id == "other" and other_category:
            # Create new category
            new_cat = Category(
                category_name=other_category,
                category_type="income",
                is_default=False
            )
            db.session.add(new_cat)
            db.session.commit()
            final_category_id = new_cat.category_id
        elif category_id and category_id != "other":
            final_category_id = int(category_id)

        txn = Transaction(
            user_id=current_user.user_id,
            category_id=final_category_id,
            transaction_type="income",
            amount=amount,
            transaction_date=transaction_date,
            description=description,
        )
        db.session.add(txn)
        db.session.commit()
        flash("Income added.", "success")
        return redirect(url_for("main.income"))

    categories = Category.query.filter_by(category_type="income").all()
    records = (
        Transaction.query.filter_by(user_id=current_user.user_id, transaction_type="income")
        .order_by(Transaction.transaction_date.desc())
        .all()
    )
    return render_template("income.html", categories=categories, records=records)


@main_bp.route("/delete-expense/<int:transaction_id>", methods=["POST"])
@login_required
def delete_expense(transaction_id):
    txn = Transaction.query.filter_by(transaction_id=transaction_id, user_id=current_user.user_id, transaction_type="expense").first_or_404()
    db.session.delete(txn)
    db.session.commit()
    flash("Expense deleted.", "success")
    return redirect(url_for("main.expenses"))


@main_bp.route("/delete-income/<int:transaction_id>", methods=["POST"])
@login_required
def delete_income(transaction_id):
    txn = Transaction.query.filter_by(transaction_id=transaction_id, user_id=current_user.user_id, transaction_type="income").first_or_404()
    db.session.delete(txn)
    db.session.commit()
    flash("Income deleted.", "success")
    return redirect(url_for("main.income"))


@main_bp.route("/budget", methods=["GET", "POST"])
@login_required
def budget():
    _get_or_create_default_categories()
    if request.method == "POST":
        month = int(request.form["period_month"])
        year = int(request.form["period_year"])
        limit_amount = float(request.form["limit_amount"])
        category_id = request.form.get("category_id") or None

        entry = Budget(
            user_id=current_user.user_id,
            period_month=month,
            period_year=year,
            limit_amount=limit_amount,
            category_id=int(category_id) if category_id else None,
        )
        db.session.add(entry)
        db.session.commit()
        flash("Budget saved.", "success")
        return redirect(url_for("main.budget"))

    budgets = Budget.query.filter_by(user_id=current_user.user_id).order_by(Budget.period_year.desc(), Budget.period_month.desc()).all()
    categories = Category.query.filter_by(category_type="expense").all()
    return render_template("budget.html", budgets=budgets, categories=categories)


@main_bp.route("/goals", methods=["GET", "POST"])
@login_required
def goals():
    if request.method == "POST":
        goal_name = request.form["goal_name"]
        target_amount = float(request.form["target_amount"])
        current_amount = float(request.form.get("current_amount", 0))
        deadline = request.form.get("deadline") or None

        goal = Goal(
            user_id=current_user.user_id,
            goal_name=goal_name,
            target_amount=target_amount,
            current_amount=current_amount,
            deadline=datetime.strptime(deadline, "%Y-%m-%d").date() if deadline else None,
        )
        db.session.add(goal)
        db.session.commit()
        flash("Goal created.", "success")
        return redirect(url_for("main.goals"))

    records = Goal.query.filter_by(user_id=current_user.user_id).order_by(Goal.created_at.desc()).all()
    return render_template("goals.html", records=records)


@main_bp.route("/bills", methods=["GET", "POST"])
@login_required
def bills():
    if request.method == "POST":
        bill = Bill(
            user_id=current_user.user_id,
            bill_name=request.form["bill_name"],
            amount=float(request.form["amount"]),
            due_date=datetime.strptime(request.form["due_date"], "%Y-%m-%d").date(),
            recurrence=request.form.get("recurrence", "monthly"),
            status=request.form.get("status", "pending"),
        )
        db.session.add(bill)
        db.session.commit()
        flash("Bill saved.", "success")
        return redirect(url_for("main.bills"))

    records = Bill.query.filter_by(user_id=current_user.user_id).order_by(Bill.due_date.asc()).all()
    return render_template("bills.html", records=records)


@main_bp.route("/analytics")
@login_required
def analytics_page():
    month, year = current_period()
    summary = upsert_financial_insight(current_user.user_id, month, year)
    heavy_days = expense_heavy_days(current_user.user_id, month, year)
    plots = render_analytics_plots(current_user.user_id, month, year)
    return render_template("analytics.html", summary=summary, heavy_days=heavy_days, year=year, plots=plots)


@main_bp.route("/api/analytics")
@login_required
def analytics_api():
    month, year = current_period()
    summary = upsert_financial_insight(current_user.user_id, month, year)
    annual = chart_data(current_user.user_id, year)
    category = category_expense_data(current_user.user_id, month, year)
    return jsonify(
        {
            "summary": summary,
            "annual": annual,
            "category": category,
            "heavy_days": expense_heavy_days(current_user.user_id, month, year),
        }
    )
