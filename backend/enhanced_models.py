from datetime import date, datetime
from flask_sqlalchemy import SQLAlchemy
from flask_login import UserMixin
from werkzeug.security import generate_password_hash, check_password_hash
import enum


db = SQLAlchemy()


class User(UserMixin, db.Model):
    __tablename__ = "users"

    user_id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(100), unique=True, nullable=False, index=True)
    password_hash = db.Column(db.String(255), nullable=False)
    phone = db.Column(db.String(20))
    date_of_birth = db.Column(db.Date)
    monthly_income_target = db.Column(db.Numeric(12, 2))
    created_at = db.Column(db.DateTime, server_default=db.func.now())
    updated_at = db.Column(db.DateTime, server_default=db.func.now(), onupdate=db.func.now())

    accounts = db.relationship("Account", back_populates="user", cascade="all, delete-orphan")
    transactions = db.relationship("Transaction", back_populates="user", cascade="all, delete-orphan")
    budgets = db.relationship("Budget", back_populates="user", cascade="all, delete-orphan")
    goals = db.relationship("Goal", back_populates="user", cascade="all, delete-orphan")
    bills = db.relationship("Bill", back_populates="user", cascade="all, delete-orphan")
    insights = db.relationship("FinancialInsight", back_populates="user", cascade="all, delete-orphan")
    preferences = db.relationship("UserPreference", back_populates="user", uselist=False, cascade="all, delete-orphan")

    def set_password(self, password: str) -> None:
        self.password_hash = generate_password_hash(password)

    def check_password(self, password: str) -> bool:
        return check_password_hash(self.password_hash, password)

    def get_id(self):
        return str(self.user_id)


class AccountType(db.Model):
    __tablename__ = "account_types"

    type_id = db.Column(db.Integer, primary_key=True)
    type_name = db.Column(db.String(50), unique=True, nullable=False)

    accounts = db.relationship("Account", back_populates="account_type")


class Account(db.Model):
    __tablename__ = "accounts"

    account_id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.user_id", ondelete="CASCADE"), nullable=False)
    account_name = db.Column(db.String(100), nullable=False)
    account_type_id = db.Column(db.Integer, db.ForeignKey("account_types.type_id"), nullable=False)
    balance = db.Column(db.Numeric(12, 2), nullable=False, default=0)
    currency = db.Column(db.String(3), default='USD')
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, server_default=db.func.now())
    updated_at = db.Column(db.DateTime, server_default=db.func.now(), onupdate=db.func.now())

    user = db.relationship("User", back_populates="accounts")
    account_type = db.relationship("AccountType", back_populates="accounts")
    transactions = db.relationship("Transaction", back_populates="account")


class Category(db.Model):
    __tablename__ = "categories"

    category_id = db.Column(db.Integer, primary_key=True)
    category_name = db.Column(db.String(100), nullable=False)
    category_type = db.Column(db.String(20), nullable=False)
    is_default = db.Column(db.Boolean, nullable=False, default=False)
    tags = db.Column(db.String(255))  # SET type stored as string
    color_code = db.Column(db.String(7), default='#000000')
    created_at = db.Column(db.DateTime, server_default=db.func.now())

    transactions = db.relationship("Transaction", back_populates="category")
    budgets = db.relationship("Budget", back_populates="category")


class Transaction(db.Model):
    __tablename__ = "transactions"

    transaction_id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.user_id", ondelete="CASCADE"), nullable=False, index=True)
    account_id = db.Column(db.Integer, db.ForeignKey("accounts.account_id", ondelete="SET NULL"), nullable=True)
    category_id = db.Column(db.Integer, db.ForeignKey("categories.category_id", ondelete="SET NULL"), nullable=True)
    transaction_type = db.Column(db.String(20), nullable=False)
    amount = db.Column(db.Numeric(12, 2), nullable=False)
    transaction_date = db.Column(db.Date, nullable=False, default=date.today)
    description = db.Column(db.String(255))
    location = db.Column(db.String(100))
    receipt_number = db.Column(db.String(50))
    is_recurring = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, server_default=db.func.now())
    updated_at = db.Column(db.DateTime, server_default=db.func.now(), onupdate=db.func.now())

    user = db.relationship("User", back_populates="transactions")
    account = db.relationship("Account", back_populates="transactions")
    category = db.relationship("Category", back_populates="transactions")
    tags = db.relationship("TransactionTag", back_populates="transaction", cascade="all, delete-orphan")


class TransactionTag(db.Model):
    __tablename__ = "transaction_tags"

    transaction_id = db.Column(db.Integer, db.ForeignKey("transactions.transaction_id", ondelete="CASCADE"), primary_key=True)
    tag_name = db.Column(db.String(50), primary_key=True)

    transaction = db.relationship("Transaction", back_populates="tags")


