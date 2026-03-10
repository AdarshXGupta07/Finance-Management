# CHAPTER 3 — Complex SQL Queries (PFMS)

Database used: `pfms_db` from `database/schema.sql` and `database/sample_data.sql`.

## 3.1 Adding Constraints and Queries Based on Constraints

### Question 1
How do we enforce positive transaction amounts?

**SQL Statement:**
```sql
ALTER TABLE transactions
ADD CONSTRAINT chk_txn_amount_positive CHECK (amount > 0);
```

**Output:**
Constraint created successfully.

### Question 2
How do we enforce valid budget month range?

**SQL Statement:**
```sql
ALTER TABLE budgets
ADD CONSTRAINT chk_budget_month CHECK (period_month BETWEEN 1 AND 12);
```

**Output:**
Constraint created successfully.

### Question 3
How do we verify constraints by attempting invalid data?

**SQL Statement:**
```sql
INSERT INTO transactions (user_id, transaction_type, amount, transaction_date)
VALUES (1, 'expense', -500, '2026-01-12');
```

**Output:**
```text
ERROR 3819 (HY000): Check constraint 'chk_txn_amount_positive' is violated.
```

## 3.2 Queries Based on Aggregate Functions

### Question 1
What is total income and expense for each user?

**SQL Statement:**
```sql
SELECT user_id,
       SUM(CASE WHEN transaction_type='income' THEN amount ELSE 0 END) AS total_income,
       SUM(CASE WHEN transaction_type='expense' THEN amount ELSE 0 END) AS total_expense
FROM transactions
GROUP BY user_id;
```

**Output:**
| user_id | total_income | total_expense |
|---|---:|---:|
| 1 | 95000.00 | 5750.00 |

### Question 2
What is average transaction amount by type?

**SQL Statement:**
```sql
SELECT transaction_type, AVG(amount) AS avg_amount
FROM transactions
GROUP BY transaction_type;
```

**Output:**
| transaction_type | avg_amount |
|---|---:|
| income | 47500.00 |
| expense | 1437.50 |

### Question 3
How many pending bills and total due amount per user?

**SQL Statement:**
```sql
SELECT user_id, COUNT(*) AS pending_bills, SUM(amount) AS total_due
FROM bills
WHERE status='pending'
GROUP BY user_id;
```

**Output:**
| user_id | pending_bills | total_due |
|---|---:|---:|
| 1 | 2 | 9499.00 |

## 3.3 Complex Queries Based on Sets

### Question 1
Which categories are used in transactions (INTERSECT-style using JOIN)?

**SQL Statement:**
```sql
SELECT DISTINCT c.category_name
FROM categories c
JOIN transactions t ON c.category_id = t.category_id;
```

**Output:**
Salary, Freelance, Food, Transport, Utilities, Entertainment

### Question 2
Which categories are not yet used (SET DIFFERENCE)?

**SQL Statement:**
```sql
SELECT c.category_name
FROM categories c
LEFT JOIN transactions t ON c.category_id = t.category_id
WHERE t.transaction_id IS NULL;
```

**Output:**
No rows in current sample data.

### Question 3
Combine account names and bill names in one list (UNION)

**SQL Statement:**
```sql
SELECT account_name AS item_name, 'ACCOUNT' AS source FROM accounts
UNION
SELECT bill_name AS item_name, 'BILL' AS source FROM bills;
```

**Output:**
HDFC Savings, Cash Wallet, Internet Bill, Credit Card

## 3.4 Complex Queries Based on Subqueries

### Question 1
Find transactions above user average transaction amount.

**SQL Statement:**
```sql
SELECT transaction_id, amount
FROM transactions
WHERE amount > (
  SELECT AVG(amount) FROM transactions WHERE user_id = 1
)
AND user_id = 1;
```

**Output:**
transaction_id 1, 2

### Question 2
Find top expense category for user.

