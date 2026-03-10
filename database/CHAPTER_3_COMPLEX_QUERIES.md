# CHAPTER 3: Complex Queries

This chapter documents complex DBMS queries for the required concepts:
- Constraints
- Aggregate Functions
- Sets
- Subqueries
- Joins
- Views
- Triggers
- Cursors

Each subsection includes:
1. **Question**
2. **SQL Statement**
3. **Output** (sample result format)
4. **How and Why** (implementation purpose)

---

## 3.1 Adding Constraints and Queries Based on Constraints

### Question 1
How do we enforce unique user emails?

**SQL Statement:**
```sql
ALTER TABLE users
ADD CONSTRAINT uq_users_email UNIQUE (email);
```

**Output:**
```text
Query OK, 0 rows affected
```

**How and Why:**
This ensures no two users can register with the same email. It protects data integrity and avoids duplicate login identities.

### Question 2
How do we restrict budget values to positive amounts?

**SQL Statement:**
```sql
ALTER TABLE budgets
ADD CONSTRAINT chk_budget_limit CHECK (limit_amount > 0);
```

**Output:**
```text
Query OK, 0 rows affected
```

**How and Why:**
A budget cannot be zero or negative in this business domain. The CHECK constraint prevents invalid financial planning data.

### Question 3
How do we reject invalid transaction-user references?

**SQL Statement:**
```sql
ALTER TABLE transactions
ADD CONSTRAINT fk_txn_user FOREIGN KEY (user_id)
REFERENCES users(user_id) ON DELETE CASCADE;
```

**Output:**
```text
Query OK, 0 rows affected
```

**How and Why:**
The foreign key ensures every transaction belongs to a valid user. `ON DELETE CASCADE` avoids orphan records when a user is removed.

---

## 3.2 Queries Based on Aggregate Functions

### Question 1
What is each user's total income and total expense?

**SQL Statement:**
```sql
SELECT
  user_id,
  SUM(CASE WHEN transaction_type = 'income' THEN amount ELSE 0 END) AS total_income,
  SUM(CASE WHEN transaction_type = 'expense' THEN amount ELSE 0 END) AS total_expense
FROM transactions
GROUP BY user_id;
```

**Output:**

| user_id | total_income | total_expense |
|---|---:|---:|
| 1 | 85000.00 | 32500.00 |
| 2 | 72000.00 | 28100.00 |

**How and Why:**
Conditional aggregation splits income and expense in one grouped query, giving monthly/overall financial summary per user.

### Question 2
What is the average expense amount per category?

**SQL Statement:**
```sql
SELECT c.category_name, AVG(t.amount) AS avg_expense
FROM transactions t
JOIN categories c ON t.category_id = c.category_id
WHERE t.transaction_type = 'expense'
GROUP BY c.category_name;
```

**Output:**

| category_name | avg_expense |
|---|---:|
| Food | 640.50 |
| Transport | 410.00 |
| Utilities | 1200.75 |

**How and Why:**
`AVG()` helps understand spending intensity by category, useful for budget optimization.

### Question 3
Which users have done more than 10 transactions?

**SQL Statement:**
```sql
SELECT user_id, COUNT(*) AS txn_count
FROM transactions
GROUP BY user_id
HAVING COUNT(*) > 10;
```

**Output:**

| user_id | txn_count |
|---|---:|
| 1 | 18 |
| 2 | 14 |

**How and Why:**
`HAVING` filters grouped results and identifies high-activity users for behavioral analysis.

---

## 3.3 Complex Queries Based on Sets

### Question 1
List all category names used for either income or expense without duplicates.

**SQL Statement:**
```sql
SELECT category_name FROM categories WHERE category_type = 'income'
UNION
SELECT category_name FROM categories WHERE category_type = 'expense';
```

**Output:**

| category_name |
|---|
| Salary |
| Freelance |
| Food |
| Rent |
| Utilities |

**How and Why:**
`UNION` performs set combination and removes duplicates by default.

### Question 2
Show categories that appear in both income and expense sets.

**SQL Statement:**
```sql
SELECT category_name FROM categories WHERE category_type = 'income'
INTERSECT
SELECT category_name FROM categories WHERE category_type = 'expense';
```

**Output:**

| category_name |
|---|
| Bonus |

**How and Why:**
Set intersection helps identify overlapping category labels across domains (if DB version supports `INTERSECT`).

### Question 3
Show categories that are income-only (not in expense set).

**SQL Statement:**
```sql
SELECT category_name FROM categories WHERE category_type = 'income'
EXCEPT
SELECT category_name FROM categories WHERE category_type = 'expense';
```

**Output:**

| category_name |
|---|
| Salary |
| Freelance |

**How and Why:**
Set difference finds exclusive values and supports taxonomy cleanup. For MySQL versions without `EXCEPT`, use `LEFT JOIN ... IS NULL` alternative.

---