class Budget(db.Model):
    __tablename__ = "budgets"

    budget_id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.user_id", ondelete="CASCADE"), nullable=False)
    category_id = db.Column(db.Integer, db.ForeignKey("categories.category_id", ondelete="SET NULL"), nullable=True)
    period_month = db.Column(db.Integer, nullable=False)
    period_year = db.Column(db.Integer, nullable=False)
    limit_amount = db.Column(db.Numeric(12, 2), nullable=False)
    spent_amount = db.Column(db.Numeric(12, 2), nullable=False, default=0)
    alert_threshold = db.Column(db.Numeric(5, 2), default=80.00)
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, server_default=db.func.now())
    updated_at = db.Column(db.DateTime, server_default=db.func.now(), onupdate=db.func.now())

    user = db.relationship("User", back_populates="budgets")
    category = db.relationship("Category")


class Goal(db.Model):
    __tablename__ = "goals"

    goal_id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.user_id", ondelete="CASCADE"), nullable=False)
    goal_name = db.Column(db.String(100), nullable=False)
    target_amount = db.Column(db.Numeric(12, 2), nullable=False)
    current_amount = db.Column(db.Numeric(12, 2), nullable=False, default=0)
    deadline = db.Column(db.Date)
    priority = db.Column(db.String(20), default='medium')
    status = db.Column(db.String(20), default='active')
    auto_contribute = db.Column(db.Boolean, default=False)
    contribution_amount = db.Column(db.Numeric(12, 2))
    created_at = db.Column(db.DateTime, server_default=db.func.now())
    updated_at = db.Column(db.DateTime, server_default=db.func.now(), onupdate=db.func.now())

    user = db.relationship("User", back_populates="goals")


class Bill(db.Model):
    __tablename__ = "bills"

    bill_id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.user_id", ondelete="CASCADE"), nullable=False)
    bill_name = db.Column(db.String(100), nullable=False)
    amount = db.Column(db.Numeric(12, 2), nullable=False)
    due_date = db.Column(db.Date, nullable=False)
    recurrence = db.Column(db.String(20), nullable=False, default='monthly')
    status = db.Column(db.String(20), nullable=False, default='pending')
    paid_date = db.Column(db.Date)
    late_fee = db.Column(db.Numeric(12, 2), default=0)
    autopay = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, server_default=db.func.now())
    updated_at = db.Column(db.DateTime, server_default=db.func.now(), onupdate=db.func.now())

    user = db.relationship("User", back_populates="bills")


class FinancialInsight(db.Model):
    __tablename__ = "financial_insights"

    insight_id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.user_id", ondelete="CASCADE"), nullable=False)
    insight_month = db.Column(db.Integer, nullable=False)
    insight_year = db.Column(db.Integer, nullable=False)
    total_income = db.Column(db.Numeric(12, 2), nullable=False, default=0)
    total_expense = db.Column(db.Numeric(12, 2), nullable=False, default=0)
    savings = db.Column(db.Numeric(12, 2), nullable=False, default=0)
    savings_rate = db.Column(db.Numeric(5, 2), nullable=False, default=0)
    savings_consistency_score = db.Column(db.Numeric(5, 2), nullable=False, default=0)
    overspending_flag = db.Column(db.Boolean, nullable=False, default=False)
    budget_utilization = db.Column(db.Numeric(5, 2), default=0)
    top_expense_category = db.Column(db.String(100))
    financial_health_score = db.Column(db.Numeric(5, 2), default=0)
    generated_message = db.Column(db.String(255), nullable=False)
    created_at = db.Column(db.DateTime, server_default=db.func.now())

    user = db.relationship("User", back_populates="insights")


class UserPreference(db.Model):
    __tablename__ = "user_preferences"

    preference_id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.user_id", ondelete="CASCADE"), nullable=False, unique=True)
    currency = db.Column(db.String(3), default='USD')
    date_format = db.Column(db.String(20), default='%Y-%m-%d')
    timezone = db.Column(db.String(50), default='UTC')
    email_notifications = db.Column(db.Boolean, default=True)
    budget_alerts = db.Column(db.Boolean, default=True)
    goal_reminders = db.Column(db.Boolean, default=True)
    bill_reminders = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, server_default=db.func.now())
    updated_at = db.Column(db.DateTime, server_default=db.func.now(), onupdate=db.func.now())

    user = db.relationship("User", back_populates="preferences")


class AuditLog(db.Model):
    __tablename__ = "audit_log"

    log_id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.user_id", ondelete="SET NULL"))
    table_name = db.Column(db.String(50), nullable=False)
    record_id = db.Column(db.Integer, nullable=False)
    action = db.Column(db.String(20), nullable=False)
    old_values = db.Column(db.Text)
    new_values = db.Column(db.Text)
    changed_at = db.Column(db.DateTime, server_default=db.func.now())
    ip_address = db.Column(db.String(45))
    user_agent = db.Column(db.Text)

    user = db.relationship("User")


