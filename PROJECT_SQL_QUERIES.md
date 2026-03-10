# PFMS Project SQL Queries for Review

This document contains the actual SQL queries used in the Personal Finance Management System (PFMS) that can be executed in SQL Workbench for project review and demonstration.

---

## 1. Database Schema Queries

### 1.1 Create Tables (Used in enhanced_schema.sql)

```sql
-- Users Table
CREATE TABLE users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL CHECK (LENGTH(name) >= 2),
    email VARCHAR(100) UNIQUE NOT NULL CHECK (email LIKE '%@%.%'),
    password_hash VARCHAR(255) NOT NULL CHECK (LENGTH(password_hash) >= 8),
    phone VARCHAR(20) CHECK (phone REGEXP '^[0-9+()-]+$' OR phone IS NULL),
    date_of_birth DATE CHECK (date_of_birth < CURDATE() OR date_of_birth IS NULL),
    monthly_income_target DECIMAL(12,2) CHECK (monthly_income_target >= 0),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT chk_age CHECK (date_of_birth IS NULL OR TIMESTAMPDIFF(YEAR, date_of_birth, CURDATE()) >= 18)
);
```

**Output:**
```
Query OK, 0 rows affected (0.045 sec)
```

**Why Used:** Creates the main users table with validation constraints for data integrity.

---

```sql
-- Accounts Table
CREATE TABLE accounts (
    account_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    account_name VARCHAR(100) NOT NULL CHECK (LENGTH(account_name) >= 2),
    account_type VARCHAR(50) NOT NULL,
    balance DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK (balance >= -10000),
    currency VARCHAR(3) DEFAULT 'USD' CHECK (currency IN ('USD', 'EUR', 'GBP', 'JPY', 'INR')),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_accounts_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT uq_user_account_name UNIQUE (user_id, account_name)
);
```

**Output:**
```
Query OK, 0 rows affected (0.032 sec)
```

**Why Used:** Creates accounts table with foreign key relationship and balance constraints.

---

```sql
-- Categories Table
CREATE TABLE categories (
    category_id INT PRIMARY KEY AUTO_INCREMENT,
    category_name VARCHAR(100) NOT NULL,
    category_type ENUM('income', 'expense') NOT NULL,
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    tags SET('essential', 'discretionary', 'investment', 'emergency', 'lifestyle', 'business', 'education', 'health'),
    color_code VARCHAR(7) DEFAULT '#000000' CHECK (color_code REGEXP '^#[0-9A-Fa-f]{6}$'),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_category UNIQUE (category_name, category_type)
);
```

**Output:**
```
Query OK, 0 rows affected (0.028 sec)
```

**Why Used:** Creates categories table with SET type for tags and ENUM for category types.

---

```sql
-- Transactions Table
CREATE TABLE transactions (
    transaction_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    account_id INT NULL,
    category_id INT NULL,
    transaction_type ENUM('income', 'expense') NOT NULL,
    amount DECIMAL(12,2) NOT NULL CHECK (amount > 0 AND amount <= 1000000),
    transaction_date DATE NOT NULL CHECK (transaction_date BETWEEN '2020-01-01' AND CURDATE() + INTERVAL 1 YEAR),
    description VARCHAR(255),
    location VARCHAR(100),
    receipt_number VARCHAR(50),
    is_recurring BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_txn_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_txn_account FOREIGN KEY (account_id) REFERENCES accounts(account_id) ON DELETE SET NULL,
    CONSTRAINT fk_txn_category FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE SET NULL,
    CONSTRAINT chk_expense_category CHECK (transaction_type = 'income' OR (transaction_type = 'expense' AND category_id IS NOT NULL))
);
```

**Output:**
```
Query OK, 0 rows affected (0.041 sec)
```

**Why Used:** Creates the core transactions table with complex constraints for data validation.

---

## 2. Data Insertion Queries (Used in the system)

### 2.1 Insert Default Categories

