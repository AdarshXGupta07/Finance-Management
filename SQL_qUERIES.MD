# SQL Queries Used (Constraints, Sets, Joins, Views, Triggers, Cursors, Aggregation)

This file lists representative SQL used in this project.

## 1) Constraints

```sql
ALTER TABLE users
ADD CONSTRAINT uq_users_email UNIQUE (email);
```

```sql
ALTER TABLE budgets
ADD CONSTRAINT chk_budget_limit CHECK (limit_amount > 0);
```

```sql
ALTER TABLE transactions
ADD CONSTRAINT fk_txn_user FOREIGN KEY (user_id)
REFERENCES users(user_id) ON DELETE CASCADE;
```

## 2) Sets / Set Logic

### SET data type
```sql
CREATE TABLE categories (
  category_id INT PRIMARY KEY AUTO_INCREMENT,
  category_name VARCHAR(100) NOT NULL,
  category_type ENUM('income','expense') NOT NULL,
  tags SET('essential','discretionary','investment','emergency','lifestyle')
);
```

### SQL set operator (UNION)
```sql
SELECT category_name FROM categories WHERE category_type = 'income'
UNION
SELECT category_name FROM categories WHERE category_type = 'expense';
```

## 3) Joins

```sql
SELECT t.transaction_id, t.amount, c.category_name, u.name
FROM transactions t
INNER JOIN categories c ON t.category_id = c.category_id
INNER JOIN users u ON t.user_id = u.user_id;
```

```sql
SELECT u.user_id, u.name, COALESCE(SUM(t.amount), 0) AS total_expense
FROM users u
LEFT JOIN transactions t
  ON u.user_id = t.user_id AND t.transaction_type = 'expense'
GROUP BY u.user_id, u.name;
```

## 4) Views

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
```

```sql
SELECT * FROM transaction_analytics WHERE user_id = 1;
```

## 5) Triggers

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

## 6) Cursors (Stored Procedure)

```sql
CREATE PROCEDURE calculate_monthly_insights(IN p_user_id INT, IN p_month INT, IN p_year INT)
BEGIN
  DECLARE done INT DEFAULT FALSE;
  DECLARE v_type VARCHAR(10);
  DECLARE v_amount DECIMAL(12,2);

  DECLARE cur_txn CURSOR FOR
    SELECT transaction_type, amount
    FROM transactions
    WHERE user_id = p_user_id
      AND MONTH(transaction_date) = p_month
      AND YEAR(transaction_date) = p_year;

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

  OPEN cur_txn;
  read_loop: LOOP
    FETCH cur_txn INTO v_type, v_amount;
    IF done THEN
      LEAVE read_loop;
    END IF;
  END LOOP;
  CLOSE cur_txn;
END;
```

## 7) Aggregation

```sql
SELECT
  user_id,
  SUM(CASE WHEN transaction_type = 'income' THEN amount ELSE 0 END) AS total_income,
  SUM(CASE WHEN transaction_type = 'expense' THEN amount ELSE 0 END) AS total_expense,
  AVG(amount) AS avg_transaction,
  COUNT(*) AS total_transactions,
  MAX(amount) AS highest_transaction
FROM transactions
GROUP BY user_id;
```

## Minimum 3 advanced features satisfied

At least these three are fully implemented and documented:
1. Joins
2. Views
3. Triggers

Additional implemented features: Constraints, Sets, Cursors, Aggregation.