# Views (using SQLAlchemy's text() for raw SQL)
class UserFinancialSummary(db.Model):
    __tablename__ = "user_financial_summary"

    user_id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100))
    email = db.Column(db.String(100))
    account_count = db.Column(db.Integer)
    total_balance = db.Column(db.Numeric(12, 2))
    total_income = db.Column(db.Numeric(12, 2))
    total_expense = db.Column(db.Numeric(12, 2))
    net_savings = db.Column(db.Numeric(12, 2))
    active_goals = db.Column(db.Integer)
    total_goal_target = db.Column(db.Numeric(12, 2))
    total_goal_saved = db.Column(db.Numeric(12, 2))
    pending_bills = db.Column(db.Integer)
    total_bills = db.Column(db.Integer)


class BudgetPerformance(db.Model):
    __tablename__ = "budget_performance"

    budget_id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer)
    limit_amount = db.Column(db.Numeric(12, 2))
    spent_amount = db.Column(db.Numeric(12, 2))
    utilization_percentage = db.Column(db.Numeric(5, 2))
    status = db.Column(db.String(20))
    category_name = db.Column(db.String(100))
    period = db.Column(db.String(20))
    user_name = db.Column(db.String(100))


class TransactionAnalytics(db.Model):
    __tablename__ = "transaction_analytics"

    user_id = db.Column(db.Integer, primary_key=True)
    user_name = db.Column(db.String(100))
    transaction_type = db.Column(db.String(20), primary_key=True)
    category_name = db.Column(db.String(100), primary_key=True)
    month_year = db.Column(db.String(20), primary_key=True)
    transaction_count = db.Column(db.Integer)
    total_amount = db.Column(db.Numeric(12, 2))
    average_amount = db.Column(db.Numeric(12, 2))
    min_amount = db.Column(db.Numeric(12, 2))
    max_amount = db.Column(db.Numeric(12, 2))


class GoalProgress(db.Model):
    __tablename__ = "goal_progress"

    goal_id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer)
    user_name = db.Column(db.String(100))
    goal_name = db.Column(db.String(100))
    target_amount = db.Column(db.Numeric(12, 2))
    current_amount = db.Column(db.Numeric(12, 2))
    completion_percentage = db.Column(db.Numeric(5, 2))
    progress_status = db.Column(db.String(20))
    days_remaining = db.Column(db.Integer)
    priority = db.Column(db.String(20))
    status = db.Column(db.String(20))


# Database operations using cursors (stored procedures)
class DatabaseOperations:
    @staticmethod
    def calculate_monthly_insights(user_id, month, year):
        """Call stored procedure to calculate monthly financial insights"""
        try:
            result = db.session.execute(
                db.text("CALL calculate_monthly_insights(:user_id, :month, :year)"),
                {"user_id": user_id, "month": month, "year": year}
            )
            db.session.commit()
            return result
        except Exception as e:
            db.session.rollback()
            raise e

    @staticmethod
    def generate_bill_reminders(user_id):
        """Call stored procedure to generate bill reminders using cursor"""
        try:
            result = db.session.execute(
                db.text("CALL generate_bill_reminders(:user_id)"),
                {"user_id": user_id}
            )
            return result.fetchall()
        except Exception as e:
            raise e

    @staticmethod
    def analyze_spending_patterns(user_id, months=12):
        """Call stored procedure to analyze spending patterns using cursor"""
        try:
            result = db.session.execute(
                db.text("CALL analyze_spending_patterns(:user_id, :months)"),
                {"user_id": user_id, "months": months}
            )
            return result.fetchall()
        except Exception as e:
            raise e

    @staticmethod
    def get_user_financial_summary(user_id):
        """Get user financial summary using view"""
        try:
            result = db.session.execute(
                db.text("SELECT * FROM user_financial_summary WHERE user_id = :user_id"),
                {"user_id": user_id}
            )
            return result.fetchone()
        except Exception as e:
            raise e

    @staticmethod
    def get_budget_performance(user_id):
        """Get budget performance using view"""
        try:
            result = db.session.execute(
                db.text("SELECT * FROM budget_performance WHERE user_id = :user_id"),
                {"user_id": user_id}
            )
            return result.fetchall()
        except Exception as e:
            raise e

    @staticmethod
    def get_transaction_analytics(user_id):
        """Get transaction analytics using view"""
        try:
            result = db.session.execute(
                db.text("SELECT * FROM transaction_analytics WHERE user_id = :user_id"),
                {"user_id": user_id}
            )
            return result.fetchall()
        except Exception as e:
            raise e

    @staticmethod
    def get_goal_progress(user_id):
        """Get goal progress using view"""
        try:
            result = db.session.execute(
                db.text("SELECT * FROM goal_progress WHERE user_id = :user_id"),
                {"user_id": user_id}
            )
            return result.fetchall()
        except Exception as e:
            raise e

    @staticmethod
    def log_audit(user_id, table_name, record_id, action, old_values=None, new_values=None, ip_address=None, user_agent=None):
        """Log audit trail"""
        try:
            audit = AuditLog(
                user_id=user_id,
                table_name=table_name,
                record_id=record_id,
                action=action,
                old_values=old_values,
                new_values=new_values,
                ip_address=ip_address,
                user_agent=user_agent
            )
            db.session.add(audit)
            db.session.commit()
        except Exception as e:
            db.session.rollback()
            raise e