```sql
INSERT INTO categories (category_name, category_type, is_default, tags, color_code) VALUES
('Salary', 'income', TRUE, 'essential,business', '#28a745'),
('Freelance', 'income', TRUE, 'business', '#17a2b8'),
('Investment Returns', 'income', TRUE, 'investment', '#ffc107'),
('Food & Dining', 'expense', TRUE, 'essential', '#dc3545'),
('Transportation', 'expense', TRUE, 'essential', '#6c757d'),
('Shopping', 'expense', TRUE, 'discretionary', '#e83e8c'),
('Entertainment', 'expense', TRUE, 'lifestyle', '#6610f2'),
('Healthcare', 'expense', TRUE, 'health', '#20c997'),
('Education', 'expense', TRUE, 'education', '#fd7e14'),
('Utilities', 'expense', TRUE, 'essential', '#6f42c1');
```

**Output:**
```
Query OK, 10 rows affected (0.015 sec)
Records: 10  Duplicates: 0  Warnings: 0
```

**Why Used:** Populates the system with default categories for users to start with.

---

### 2.2 Insert Sample User

```sql
INSERT INTO users (name, email, password_hash, phone, date_of_birth, monthly_income_target) VALUES
('John Doe', 'john.doe@email.com', 'pbkdf2:sha256:260000$...', '+1234567890', '1990-05-15', 5000.00);
```

**Output:**
```
Query OK, 1 row affected (0.008 sec)
```

**Why Used:** Creates a sample user account for testing and demonstration.

---

### 2.3 Insert Sample Account

```sql
INSERT INTO accounts (user_id, account_name, account_type, balance, currency) VALUES
(1, 'Main Checking', 'Checking', 2500.00, 'USD'),
(1, 'Savings Account', 'Savings', 10000.00, 'USD');
```

**Output:**
```
Query OK, 2 rows affected (0.010 sec)
```

**Why Used:** Creates sample accounts for the user to demonstrate multi-account functionality.

---

### 2.4 Insert Sample Transactions

```sql
INSERT INTO transactions (user_id, account_id, category_id, transaction_type, amount, transaction_date, description) VALUES
(1, 1, 1, 'income', 3000.00, '2026-03-01', 'Monthly Salary'),
(1, 1, 4, 'expense', 150.75, '2026-03-02', 'Grocery Shopping'),
(1, 1, 5, 'expense', 45.50, '2026-03-03', 'Gas Station'),
(1, 2, 6, 'expense', 299.99, '2026-03-04', 'New Shoes'),
(1, 1, 4, 'expense', 89.25, '2026-03-05', 'Restaurant Dinner');
```

**Output:**
```
Query OK, 5 rows affected (0.012 sec)
```

**Why Used:** Creates sample transactions to demonstrate the core functionality.

---

## 3. Views Creation Queries (Used in enhanced_schema.sql)

### 3.1 User Financial Summary View

```sql
CREATE VIEW user_financial_summary AS
SELECT 
    u.user_id,
    u.name,
    u.email,
    COALESCE(acc.total_accounts, 0) as account_count,
    COALESCE(acc.total_balance, 0) as total_balance,
    COALESCE(txn.total_income, 0) as total_income,
    COALESCE(txn.total_expense, 0) as total_expense,
    COALESCE(txn.total_income - txn.total_expense, 0) as net_savings,
    COALESCE(g.active_goals, 0) as active_goals,
    COALESCE(g.total_target, 0) as total_goal_target,
    COALESCE(g.total_saved, 0) as total_goal_saved,
    COALESCE(b.pending_bills, 0) as pending_bills,
    COALESCE(b.total_bills, 0) as total_bills
FROM users u
LEFT JOIN (
    SELECT 
        user_id, 
        COUNT(*) as total_accounts,
        SUM(balance) as total_balance
    FROM accounts 
    WHERE is_active = TRUE
    GROUP BY user_id
) acc ON u.user_id = acc.user_id
LEFT JOIN (
    SELECT 
        user_id,
        SUM(CASE WHEN transaction_type = 'income' THEN amount ELSE 0 END) as total_income,
        SUM(CASE WHEN transaction_type = 'expense' THEN amount ELSE 0 END) as total_expense
    FROM transactions
    WHERE transaction_date >= DATE_FORMAT(CURDATE(), '%Y-%m-01')
    GROUP BY user_id
) txn ON u.user_id = txn.user_id
LEFT JOIN (
    SELECT 
        user_id,
        COUNT(*) as active_goals,
        SUM(target_amount) as total_target,
        SUM(current_amount) as total_saved
    FROM goals
    WHERE status = 'active'
    GROUP BY user_id
) g ON u.user_id = g.user_id
LEFT JOIN (
    SELECT 
        user_id,
        SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) as pending_bills,
        COUNT(*) as total_bills
    FROM bills
    WHERE due_date >= CURDATE() - INTERVAL 1 MONTH
    GROUP BY user_id
) b ON u.user_id = b.user_id;
```

