# Personal Finance Management System (PFMS)

A complete DBMS academic project implementing a **ready-to-run** Personal Finance Management System with strict separation of frontend, backend, and database layers.

## Project Structure

```text
PersonalFinanceManagementSystem/
├── frontend/
│   ├── templates/
│   └── static/
├── backend/
│   ├── app.py
│   ├── routes.py
│   ├── models.py
│   ├── analytics.py
│   ├── auth.py
│   ├── config.py
│   └── requirements.txt
├── database/
│   ├── schema.sql
│   ├── sample_data.sql
│   └── er_diagram.drawio.xml
└── README.md
```

## Features

- Secure user registration/login (password hashing with Werkzeug)
- Unlimited income/expense entries
- Category-based transaction organization
- Budget planning by month/year (+ optional category budget)
- Goal tracking with target/current/deadline
- Bill reminders with due dates and recurrence
- Smart financial behavior analysis:
  - Overspending detection
  - Budget breach alerts
  - Expense-heavy days
  - Savings consistency score
  - Monthly summary insights
- Visual analytics via Chart.js:
  - Income vs Expense (bar)
  - Category-wise Expense (pie)
  - Monthly trend (line)
  - Budget utilization meter

## Setup and Run

1. Create database and tables:
   ```bash
   mysql -u root -p < database/schema.sql
   mysql -u root -p < database/sample_data.sql
   ```
2. Install backend dependencies:
   ```bash
   cd backend
   pip install -r requirements.txt
   ```
3. Update DB credentials only (if needed):
   - Edit `backend/config.py` and change `SQLALCHEMY_DATABASE_URI`
   - OR set env var:
     ```bash
     export DATABASE_URL='mysql+pymysql://<user>:<password>@localhost/pfms_db'
     ```
4. Run application:
   ```bash
   python app.py
   ```
5. Open browser: `http://127.0.0.1:5000`

## ER Diagram Explanation

The ER diagram (`database/er_diagram.drawio.xml`) contains these entities:

1. **User** – master entity for each system user.
2. **Account** – bank/cash accounts owned by a user.
3. **Category** – reusable income/expense categories.
4. **Transaction** – central fact table referencing user, account, category.
5. **Budget** – month-year spending constraints per user (and optional category).
6. **Goal** – user savings/target objectives.
7. **Bill** – recurring dues and reminders.
8. **FinancialInsight** – derived monthly analytics and smart alerts.

### Cardinality (1:N)
- User → Accounts
- User → Transactions
- Category → Transactions
- Account → Transactions
- User → Budgets
- User → Goals
- User → Bills
- User → FinancialInsights

## Normalization (3NF)

- **1NF**: Atomic attributes (no repeating groups); transactions and bills are row-based records.
- **2NF**: Non-key attributes fully dependent on primary key (single-column surrogate keys for each table).
- **3NF**: Removed transitive dependencies:
  - Category details stored only in `categories`.
  - User profile stored only in `users`.
  - Insights separated into `financial_insights` instead of denormalized in `transactions`.

## Why this PFMS is better than basic trackers

- Not just CRUD: includes **behavioral intelligence**.
- Calculates **savings consistency score** and **overspending flags**.
- Generates contextual alerts like:
  - “You are overspending this month”
  - “Your savings are improving”
- Highlights expense-heavy days for actionable control.
- DBMS-friendly architecture with complete schema, constraints, and ER design.

## Viva-ready DBMS talking points

- Demonstrates complete SDLC separation: UI (frontend), API/business logic (backend), and persistent relational storage (database).
- Enforces data integrity with PK/FK/UNIQUE/CHECK constraints.
- Uses ORM (SQLAlchemy) + raw SQL schema for academic clarity.
- Shows relationship mapping and normalization rationale clearly.
- Implements analytical SQL aggregations and stores monthly insight snapshots.