## 3.4 Complex Queries Based on Subqueries

### Question 1
Find users whose total expenses are above the global average expense per user.

**SQL Statement:**
```sql
SELECT user_id, SUM(amount) AS total_expense
FROM transactions
WHERE transaction_type = 'expense'
GROUP BY user_id
HAVING SUM(amount) > (
  SELECT AVG(user_expense)
  FROM (
    SELECT user_id, SUM(amount) AS user_expense
    FROM transactions
    WHERE transaction_type = 'expense'
    GROUP BY user_id
  ) x
);
```

**Output:**

| user_id | total_expense |
|---|---:|
| 1 | 32500.00 |

**How and Why:**
Nested subquery computes benchmark first, then outer query compares each user against that benchmark.

### Question 2
Fetch transactions greater than the user's own average transaction amount.

**SQL Statement:**
```sql
SELECT t.*
FROM transactions t
WHERE t.amount > (
  SELECT AVG(t2.amount)
  FROM transactions t2
  WHERE t2.user_id = t.user_id
);
```

**Output:**
```text
Rows with above-average amount per corresponding user
```

**How and Why:**
Correlated subquery personalizes filtering by each user's spending pattern.

### Question 3
Find categories with expense totals greater than the category-wise median proxy (average).

**SQL Statement:**
```sql
SELECT c.category_name, SUM(t.amount) AS category_total
FROM transactions t
JOIN categories c ON c.category_id = t.category_id
WHERE t.transaction_type = 'expense'
GROUP BY c.category_name
HAVING SUM(t.amount) > (
  SELECT AVG(total_per_category)
  FROM (
    SELECT SUM(amount) AS total_per_category
    FROM transactions
    WHERE transaction_type = 'expense'
    GROUP BY category_id
  ) z
);
```

**Output:**

| category_name | category_total |
|---|---:|
| Rent | 18000.00 |
| Food | 9500.00 |

**How and Why:**
This identifies heavy categories using nested aggregation logic.

---

## 3.5 Complex Queries Based on Joins

### Question 1
Show complete transaction details with user and category names.

**SQL Statement:**
```sql
SELECT t.transaction_id, u.name AS user_name, c.category_name, t.amount, t.transaction_date
FROM transactions t
INNER JOIN users u ON t.user_id = u.user_id
INNER JOIN categories c ON t.category_id = c.category_id;
```

**Output:**

| transaction_id | user_name | category_name | amount | transaction_date |
|---:|---|---|---:|---|
| 101 | Rahul | Food | 550.00 | 2025-01-08 |

**How and Why:**
Joins normalize data across master and transaction tables while returning readable analytics output.

### Question 2
List all users and their budget info even if a budget is not present.

**SQL Statement:**
```sql
SELECT u.user_id, u.name, b.limit_amount, b.spent_amount
FROM users u
LEFT JOIN budgets b ON u.user_id = b.user_id;
```

**Output:**

| user_id | name | limit_amount | spent_amount |
|---:|---|---:|---:|
| 1 | Rahul | 30000.00 | 22000.00 |
| 3 | Asha | NULL | NULL |

**How and Why:**
`LEFT JOIN` keeps all users in output; useful for coverage reports and onboarding gaps.

### Question 3
Show category-wise expense totals only where categories are used.

**SQL Statement:**
```sql
SELECT c.category_name, SUM(t.amount) AS total_expense
FROM categories c
JOIN transactions t ON c.category_id = t.category_id
WHERE t.transaction_type = 'expense'
GROUP BY c.category_name;
```

**Output:**

| category_name | total_expense |
|---|---:|
| Food | 9500.00 |
| Rent | 18000.00 |

**How and Why:**
This join gives operational summaries for dashboards and category budgeting.

---

## 3.6 Complex Queries Based on Views

### Question 1
How do we create and query a monthly transaction analytics view?

**SQL Statement:**
```sql
CREATE VIEW transaction_analytics AS
SELECT
  t.user_id,
  t.transaction_type,
  c.category_name,
  COUNT(*) AS transaction_count,
  SUM(t.amount) AS total_amount,
  AVG(t.amount) AS average_amount,
  DATE_FORMAT(t.transaction_date, '%Y-%m') AS month_year
FROM transactions t
LEFT JOIN categories c ON t.category_id = c.category_id
GROUP BY t.user_id, t.transaction_type, c.category_name, DATE_FORMAT(t.transaction_date, '%Y-%m');

SELECT *
FROM transaction_analytics
WHERE user_id = 1;
```

**Output:**

| user_id | transaction_type | category_name | transaction_count | total_amount | average_amount | month_year |
|---:|---|---|---:|---:|---:|---|
| 1 | expense | Food | 5 | 3200.00 | 640.00 | 2025-01 |

**How and Why:**
A view encapsulates a complex query once and allows easy repeated reporting.

### Question 2
Query budget status using a prepared budget performance view.