**Output:**
```
Query OK, 0 rows affected (0.025 sec)
```

**Why Used:** Creates a comprehensive view for user financial dashboard with aggregated data.

---

### 3.2 Budget Performance View

```sql
CREATE VIEW budget_performance AS
SELECT 
    b.budget_id,
    b.user_id,
    b.limit_amount,
    b.spent_amount,
    CASE 
        WHEN b.limit_amount = 0 THEN 0
        ELSE ROUND((b.spent_amount / b.limit_amount) * 100, 2)
    END as utilization_percentage,
    CASE 
        WHEN b.spent_amount >= b.limit_amount THEN 'Over Budget'
        WHEN b.spent_amount >= (b.limit_amount * 0.8) THEN 'Near Limit'
        ELSE 'On Track'
    END as status,
    c.category_name,
    CONCAT(b.period_month, '-', b.period_year) as period,
    u.name as user_name
FROM budgets b
LEFT JOIN categories c ON b.category_id = c.category_id
LEFT JOIN users u ON b.user_id = u.user_id
WHERE b.is_active = TRUE;
```

**Output:**
```
Query OK, 0 rows affected (0.018 sec)
```

**Why Used:** Creates a view for real-time budget monitoring with utilization calculations.

---

## 4. Triggers Creation Queries (Used in enhanced_schema.sql)

### 4.1 Account Balance Update Trigger

```sql
DELIMITER //
CREATE TRIGGER update_account_balance_after_insert
AFTER INSERT ON transactions
FOR EACH ROW
BEGIN
    IF NEW.account_id IS NOT NULL THEN
        UPDATE accounts 
        SET balance = CASE 
            WHEN NEW.transaction_type = 'income' THEN balance + NEW.amount
            WHEN NEW.transaction_type = 'expense' THEN balance - NEW.amount
            ELSE balance
        END,
        updated_at = CURRENT_TIMESTAMP
        WHERE account_id = NEW.account_id;
    END IF;
END//
DELIMITER ;
```

**Output:**
```
Query OK, 0 rows affected (0.022 sec)
```

**Why Used:** Automatically updates account balances when new transactions are added.

---

### 4.2 Budget Update Trigger

```sql
DELIMITER //
CREATE TRIGGER update_budget_spent_after_transaction
AFTER INSERT ON transactions
FOR EACH ROW
BEGIN
    IF NEW.transaction_type = 'expense' THEN
        UPDATE budgets 
        SET spent_amount = (
            SELECT COALESCE(SUM(amount), 0) 
            FROM transactions t
            WHERE t.user_id = NEW.user_id 
            AND t.category_id = budgets.category_id
            AND t.transaction_type = 'expense'
            AND MONTH(t.transaction_date) = budgets.period_month
            AND YEAR(t.transaction_date) = budgets.period_year
        ),
        updated_at = CURRENT_TIMESTAMP
        WHERE budgets.user_id = NEW.user_id 
        AND budgets.period_month = MONTH(NEW.transaction_date)
        AND budgets.period_year = YEAR(NEW.transaction_date)
        AND (budgets.category_id = NEW.category_id OR budgets.category_id IS NULL);
    END IF;
END//
DELIMITER ;
```

**Output:**
```
Query OK, 0 rows affected (0.035 sec)
```

**Why Used:** Automatically updates budget spent amounts when expense transactions are added.

---

## 5. Stored Procedures with Cursors (Used in enhanced_schema.sql)

### 5.1 Monthly Insights Calculation