**SQL Statement:**
```sql
SELECT c.category_name, SUM(t.amount) AS total
FROM transactions t
JOIN categories c ON t.category_id = c.category_id
WHERE t.user_id = 1 AND t.transaction_type='expense'
GROUP BY c.category_name
HAVING SUM(t.amount) = (
  SELECT MAX(total_amt)
  FROM (
    SELECT SUM(amount) AS total_amt
    FROM transactions
    WHERE user_id=1 AND transaction_type='expense'
    GROUP BY category_id
  ) x
);
```

**Output:**
Utilities, 3000.00

### Question 3
List users with budgets above overall average budget.

**SQL Statement:**
```sql
SELECT DISTINCT user_id
FROM budgets
WHERE limit_amount > (SELECT AVG(limit_amount) FROM budgets);
```

**Output:**
user_id = 1

## 3.5 Complex Queries Based on Joins

### Question 1
Show transaction with account and category names.

**SQL Statement:**
```sql
SELECT t.transaction_id, t.amount, a.account_name, c.category_name
FROM transactions t
LEFT JOIN accounts a ON t.account_id = a.account_id
LEFT JOIN categories c ON t.category_id = c.category_id
WHERE t.user_id = 1;
```

**Output:**
6 joined rows with account/category labels.

### Question 2
Show user goal progress percentage.

**SQL Statement:**
```sql
SELECT u.name, g.goal_name,
       ROUND((g.current_amount / g.target_amount) * 100, 2) AS progress_percent
FROM users u
JOIN goals g ON u.user_id = g.user_id;
```

**Output:**
Emergency Fund 30.00%, Vacation Trip 25.00%

### Question 3
Show budget and spent amount by category.

**SQL Statement:**
```sql
SELECT b.budget_id, c.category_name, b.limit_amount,
       COALESCE(SUM(t.amount), 0) AS spent_amount
FROM budgets b
LEFT JOIN categories c ON b.category_id = c.category_id
LEFT JOIN transactions t ON t.category_id = b.category_id
  AND t.transaction_type='expense'
  AND MONTH(t.transaction_date)=b.period_month
  AND YEAR(t.transaction_date)=b.period_year
GROUP BY b.budget_id, c.category_name, b.limit_amount;
```

**Output:**
Budget-wise limit and spent values returned.

## 3.6 Complex Queries Based on Views

### Question 1
Create monthly financial summary view.

**SQL Statement:**
```sql
CREATE OR REPLACE VIEW vw_monthly_summary AS
SELECT user_id,
       YEAR(transaction_date) AS yr,
       MONTH(transaction_date) AS mon,
       SUM(CASE WHEN transaction_type='income' THEN amount ELSE 0 END) AS total_income,
       SUM(CASE WHEN transaction_type='expense' THEN amount ELSE 0 END) AS total_expense
FROM transactions
GROUP BY user_id, YEAR(transaction_date), MONTH(transaction_date);
```

**Output:**
View created.

### Question 2
Query savings from view.

**SQL Statement:**
```sql
SELECT user_id, yr, mon,
       total_income - total_expense AS savings
FROM vw_monthly_summary;
```

**Output:**
user_id 1, yr 2026, mon 1, savings 89250.00

### Question 3
Create and query overdue bill view.

**SQL Statement:**
```sql
CREATE OR REPLACE VIEW vw_overdue_bills AS
SELECT *
FROM bills
WHERE status='overdue' OR due_date < CURDATE();

SELECT bill_name, due_date, status FROM vw_overdue_bills;
```

**Output:**
Rows depending on current date/status.

## 3.7 Complex Queries Based on Triggers

### Question 1
Auto-update account balance on expense insert.

**SQL Statement:**
```sql
DELIMITER //
CREATE TRIGGER trg_after_expense_insert
AFTER INSERT ON transactions
FOR EACH ROW
BEGIN
  IF NEW.transaction_type = 'expense' AND NEW.account_id IS NOT NULL THEN
    UPDATE accounts SET balance = balance - NEW.amount
    WHERE account_id = NEW.account_id;
  END IF;
END //
DELIMITER ;
```

**Output:**
Trigger created.

### Question 2
Auto-update account balance on income insert.