**SQL Statement:**
```sql
SELECT budget_id, user_id, utilization_percentage, status
FROM budget_performance
WHERE status IN ('Near Limit', 'Over Budget');
```

**Output:**

| budget_id | user_id | utilization_percentage | status |
|---:|---:|---:|---|
| 3 | 1 | 94.20 | Near Limit |

**How and Why:**
Views provide instant business indicators without repeating CASE logic in every query.

### Question 3
Retrieve consolidated user financial summary from view.

**SQL Statement:**
```sql
SELECT user_id, name, total_income, total_expense, net_savings
FROM user_financial_summary
ORDER BY net_savings DESC;
```

**Output:**

| user_id | name | total_income | total_expense | net_savings |
|---:|---|---:|---:|---:|
| 1 | Rahul | 85000.00 | 32500.00 | 52500.00 |

**How and Why:**
The summary view supports fast dashboard loading and centralized business logic.

---

## 3.7 Complex Queries Based on Triggers

### Question 1
How do we auto-update budget spent amount after expense insert?

**SQL Statement:**
```sql
CREATE TRIGGER update_budget_spent_after_transaction
AFTER INSERT ON transactions
FOR EACH ROW
BEGIN
  IF NEW.transaction_type = 'expense' THEN
    UPDATE budgets
    SET spent_amount = spent_amount + NEW.amount
    WHERE user_id = NEW.user_id
      AND (category_id = NEW.category_id OR category_id IS NULL)
      AND period_month = MONTH(NEW.transaction_date)
      AND period_year = YEAR(NEW.transaction_date);
  END IF;
END;
```

**Output:**
```text
Query OK, Trigger created
```

**How and Why:**
Removes manual budget maintenance and guarantees real-time budget tracking.

### Question 2
How do we audit every transaction insert?

**SQL Statement:**
```sql
CREATE TRIGGER audit_transaction_insert
AFTER INSERT ON transactions
FOR EACH ROW
BEGIN
  INSERT INTO audit_log (user_id, table_name, record_id, action, new_values)
  VALUES (
    NEW.user_id,
    'transactions',
    NEW.transaction_id,
    'INSERT',
    JSON_OBJECT('amount', NEW.amount, 'type', NEW.transaction_type, 'date', NEW.transaction_date)
  );
END;
```

**Output:**
```text
Query OK, Trigger created
```

**How and Why:**
Provides traceability for compliance and debugging.

### Question 3
What is the effect of trigger after inserting an expense?

**SQL Statement:**
```sql
INSERT INTO transactions (user_id, account_id, category_id, transaction_type, amount, transaction_date)
VALUES (1, 1, 3, 'expense', 500.00, '2025-02-10');

SELECT budget_id, spent_amount
FROM budgets
WHERE user_id = 1
  AND period_month = 2
  AND period_year = 2025;
```

**Output:**

| budget_id | spent_amount |
|---:|---:|
| 8 | 12500.00 |

**How and Why:**
This validates that trigger logic executed automatically after DML.

---

## 3.8 Complex Queries Based on Cursors

### Question 1
How do we process each transaction row-by-row for monthly insights?

**SQL Statement:**
```sql
CALL calculate_monthly_insights(1, 2, 2025);
```

**Output:**
```text
Procedure executed successfully
```

**How and Why:**
Cursors are used when row-level iterative logic is needed for derived metrics and scoring.

### Question 2
How do we generate upcoming bill reminders using cursor-based procedure?

**SQL Statement:**
```sql
CALL generate_bill_reminders(1);
```

**Output:**

| bill_name | due_date | days_remaining | urgency |
|---|---|---:|---|
| Electricity Bill | 2025-02-15 | 3 | High |

**How and Why:**
The procedure scans upcoming bills and classifies urgency for proactive notifications.

### Question 3
How do we analyze spending patterns by category for last N months?

**SQL Statement:**
```sql
CALL analyze_spending_patterns(1, 6);
```

**Output:**

| category_name | total_spent | txn_count | avg_amount | spending_percent |
|---|---:|---:|---:|---:|
| Food | 9500.00 | 14 | 678.57 | 29.1 |
| Rent | 18000.00 | 6 | 3000.00 | 55.1 |

**How and Why:**
Cursor-based procedures are suitable for iterative analytics and custom summary generation.

---

## How It Was Done (Implementation Steps)

1. Reviewed schema objects (tables, views, triggers, procedures) already present in project SQL files.
2. Grouped queries by required chapter sub-topics (3.1 to 3.8).
3. For each topic, prepared **3 questions** with practical SQL statements.
4. Added output format examples so the chapter is submission-ready.
5. Added brief **How and Why** notes for viva/report explanation.

## Why This Structure Was Chosen

- Matches your exact chapter format.
- Covers all requested concepts in one standardized document.
- Makes checking and viva explanation simple (question → query → output → reason).
- Ensures minimum advanced coverage across all listed DBMS topics.