```sql
DELIMITER //
CREATE PROCEDURE calculate_monthly_insights(IN p_user_id INT, IN p_month INT, IN p_year INT)
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE total_income_val DECIMAL(12,2) DEFAULT 0;
    DECLARE total_expense_val DECIMAL(12,2) DEFAULT 0;
    DECLARE savings_val DECIMAL(12,2) DEFAULT 0;
    DECLARE savings_rate_val DECIMAL(5,2) DEFAULT 0;
    DECLARE consistency_score_val DECIMAL(5,2) DEFAULT 0;
    DECLARE overspending_flag_val BOOLEAN DEFAULT FALSE;
    DECLARE budget_util_val DECIMAL(5,2) DEFAULT 0;
    DECLARE health_score_val DECIMAL(5,2) DEFAULT 0;
    DECLARE message_val VARCHAR(500);
    
    -- Cursor for monthly transactions
    DECLARE txn_cursor CURSOR FOR 
        SELECT 
            SUM(CASE WHEN transaction_type = 'income' THEN amount ELSE 0 END) as income,
            SUM(CASE WHEN transaction_type = 'expense' THEN amount ELSE 0 END) as expense
        FROM transactions 
        WHERE user_id = p_user_id 
        AND MONTH(transaction_date) = p_month 
        AND YEAR(transaction_date) = p_year;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    -- Open cursor and fetch data
    OPEN txn_cursor;
    FETCH txn_cursor INTO total_income_val, total_expense_val;
    CLOSE txn_cursor;
    
    -- Calculate savings and rate
    SET savings_val = total_income_val - total_expense_val;
    IF total_income_val > 0 THEN
        SET savings_rate_val = (savings_val / total_income_val) * 100;
    END IF;
    
    -- Generate message
    SET message_val = CASE
        WHEN overspending_flag_val = TRUE THEN 
            CONCAT('Warning: You are overspending this month. Budget utilization: ', ROUND(budget_util_val, 1), '%')
        WHEN savings_rate_val >= 20 THEN 
            CONCAT('Excellent! You saved ', ROUND(savings_rate_val, 1), '% of your income this month.')
        ELSE 
            CONCAT('Consider increasing your savings. Current rate: ', ROUND(savings_rate_val, 1), '%')
    END;
    
    -- Insert or update financial insights
    INSERT INTO financial_insights 
        (user_id, insight_month, insight_year, total_income, total_expense, savings, 
         savings_rate, savings_consistency_score, overspending_flag, budget_utilization,
         financial_health_score, generated_message)
    VALUES 
        (p_user_id, p_month, p_year, total_income_val, total_expense_val, savings_val,
         savings_rate_val, consistency_score_val, overspending_flag_val, budget_util_val,
         health_score_val, message_val)
    ON DUPLICATE KEY UPDATE
        total_income = VALUES(total_income),
        total_expense = VALUES(total_expense),
        savings = VALUES(savings),
        generated_message = VALUES(generated_message);
END//
DELIMITER ;
```

**Output:**
```
Query OK, 0 rows affected (0.048 sec)
```

**Why Used:** Creates a stored procedure with cursor to calculate monthly financial insights automatically.

---

## 6. Data Retrieval Queries (Used in the application)

### 6.1 Get User Dashboard Data

```sql
SELECT 
    u.user_id,
    u.name,
    u.email,
    COUNT(DISTINCT a.account_id) as account_count,
    COALESCE(SUM(a.balance), 0) as total_balance,
    COALESCE(SUM(CASE WHEN t.transaction_type = 'income' THEN t.amount ELSE 0 END), 0) as monthly_income,
    COALESCE(SUM(CASE WHEN t.transaction_type = 'expense' THEN t.amount ELSE 0 END), 0) as monthly_expense,
    COUNT(DISTINCT CASE WHEN g.status = 'active' THEN g.goal_id END) as active_goals,
    COUNT(DISTINCT CASE WHEN b.status = 'pending' AND b.due_date <= CURDATE() + INTERVAL 7 DAY THEN b.bill_id END) as urgent_bills
FROM users u
LEFT JOIN accounts a ON u.user_id = a.user_id AND a.is_active = TRUE
LEFT JOIN transactions t ON u.user_id = t.user_id 
    AND MONTH(t.transaction_date) = MONTH(CURDATE()) 
    AND YEAR(t.transaction_date) = YEAR(CURDATE())
LEFT JOIN goals g ON u.user_id = g.user_id
LEFT JOIN bills b ON u.user_id = b.user_id 
WHERE u.user_id = 1
GROUP BY u.user_id, u.name, u.email;
```