**SQL Statement:**
```sql
DELIMITER //
CREATE TRIGGER trg_after_income_insert
AFTER INSERT ON transactions
FOR EACH ROW
BEGIN
  IF NEW.transaction_type = 'income' AND NEW.account_id IS NOT NULL THEN
    UPDATE accounts SET balance = balance + NEW.amount
    WHERE account_id = NEW.account_id;
  END IF;
END //
DELIMITER ;
```

**Output:**
Trigger created.

### Question 3
Audit deleted bills into a log table.

**SQL Statement:**
```sql
CREATE TABLE IF NOT EXISTS bill_delete_log (
  log_id INT PRIMARY KEY AUTO_INCREMENT,
  bill_id INT,
  deleted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DELIMITER //
CREATE TRIGGER trg_bill_delete
AFTER DELETE ON bills
FOR EACH ROW
BEGIN
  INSERT INTO bill_delete_log (bill_id) VALUES (OLD.bill_id);
END //
DELIMITER ;
```

**Output:**
Log table + trigger created.

## 3.8 Complex Queries Based on Cursors

### Question 1
Calculate total pending bill amount using cursor.

**SQL Statement:**
```sql
DELIMITER //
CREATE PROCEDURE sp_total_pending_bills(IN p_user_id INT, OUT p_total DECIMAL(12,2))
BEGIN
  DECLARE done INT DEFAULT 0;
  DECLARE v_amt DECIMAL(12,2);
  DECLARE cur CURSOR FOR
    SELECT amount FROM bills WHERE user_id = p_user_id AND status='pending';
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

  SET p_total = 0;
  OPEN cur;
  read_loop: LOOP
    FETCH cur INTO v_amt;
    IF done = 1 THEN LEAVE read_loop; END IF;
    SET p_total = p_total + v_amt;
  END LOOP;
  CLOSE cur;
END //
DELIMITER ;
```

**Output:**
Procedure created.

### Question 2
Mark overdue bills for a user via cursor iteration.

**SQL Statement:**
```sql
DELIMITER //
CREATE PROCEDURE sp_mark_overdue(IN p_user_id INT)
BEGIN
  DECLARE done INT DEFAULT 0;
  DECLARE v_bill_id INT;
  DECLARE cur CURSOR FOR
    SELECT bill_id FROM bills
    WHERE user_id = p_user_id AND status='pending' AND due_date < CURDATE();
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

  OPEN cur;
  loop_bills: LOOP
    FETCH cur INTO v_bill_id;
    IF done = 1 THEN LEAVE loop_bills; END IF;
    UPDATE bills SET status='overdue' WHERE bill_id=v_bill_id;
  END LOOP;
  CLOSE cur;
END //
DELIMITER ;
```

**Output:**
Procedure created and matching rows updated.

### Question 3
Generate per-category expense report text using cursor.

**SQL Statement:**
```sql
DELIMITER //
CREATE PROCEDURE sp_category_expense_report(IN p_user_id INT)
BEGIN
  DECLARE done INT DEFAULT 0;
  DECLARE v_cat VARCHAR(100);
  DECLARE v_amt DECIMAL(12,2);
  DECLARE cur CURSOR FOR
    SELECT c.category_name, SUM(t.amount)
    FROM transactions t
    JOIN categories c ON c.category_id=t.category_id
    WHERE t.user_id=p_user_id AND t.transaction_type='expense'
    GROUP BY c.category_name;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

  CREATE TEMPORARY TABLE IF NOT EXISTS tmp_report(line_text VARCHAR(255));
  DELETE FROM tmp_report;

  OPEN cur;
  report_loop: LOOP
    FETCH cur INTO v_cat, v_amt;
    IF done = 1 THEN LEAVE report_loop; END IF;
    INSERT INTO tmp_report VALUES (CONCAT(v_cat, ': ', v_amt));
  END LOOP;
  CLOSE cur;

  SELECT * FROM tmp_report;
END //
DELIMITER ;
```

**Output:**
Expense report rows by category.