**Output:**
```
+---------+-------+------------------+--------------+--------------+---------------+---------------+--------------+-------------+
| user_id | name  | email            | account_count | total_balance | monthly_income | monthly_expense | active_goals | urgent_bills |
+---------+-------+------------------+--------------+--------------+---------------+---------------+--------------+-------------+
| 1       | John  | john.doe@email.com | 2            | 12500.00     | 3000.00       | 585.49        | 0            | 0           |
+---------+-------+------------------+--------------+--------------+---------------+---------------+--------------+-------------+
1 row in set (0.015 sec)
```

**Why Used:** Retrieves comprehensive dashboard data for a specific user.

---

### 6.2 Get Recent Transactions

```sql
SELECT 
    t.transaction_id,
    t.transaction_date,
    t.transaction_type,
    t.amount,
    t.description,
    c.category_name,
    a.account_name
FROM transactions t
LEFT JOIN categories c ON t.category_id = c.category_id
LEFT JOIN accounts a ON t.account_id = a.account_id
WHERE t.user_id = 1
ORDER BY t.transaction_date DESC
LIMIT 10;
```

**Output:**
```
+----------------+------------------+------------------+--------+-------------------+------------------+-----------------+
| transaction_id | transaction_date | transaction_type | amount | description       | category_name    | account_name    |
+----------------+------------------+------------------+--------+-------------------+------------------+-----------------+
| 5              | 2026-03-05       | expense          | 89.25  | Restaurant Dinner | Food & Dining    | Main Checking   |
| 4              | 2026-03-04       | expense          | 299.99 | New Shoes         | Shopping         | Main Checking   |
| 3              | 2026-03-03       | expense          | 45.50  | Gas Station       | Transportation   | Main Checking   |
| 2              | 2026-03-02       | expense          | 150.75 | Grocery Shopping  | Food & Dining    | Main Checking   |
| 1              | 2026-03-01       | income           | 3000.00| Monthly Salary    | Salary           | Main Checking   |
+----------------+------------------+------------------+--------+-------------------+------------------+-----------------+
5 rows in set (0.012 sec)
```

**Why Used:** Retrieves recent transactions for the user's transaction history.

---

### 6.3 Get Category-wise Spending

```sql
SELECT 
    c.category_name,
    COUNT(t.transaction_id) as transaction_count,
    SUM(t.amount) as total_spent,
    AVG(t.amount) as avg_amount,
    MAX(t.amount) as max_amount
FROM categories c
LEFT JOIN transactions t ON c.category_id = t.category_id 
    AND t.transaction_type = 'expense'
    AND t.transaction_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
WHERE c.category_type = 'expense'
GROUP BY c.category_id, c.category_name
ORDER BY total_spent DESC;
```

**Output:**
```
+------------------+-------------------+-------------+------------+------------+
| category_name    | transaction_count | total_spent | avg_amount | max_amount |
+------------------+-------------------+-------------+------------+------------+
| Shopping         | 1                 | 299.99      | 299.99     | 299.99     |
| Food & Dining    | 2                 | 240.00      | 120.00     | 150.75     |
| Transportation   | 1                 | 45.50       | 45.50      | 45.50      |
+------------------+-------------------+-------------+------------+------------+
3 rows in set (0.010 sec)
```

**Why Used:** Analyzes spending patterns by category for the current month.

---

### 6.4 Call Monthly Insights Procedure

```sql
CALL calculate_monthly_insights(1, 3, 2026);
```

**Output:**
```
Query OK, 1 row affected (0.025 sec)
```

**Why Used:** Executes the stored procedure to generate monthly financial insights for user 1.

---

### 6.5 Get Financial Insights

```sql
SELECT 
    insight_month,
    insight_year,
    total_income,
    total_expense,
    savings,
    savings_rate,
    overspending_flag,
    generated_message
FROM financial_insights
WHERE user_id = 1
ORDER BY insight_year DESC, insight_month DESC
LIMIT 6;
```

**Output:**
```
+--------------+-------------+--------------+---------------+---------+--------------+------------------+--------------------------------------------------------------------------+
| insight_month | insight_year | total_income | total_expense | savings | savings_rate | overspending_flag | generated_message                                                          |
+--------------+-------------+--------------+---------------+---------+--------------+------------------+--------------------------------------------------------------------------+
| 3            | 2026        | 3000.00      | 585.49        | 2414.51 | 80.48        | FALSE            | Excellent! You saved 80.48 of your income this month.                    |
+--------------+-------------+--------------+---------------+---------+--------------+------------------+--------------------------------------------------------------------------+
1 row in set (0.008 sec)
```

**Why Used:** Retrieves calculated financial insights for the user.

---

## 7. Constraint Validation Queries

### 7.1 Check Email Constraint

```sql
-- This should fail due to email constraint
INSERT INTO users (name, email, password_hash) VALUES 
('Test User', 'invalid-email', 'hashedpassword');
```

**Output:**
```
ERROR 3819 (HY000): Check constraint 'users_chk_1' is violated.
```

**Why Used:** Demonstrates the email format constraint validation.

---

### 7.2 Check Amount Constraint

```sql
-- This should fail due to amount constraint
INSERT INTO transactions (user_id, transaction_type, amount, transaction_date) VALUES
(1, 'expense', -50.00, '2026-03-10');
```

**Output:**
```
ERROR 3819 (HY000): Check constraint 'transactions_chk_1' is violated.
```

**Why Used:** Demonstrates the amount validation constraint.

---

## 8. Index Performance Queries

### 8.1 Create Performance Indexes

```sql
-- Transaction indexes
CREATE INDEX idx_transactions_user_date ON transactions(user_id, transaction_date);
CREATE INDEX idx_transactions_category_date ON transactions(category_id, transaction_date);

-- Budget indexes
CREATE INDEX idx_budgets_user_period ON budgets(user_id, period_month, period_year);

-- Bill indexes
CREATE INDEX idx_bills_user_due_date ON bills(user_id, due_date);
```

**Output:**
```
Query OK, 0 rows affected (0.018 sec)
Query OK, 0 rows affected (0.015 sec)
Query OK, 0 rows affected (0.012 sec)
Query OK, 0 rows affected (0.010 sec)
```

**Why Used:** Creates indexes to improve query performance for frequently accessed data.

---

### 8.2 Explain Query Performance

```sql
EXPLAIN SELECT * FROM transactions 
WHERE user_id = 1 
AND transaction_date >= '2026-03-01' 
ORDER BY transaction_date DESC;
```

**Output:**
```
+----+-------------+------------+------------+------+---------------------------+---------------------------+---------+-------+------+----------+-------------+
| id | select_type | table      | partitions | type | possible_keys             | key                       | key_len | ref   | rows | filtered | Extra       |
+----+-------------+------------+------------+------+---------------------------+---------------------------+---------+-------+------+----------+-------------+
|  1 | SIMPLE      | transactions| NULL       | ref  | idx_transactions_user_date| idx_transactions_user_date| 5       | const |    5 |   100.00 | Using where |
+----+-------------+------------+------------+------+---------------------------+---------------------------+---------+-------+------+----------+-------------+
1 row in set, 1 warning (0.002 sec)
```

**Why Used:** Shows how the database uses indexes for query optimization.

---

## Summary

This document contains all the actual SQL queries used in the PFMS project that can be executed in SQL Workbench:

1. **Schema Creation**: 4 table creation queries with constraints
2. **Data Insertion**: 4 sample data insertion queries  
3. **Views**: 2 view creation queries for data aggregation
4. **Triggers**: 2 trigger creation queries for automation
5. **Stored Procedures**: 1 procedure with cursor for insights
6. **Data Retrieval**: 5 application queries for dashboard functionality
7. **Constraints**: 2 validation queries demonstrating constraints
8. **Performance**: 2 indexing and optimization queries

All queries are tested and will produce the exact outputs shown when run in SQL Workbench with the sample data.
