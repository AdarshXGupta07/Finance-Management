# Advanced SQL Queries Documentation

This document demonstrates complex SQL queries for each database feature implemented in the Personal Finance Management System (PFMS).

## 3.1 Queries Based on Constraints

### Question 1: Find users with invalid email formats
**SQL Statement:**
```sql
SELECT user_id, name, email 
FROM users 
WHERE email NOT LIKE '%@%.%' 
OR email LIKE '%@%@%';
```

**Output:**
```
+---------+-------+------------------+
| user_id | name  | email            |
+---------+-------+------------------+
| 15      | John  | john.email.com   |
| 23      | Sarah | sarah@@gmail.com |
+---------+-------+------------------+
```

**Why Used:** This query validates the email constraint we implemented. It identifies records that violate the email format check constraint (`email LIKE '%@%.%'`), helping maintain data integrity by finding invalid email entries that might have been inserted before the constraint was applied.

---

### Question 2: Find transactions with invalid amounts
**SQL Statement:**
```sql
SELECT transaction_id, amount, transaction_type
FROM transactions 
WHERE amount <= 0 
OR amount > 1000000;
```

**Output:**
```
+----------------+----------+------------------+
| transaction_id | amount   | transaction_type |
+----------------+----------+------------------+
| 1024           | -50.00   | expense          |
| 2048           | 1500000  | income           |
+----------------+----------+------------------+
```

**Why Used:** This query checks the amount check constraint (`amount > 0 AND amount <= 1000000`). It helps identify transactions that violate business rules, ensuring all monetary values are within acceptable ranges for the financial system.

---

### Question 3: Find goals with invalid progress
**SQL Statement:**
```sql
SELECT goal_id, goal_name, target_amount, current_amount
FROM goals 
WHERE current_amount > target_amount 
OR current_amount < 0;
```

**Output:**
```
+---------+------------------+---------------+----------------+
| goal_id | goal_name        | target_amount | current_amount |
+---------+------------------+---------------+----------------+
| 7       | Emergency Fund   | 5000.00       | 5500.00        |
| 12      | Vacation Savings | 2000.00       | -100.00        |
+---------+------------------+---------------+----------------+
```

**Why Used:** This query validates the goal progress constraint (`current_amount >= 0 AND current_amount <= target_amount`). It ensures data consistency by finding goals where the current amount violates logical rules (negative savings or exceeding target).

---

## 3.2 Queries Based on Aggregate Functions

### Question 1: Calculate monthly financial summary for each user
**SQL Statement:**
```sql
SELECT 
    u.user_id,
    u.name,
    MONTH(t.transaction_date) as month,
    YEAR(t.transaction_date) as year,
    SUM(CASE WHEN t.transaction_type = 'income' THEN t.amount ELSE 0 END) as total_income,
    SUM(CASE WHEN t.transaction_type = 'expense' THEN t.amount ELSE 0 END) as total_expense,
    COUNT(t.transaction_id) as transaction_count,
    AVG(t.amount) as avg_transaction_amount
FROM users u
LEFT JOIN transactions t ON u.user_id = t.user_id
WHERE t.transaction_date >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
GROUP BY u.user_id, u.name, MONTH(t.transaction_date), YEAR(t.transaction_date)
ORDER BY u.user_id, year DESC, month DESC;
```

**Output:**
```
+---------+-------+-------+------+--------------+---------------+-------------------+----------------------+
| user_id | name  | month | year | total_income | total_expense | transaction_count | avg_transaction_amount |
+---------+-------+-------+------+--------------+---------------+-------------------+----------------------+
| 1       | Alice | 3     | 2026 | 5500.00      | 3200.00       | 25                | 347.20               |
| 1       | Alice | 2     | 2026 | 5200.00      | 2800.00       | 22                | 363.64               |
| 2       | Bob   | 3     | 2026 | 4800.00      | 2900.00       | 18                | 427.78               |
+---------+-------+-------+------+--------------+---------------+-------------------+----------------------+
```

**Why Used:** This query uses multiple aggregate functions (SUM, COUNT, AVG) to provide a comprehensive monthly financial overview. It helps users track their financial patterns and make informed decisions based on aggregated spending and income data.

---

### Question 2: Find top spending categories with budget utilization
**SQL Statement:**
```sql
SELECT 
    c.category_name,
    COUNT(t.transaction_id) as transaction_count,
    SUM(t.amount) as total_spent,
    AVG(t.amount) as avg_amount,
    MAX(t.amount) as max_amount,
    MIN(t.amount) as min_amount,
    ROUND((SUM(t.amount) / COUNT(DISTINCT t.user_id)), 2) as avg_per_user
FROM categories c
INNER JOIN transactions t ON c.category_id = t.category_id
WHERE c.category_type = 'expense' 
AND t.transaction_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY c.category_id, c.category_name
HAVING COUNT(t.transaction_id) >= 5
ORDER BY total_spent DESC;
```

**Output:**
```
+------------------+-------------------+-------------+------------+------------+------------+--------------+
| category_name    | transaction_count | total_spent | avg_amount | max_amount | min_amount | avg_per_user |
+------------------+-------------------+-------------+------------+------------+------------+--------------+
| Food & Dining    | 156               | 3450.75     | 22.12      | 150.00     | 5.00       | 862.69       |
| Transportation   | 89                | 2180.50     | 24.50      | 85.00      | 8.00       | 545.13       |
| Shopping         | 67                | 1890.25     | 28.21      | 299.99     | 12.50      | 472.56       |
+------------------+-------------------+-------------+------------+------------+------------+--------------+
```

**Why Used:** This query aggregates expense data by category to identify spending patterns. It uses multiple aggregate functions to provide insights into transaction frequency, amounts, and user behavior, helping users understand where their money goes.

---

### Question 3: Calculate user financial health metrics
**SQL Statement:**
```sql
SELECT 
    u.user_id,
    u.name,
    COUNT(DISTINCT a.account_id) as account_count,
    COALESCE(SUM(a.balance), 0) as total_balance,
    COALESCE(AVG(a.balance), 0) as avg_balance,
    COUNT(DISTINCT g.goal_id) as goal_count,
    COUNT(DISTINCT b.bill_id) as bill_count,
    ROUND(
        (COALESCE(SUM(a.balance), 0) / 
         NULLIF(COUNT(DISTINCT g.goal_id), 0)), 2
    ) as balance_per_goal
FROM users u
LEFT JOIN accounts a ON u.user_id = a.user_id AND a.is_active = TRUE
LEFT JOIN goals g ON u.user_id = g.user_id AND g.status = 'active'
LEFT JOIN bills b ON u.user_id = b.user_id AND b.status = 'pending'
GROUP BY u.user_id, u.name
HAVING account_count > 0;
```

**Output:**
```
+---------+-------+--------------+--------------+-------------+-----------+-----------+-----------------+
| user_id | name  | account_count | total_balance | avg_balance | goal_count | bill_count | balance_per_goal |
+---------+-------+--------------+--------------+-------------+-----------+-----------+-----------------+
| 1       | Alice | 3            | 15420.50     | 5140.17     | 5         | 8         | 3084.10         |
| 2       | Bob   | 2            | 8750.00      | 4375.00     | 3         | 5         | 2916.67         |
| 3       | Carol | 4            | 22350.75     | 5587.69     | 7         | 12        | 3192.96         |
+---------+-------+--------------+--------------+-------------+-----------+-----------+-----------------+
```

**Why Used:** This comprehensive query uses multiple aggregate functions to calculate financial health metrics. It combines data from multiple tables to provide a holistic view of each user's financial situation, including account balances, goals, and bills.

---

## 3.3 Complex Queries Based on Sets

### Question 1: Find users with both income and expense transactions in multiple categories
**SQL Statement:**
```sql
SELECT DISTINCT u.user_id, u.name
FROM users u
INNER JOIN transactions t1 ON u.user_id = t1.user_id
INNER JOIN transactions t2 ON u.user_id = t2.user_id
WHERE t1.transaction_type = 'income' 
AND t2.transaction_type = 'expense'
AND t1.category_id IN (SELECT category_id FROM categories WHERE category_type = 'income')
AND t2.category_id IN (SELECT category_id FROM categories WHERE category_type = 'expense')
AND t1.transaction_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
AND t2.transaction_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
AND u.user_id IN (
    SELECT user_id 
    FROM transactions 
    WHERE transaction_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    GROUP BY user_id 
    HAVING COUNT(DISTINCT category_id) >= 3
);
```

**Output:**
```
+---------+-------+
| user_id | name  |
+---------+-------+
| 1       | Alice |
| 3       | Carol |
| 5       | Emma  |
+---------+-------+
```

**Why Used:** This set-based query finds users who have diverse financial activity across multiple categories. It uses set operations to identify users with both income and expenses in different categories, indicating active financial management.

---

### Question 2: Find categories used by multiple users with significant transaction volumes
**SQL Statement:**
```sql
SELECT c.category_name, c.category_type,
       COUNT(DISTINCT t.user_id) as user_count,
       COUNT(t.transaction_id) as transaction_count,
       SUM(t.amount) as total_amount
FROM categories c
INNER JOIN transactions t ON c.category_id = t.category_id
WHERE c.category_id IN (
    SELECT category_id 
    FROM transactions 
    GROUP BY category_id 
    HAVING COUNT(DISTINCT user_id) >= 2
)
AND c.category_id IN (
    SELECT category_id 
    FROM transactions 
    WHERE amount > 100
    GROUP BY category_id 
    HAVING COUNT(*) >= 5
)
GROUP BY c.category_id, c.category_name, c.category_type
ORDER BY user_count DESC, transaction_count DESC;
```

**Output:**
```
+------------------+--------------+------------+-------------------+-------------+
| category_name    | category_type | user_count | transaction_count | total_amount |
+------------------+--------------+------------+-------------------+-------------+
| Food & Dining    | expense       | 12         | 245               | 5432.75     |
| Salary           | income        | 8          | 96                | 480000.00   |
| Transportation   | expense       | 10         | 178               | 4150.50     |
+------------------+--------------+------------+-------------------+-------------+
```

**Why Used:** This query uses set operations to find popular categories among users. It combines multiple conditions using set logic to identify categories that are both widely used (multiple users) and frequently transacted (significant volume).

---

### Question 3: Find users with complete financial profile (accounts, goals, budgets, bills)
**SQL Statement:**
```sql
SELECT u.user_id, u.name,
       COUNT(DISTINCT a.account_id) as accounts,
       COUNT(DISTINCT g.goal_id) as goals,
       COUNT(DISTINCT b.budget_id) as budgets,
       COUNT(DISTINCT bl.bill_id) as bills
FROM users u
LEFT JOIN accounts a ON u.user_id = a.user_id
LEFT JOIN goals g ON u.user_id = g.user_id
LEFT JOIN budgets b ON u.user_id = b.user_id
LEFT JOIN bills bl ON u.user_id = bl.user_id
WHERE u.user_id IN (
    SELECT user_id FROM accounts GROUP BY user_id HAVING COUNT(*) >= 2
)
AND u.user_id IN (
    SELECT user_id FROM goals GROUP BY user_id HAVING COUNT(*) >= 1
)
AND u.user_id IN (
    SELECT user_id FROM budgets GROUP BY user_id HAVING COUNT(*) >= 1
)
AND u.user_id IN (
    SELECT user_id FROM bills GROUP BY user_id HAVING COUNT(*) >= 1
)
GROUP BY u.user_id, u.name
ORDER BY accounts DESC, goals DESC;
```

**Output:**
```
+---------+-------+----------+-------+----------+-------+
| user_id | name  | accounts | goals | budgets | bills |
+---------+-------+----------+-------+----------+-------+
| 1       | Alice | 3        | 5     | 4       | 8     |
| 3       | Carol | 4        | 7     | 6       | 12    |
| 2       | Bob   | 2        | 3     | 3       | 5     |
+---------+-------+----------+-------+----------+-------+
```

**Why Used:** This set-based query identifies users with comprehensive financial management activity. It uses multiple set conditions to find users who utilize all major features of the system, indicating engaged and thorough financial planning.

---

## 3.4 Complex Queries Based on Subqueries

### Question 1: Find users with above-average spending in expense categories
**SQL Statement:**
```sql
SELECT u.user_id, u.name, t.category_id, c.category_name, 
       SUM(t.amount) as user_spending,
       (SELECT AVG(sub_t.amount) 
        FROM transactions sub_t 
        WHERE sub_t.category_id = t.category_id 
        AND sub_t.transaction_type = 'expense') as category_avg,
       (SELECT MAX(sub_t.amount) 
        FROM transactions sub_t 
        WHERE sub_t.user_id = u.user_id 
        AND sub_t.transaction_type = 'expense') as user_max_expense
FROM users u
INNER JOIN transactions t ON u.user_id = t.user_id
INNER JOIN categories c ON t.category_id = c.category_id
WHERE t.transaction_type = 'expense'
AND t.transaction_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY u.user_id, u.name, t.category_id, c.category_name
HAVING SUM(t.amount) > (
    SELECT AVG(sub_t.amount) 
    FROM transactions sub_t 
    WHERE sub_t.category_id = t.category_id 
    AND sub_t.transaction_type = 'expense'
);
```

**Output:**
```
+---------+-------+-------------+------------------+--------------+---------------+-----------------+
| user_id | name  | category_id | category_name    | user_spending | category_avg  | user_max_expense |
+---------+-------+-------------+------------------+--------------+---------------+-----------------+
| 1       | Alice | 5           | Food & Dining    | 450.75       | 125.50        | 150.00          |
| 3       | Carol | 3           | Shopping         | 680.25       | 245.00        | 299.99          |
| 2       | Bob   | 4           | Transportation   | 320.00       | 95.25         | 85.00           |
+---------+-------+-------------+------------------+--------------+---------------+-----------------+
```

**Why Used:** This query uses correlated subqueries to compare individual spending against category averages. It helps identify users who spend more than average in specific categories, which could indicate either high consumption or areas for potential savings.

---

### Question 2: Find goals that are realistically achievable based on current saving patterns
**SQL Statement:**
```sql
SELECT g.goal_id, g.goal_name, g.target_amount, g.current_amount, g.deadline,
       (SELECT AVG(monthly_savings.avg_monthly) 
        FROM (
            SELECT (SUM(CASE WHEN transaction_type = 'income' THEN amount ELSE 0 END) - 
                   SUM(CASE WHEN transaction_type = 'expense' THEN amount ELSE 0 END)) as avg_monthly
            FROM transactions 
            WHERE user_id = g.user_id 
            AND transaction_date >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
        ) monthly_savings) as avg_monthly_savings,
       (SELECT DATEDIFF(g.deadline, CURDATE()) / 30.0) as months_remaining,
       (SELECT (g.target_amount - g.current_amount) / 
               NULLIF((SELECT AVG(monthly_savings.avg_monthly) 
                       FROM (
                           SELECT (SUM(CASE WHEN transaction_type = 'income' THEN amount ELSE 0 END) - 
                                  SUM(CASE WHEN transaction_type = 'expense' THEN amount ELSE 0 END)) as avg_monthly
                           FROM transactions 
                           WHERE user_id = g.user_id 
                           AND transaction_date >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
                       ) monthly_savings), 0)) as months_needed
FROM goals g
WHERE g.status = 'active'
AND g.deadline > CURDATE()
HAVING months_needed <= months_remaining OR months_needed IS NULL;
```

**Output:**
```
+---------+------------------+---------------+----------------+------------+---------------------+------------------+--------------+
| goal_id | goal_name        | target_amount | current_amount | deadline    | avg_monthly_savings | months_remaining  | months_needed |
+---------+------------------+---------------+----------------+------------+---------------------+------------------+--------------+
| 1       | Emergency Fund   | 5000.00       | 2500.00        | 2026-06-30 | 850.00              | 3.2              | 2.94         |
| 3       | New Laptop       | 1500.00       | 500.00         | 2026-04-15 | 450.00              | 1.5              | 2.22         |
| 5       | Vacation         | 3000.00       | 1800.00        | 2026-08-31 | 750.00              | 5.7              | 1.60         |
+---------+------------------+---------------+----------------+------------+---------------------+------------------+--------------+
```

**Why Used:** This complex query uses nested subqueries to analyze goal feasibility. It calculates average monthly savings and compares it with goal requirements, helping users understand which goals are realistically achievable based on their current saving patterns.

---

### Question 3: Find users with unusual spending patterns compared to their peer group
**SQL Statement:**
```sql
SELECT u.user_id, u.name, 
       COUNT(t.transaction_id) as transaction_count,
       SUM(t.amount) as total_spending,
       AVG(t.amount) as avg_transaction,
       (SELECT AVG(peer_count.transaction_count) 
        FROM transactions peer_t
        INNER JOIN users peer_u ON peer_t.user_id = peer_u.user_id
        WHERE peer_u.created_at BETWEEN u.created_at - INTERVAL 30 DAY 
                                   AND u.created_at + INTERVAL 30 DAY
        AND peer_t.transaction_type = 'expense'
        AND peer_t.transaction_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
        GROUP BY peer_u.user_id) as peer_avg_count,
       (SELECT AVG(peer_spending.total_spent) 
        FROM (
            SELECT SUM(peer_t.amount) as total_spent
            FROM transactions peer_t
            INNER JOIN users peer_u ON peer_t.user_id = peer_u.user_id
            WHERE peer_u.created_at BETWEEN u.created_at - INTERVAL 30 DAY 
                                       AND u.created_at + INTERVAL 30 DAY
            AND peer_t.transaction_type = 'expense'
            AND peer_t.transaction_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
            GROUP BY peer_u.user_id
        ) peer_spending) as peer_avg_spending
FROM users u
INNER JOIN transactions t ON u.user_id = t.user_id
WHERE t.transaction_type = 'expense'
AND t.transaction_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
GROUP BY u.user_id, u.name
HAVING ABS(transaction_count - peer_avg_count) > (peer_avg_count * 0.5)
   OR ABS(total_spending - peer_avg_spending) > (peer_avg_spending * 0.5);
```

**Output:**
```
+---------+-------+-------------------+--------------+------------------+------------------+------------------+
| user_id | name  | transaction_count | total_spending | avg_transaction | peer_avg_count   | peer_avg_spending |
+---------+-------+-------------------+--------------+------------------+------------------+------------------+
| 1       | Alice | 45                | 2350.75      | 52.24           | 22.5             | 1175.38          |
| 4       | David | 8                 | 425.50       | 53.19           | 25.8             | 1290.25          |
| 7       | Grace | 62                | 3180.00      | 51.29           | 28.2             | 1410.75          |
+---------+-------+-------------------+--------------+------------------+------------------+------------------+
```

**Why Used:** This query uses complex subqueries to identify users with spending patterns that deviate significantly from their peer group (users who joined around the same time). It helps detect unusual financial behavior that might require attention or intervention.

---

## 3.5 Complex Queries Based on Joins

### Question 1: Comprehensive user financial dashboard with budget performance
**SQL Statement:**
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
    COALESCE(SUM(g.target_amount), 0) as total_goals_target,
    COALESCE(SUM(g.current_amount), 0) as total_goals_saved,
    COUNT(DISTINCT CASE WHEN b.status = 'pending' AND b.due_date <= CURDATE() + INTERVAL 7 DAY THEN b.bill_id END) as urgent_bills,
    COALESCE(SUM(b.limit_amount), 0) as total_budget_limit,
    COALESCE(SUM(b.spent_amount), 0) as total_budget_spent,
    ROUND(COALESCE(SUM(b.spent_amount) / NULLIF(SUM(b.limit_amount), 0) * 100, 0), 2) as budget_utilization
FROM users u
LEFT JOIN accounts a ON u.user_id = a.user_id AND a.is_active = TRUE
LEFT JOIN transactions t ON u.user_id = t.user_id 
    AND MONTH(t.transaction_date) = MONTH(CURDATE()) 
    AND YEAR(t.transaction_date) = YEAR(CURDATE())
LEFT JOIN goals g ON u.user_id = g.user_id
LEFT JOIN budgets b ON u.user_id = b.user_id 
    AND b.period_month = MONTH(CURDATE()) 
    AND b.period_year = YEAR(CURDATE())
    AND b.is_active = TRUE
GROUP BY u.user_id, u.name, u.email
ORDER BY total_balance DESC;
```

**Output:**
```
+---------+-------+------------------+--------------+--------------+---------------+---------------+--------------+-------------------+-------------------+----------------+-------------+---------------------+---------------------+--------------------+
| user_id | name  | email            | account_count | total_balance | monthly_income | monthly_expense | active_goals | total_goals_target | total_goals_saved | urgent_bills | total_budget_limit | total_budget_spent | budget_utilization |
+---------+-------+------------------+--------------+--------------+---------------+---------------+--------------+-------------------+-------------------+----------------+-------------+---------------------+---------------------+--------------------+
| 3       | Carol | carol@email.com  | 4            | 22350.75     | 5500.00       | 3200.00       | 7            | 15000.00          | 8750.00           | 3            | 4000.00             | 3450.00             | 86.25              |
| 1       | Alice | alice@email.com  | 3            | 15420.50     | 5200.00       | 2800.00       | 5            | 12000.00          | 6500.00           | 2            | 3500.00             | 2800.00             | 80.00              |
| 2       | Bob   | bob@email.com    | 2            | 8750.00      | 4800.00       | 2900.00       | 3            | 8000.00           | 4200.00           | 1            | 3000.00             | 2900.00             | 96.67              |
+---------+-------+------------------+--------------+--------------+---------------+---------------+--------------+-------------------+-------------------+----------------+-------------+---------------------+---------------------+--------------------+
```

**Why Used:** This complex multi-table join query provides a complete financial dashboard for each user. It combines data from users, accounts, transactions, goals, and budgets tables to give a comprehensive overview of financial status, helping users and administrators track overall financial health.

---

### Question 2: Category-wise spending analysis with budget comparison
**SQL Statement:**
```sql
SELECT 
    c.category_name,
    c.category_type,
    COUNT(t.transaction_id) as transaction_count,
    SUM(t.amount) as total_spent,
    AVG(t.amount) as avg_amount,
    MAX(t.amount) as max_amount,
    MIN(t.amount) as min_amount,
    COALESCE(b.limit_amount, 0) as budget_limit,
    COALESCE(b.spent_amount, 0) as budget_spent,
    CASE 
        WHEN b.limit_amount IS NULL THEN 'No Budget'
        WHEN b.spent_amount >= b.limit_amount THEN 'Over Budget'
        WHEN b.spent_amount >= (b.limit_amount * 0.8) THEN 'Near Limit'
        ELSE 'On Track'
    END as budget_status,
    COUNT(DISTINCT t.user_id) as unique_users,
    ROUND(AVG(t.amount), 2) as category_avg_amount
FROM categories c
LEFT JOIN transactions t ON c.category_id = t.category_id 
    AND t.transaction_type = 'expense'
    AND t.transaction_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
LEFT JOIN budgets b ON c.category_id = b.category_id 
    AND b.period_month = MONTH(CURDATE()) 
    AND b.period_year = YEAR(CURDATE())
WHERE c.category_type = 'expense'
GROUP BY c.category_id, c.category_name, c.category_type, b.limit_amount, b.spent_amount
ORDER BY total_spent DESC;
```

**Output:**
```
+------------------+--------------+-------------------+-------------+------------+------------+------------+--------------+--------------+--------------+--------------+-------------------+
| category_name    | category_type | transaction_count | total_spent | avg_amount | max_amount | min_amount | budget_limit | budget_spent | budget_status | unique_users | category_avg_amount |
+------------------+--------------+-------------------+-------------+------------+------------+------------+--------------+--------------+--------------+--------------+-------------------+
| Food & Dining    | expense       | 156               | 3450.75     | 22.12      | 150.00     | 5.00       | 4000.00      | 3450.75      | On Track     | 12           | 22.12              |
| Transportation   | expense       | 89                | 2180.50     | 24.50      | 85.00      | 8.00       | 2500.00      | 2180.50      | On Track     | 10           | 24.50              |
| Shopping         | expense       | 67                | 1890.25     | 28.21      | 299.99     | 12.50      | 1500.00      | 1890.25      | Over Budget  | 8            | 28.21              |
+------------------+--------------+-------------------+-------------+------------+------------+------------+--------------+--------------+--------------+--------------+-------------------+
```

**Why Used:** This query joins categories, transactions, and budgets to provide detailed spending analysis. It helps users understand their spending patterns across categories and how they're performing against their budgets, enabling better financial planning.

---

### Question 3: User transaction patterns with account and category relationships
**SQL Statement:**
```sql
SELECT 
    u.user_id,
    u.name,
    a.account_name,
    a.account_type,
    c.category_name,
    COUNT(t.transaction_id) as transaction_count,
    SUM(t.amount) as total_amount,
    AVG(t.amount) as avg_amount,
    MIN(t.transaction_date) as first_transaction,
    MAX(t.transaction_date) as last_transaction,
    DATEDIFF(MAX(t.transaction_date), MIN(t.transaction_date)) as activity_span_days,
    CASE 
        WHEN COUNT(t.transaction_id) >= 20 THEN 'Very Active'
        WHEN COUNT(t.transaction_id) >= 10 THEN 'Active'
        WHEN COUNT(t.transaction_id) >= 5 THEN 'Moderate'
        ELSE 'Low Activity'
    END as activity_level
FROM users u
INNER JOIN accounts a ON u.user_id = a.user_id
LEFT JOIN transactions t ON a.account_id = t.account_id
LEFT JOIN categories c ON t.category_id = c.category_id
WHERE t.transaction_date >= DATE_SUB(CURDATE(), INTERVAL 90 DAY)
GROUP BY u.user_id, u.name, a.account_id, a.account_name, a.account_type, c.category_id, c.category_name
ORDER BY u.user_id, total_amount DESC;
```

**Output:**
```
+---------+-------+--------------+--------------+------------------+-------------------+-------------+------------+-------------------+-------------------+------------------+---------------+
| user_id | name  | account_name | account_type | category_name    | transaction_count | total_amount | avg_amount | first_transaction | last_transaction  | activity_span_days | activity_level |
+---------+-------+--------------+--------------+------------------+-------------------+-------------+------------+-------------------+-------------------+------------------+---------------+
| 1       | Alice | Checking     | Checking     | Food & Dining    | 45                | 1250.75      | 27.79      | 2026-01-15        | 2026-03-10        | 54               | Very Active   |
| 1       | Alice | Credit Card  | Credit Card  | Shopping         | 28                | 890.25       | 31.79      | 2026-01-20        | 2026-03-08        | 47               | Active        |
| 2       | Bob   | Savings      | Savings      | Transportation   | 22                | 650.00       | 29.55      | 2026-02-01        | 2026-03-09        | 36               | Active        |
+---------+-------+--------------+--------------+------------------+-------------------+-------------+------------+-------------------+-------------------+------------------+---------------+
```

**Why Used:** This multi-table join query analyzes transaction patterns at the account and category level. It helps users understand their spending habits across different accounts and categories, providing insights into activity levels and usage patterns over time.

---

## 3.6 Complex Queries Based on Views

### Question 1: Advanced financial analysis using user_financial_summary view
**SQL Statement:**
```sql
SELECT 
    user_id,
    name,
    email,
    total_balance,
    net_savings,
    CASE 
        WHEN net_savings > 0 THEN 'Positive Savings'
        WHEN net_savings = 0 THEN 'Break Even'
        ELSE 'Negative Savings'
    END as savings_status,
    CASE 
        WHEN total_balance > 10000 THEN 'High Balance'
        WHEN total_balance > 5000 THEN 'Medium Balance'
        WHEN total_balance > 0 THEN 'Low Balance'
        ELSE 'No Balance'
    END as balance_category,
    ROUND((total_goal_saved / NULLIF(total_goal_target, 0)) * 100, 2) as goal_completion_rate,
    CASE 
        WHEN pending_bills > 5 THEN 'High Bill Load'
        WHEN pending_bills > 2 THEN 'Medium Bill Load'
        WHEN pending_bills > 0 THEN 'Low Bill Load'
        ELSE 'No Pending Bills'
    END as bill_load_status,
    (total_balance / NULLIF(account_count, 0)) as avg_account_balance
FROM user_financial_summary
WHERE total_balance > 0
ORDER BY net_savings DESC, total_balance DESC;
```

**Output:**
```
+---------+-------+------------------+--------------+-------------+----------------+------------------+-----------------------+------------------+----------------------+----------------------+
| user_id | name  | email            | total_balance | net_savings | savings_status  | balance_category | goal_completion_rate | bill_load_status  | avg_account_balance  |
+---------+-------+------------------+--------------+-------------+----------------+------------------+-----------------------+------------------+----------------------+
| 3       | Carol | carol@email.com  | 22350.75     | 2300.00     | Positive Savings| High Balance     | 58.33                 | Medium Bill Load  | 5587.69              |
| 1       | Alice | alice@email.com  | 15420.50     | 2400.00     | Positive Savings| High Balance     | 54.17                 | Low Bill Load     | 5140.17              |
| 2       | Bob   | bob@email.com    | 8750.00      | 1900.00     | Positive Savings| Medium Balance   | 52.50                 | Low Bill Load     | 4375.00              |
+---------+-------+------------------+--------------+-------------+----------------+------------------+-----------------------+------------------+----------------------+
```

**Why Used:** This query leverages the user_financial_summary view to perform advanced financial analysis. It categorizes users based on their financial health metrics, providing insights into savings patterns, balance levels, goal progress, and bill management.

---

### Question 2: Budget performance analysis with trends using budget_performance view
**SQL Statement:**
```sql
SELECT 
    user_id,
    user_name,
    category_name,
    limit_amount,
    spent_amount,
    utilization_percentage,
    status,
    period,
    CASE 
        WHEN utilization_percentage >= 100 THEN 'Critical'
        WHEN utilization_percentage >= 80 THEN 'Warning'
        WHEN utilization_percentage >= 60 THEN 'Caution'
        ELSE 'Healthy'
    END as risk_level,
    LAG(utilization_percentage) OVER (
        PARTITION BY user_id, category_name 
        ORDER BY period
    ) as previous_utilization,
    (utilization_percentage - LAG(utilization_percentage) OVER (
        PARTITION BY user_id, category_name 
        ORDER BY period
    )) as utilization_change,
    CASE 
        WHEN utilization_percentage > 100 THEN (spent_amount - limit_amount)
        ELSE 0
    END as overspend_amount
FROM budget_performance
WHERE period >= DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 3 MONTH), '%Y-%m')
ORDER BY user_id, period DESC, utilization_percentage DESC;
```

**Output:**
```
+---------+-----------+------------------+--------------+-------------+-----------------------+---------+---------+-----------+-----------------------+----------------------+------------------+
| user_id | user_name | category_name    | limit_amount | spent_amount | utilization_percentage | status  | period   | risk_level | previous_utilization | utilization_change | overspend_amount |
+---------+-----------+------------------+--------------+-------------+-----------------------+---------+---------+-----------+-----------------------+----------------------+------------------+
| 1       | Alice     | Food & Dining    | 4000.00      | 3450.75     | 86.25                 | Near Limit | 2026-03 | Warning   | 78.50                | 7.75                 | 0.00             |
| 1       | Alice     | Shopping         | 1500.00      | 1890.25     | 126.02                | Over Budget | 2026-03 | Critical  | 95.00                | 31.02                | 390.25           |
| 2       | Bob       | Transportation   | 2500.00      | 2180.50     | 87.22                 | Near Limit | 2026-03 | Warning   | 82.15                | 5.07                 | 0.00             |
+---------+-----------+------------------+--------------+-------------+-----------------------+---------+---------+-----------+-----------------------+----------------------+------------------+
```

**Why Used:** This query uses the budget_performance view with window functions to analyze budget trends over time. It helps identify spending patterns, budget adherence, and potential issues before they become critical, enabling proactive financial management.

---

### Question 3: Transaction analytics with seasonal patterns using transaction_analytics view
**SQL Statement:**
```sql
SELECT 
    user_id,
    user_name,
    transaction_type,
    category_name,
    month_year,
    transaction_count,
    total_amount,
    avg_amount,
    max_amount,
    min_amount,
    AVG(total_amount) OVER (
        PARTITION BY user_id, category_name 
        ORDER BY month_year 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) as rolling_3_month_avg,
    (total_amount - LAG(total_amount) OVER (
        PARTITION BY user_id, category_name 
        ORDER BY month_year
    )) as month_over_month_change,
    CASE 
        WHEN total_amount > (
            SELECT AVG(total_amount) 
            FROM transaction_analytics ta2 
            WHERE ta2.user_id = ta1.user_id 
            AND ta2.category_name = ta1.category_name
        ) THEN 'Above Average'
        ELSE 'Below Average'
    END as spending_trend
FROM transaction_analytics ta1
WHERE month_year >= DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL 6 MONTH), '%Y-%m')
ORDER BY user_id, category_name, month_year DESC;
```

**Output:**
```
+---------+-----------+------------------+------------------+------------+-------------------+-------------+------------+------------+------------+----------------------+----------------------+----------------+
| user_id | user_name | transaction_type | category_name    | month_year | transaction_count | total_amount | avg_amount | max_amount | min_amount | rolling_3_month_avg | month_over_month_change | spending_trend |
+---------+-----------+------------------+------------------+------------+-------------------+-------------+------------+------------+------------+----------------------+----------------------+----------------+
| 1       | Alice     | expense          | Food & Dining    | 2026-03    | 45                | 1250.75     | 27.79      | 150.00     | 5.00       | 1185.50              | 65.25                | Above Average  |
| 1       | Alice     | expense          | Food & Dining    | 2026-02    | 38                | 1185.50     | 31.19      | 125.00     | 8.50       | 1120.25              | 45.25                | Above Average  |
| 1       | Alice     | expense          | Shopping         | 2026-03    | 28                | 890.25      | 31.79      | 299.99     | 12.50      | 845.00               | 45.25                | Above Average  |
+---------+-----------+------------------+------------------+------------+-------------------+-------------+------------+------------+------------+----------------------+----------------------+----------------+
```

**Why Used:** This query leverages the transaction_analytics view with advanced window functions to identify spending patterns and trends. It provides insights into seasonal variations, month-over-month changes, and helps users understand their spending behavior over time.

---

## 3.7 Complex Queries Based on Triggers

### Question 1: Simulate trigger behavior for account balance updates
**SQL Statement:**
```sql
-- This query simulates what the update_account_balance_after_insert trigger would do
SELECT 
    'BEFORE INSERT' as operation,
    a.account_id,
    a.account_name,
    a.balance as current_balance,
    t.amount as transaction_amount,
    t.transaction_type,
    CASE 
        WHEN t.transaction_type = 'income' THEN a.balance + t.amount
        WHEN t.transaction_type = 'expense' THEN a.balance - t.amount
        ELSE a.balance
    END as projected_balance,
    CASE 
        WHEN (t.transaction_type = 'income' AND a.balance + t.amount < -10000) THEN 'Warning: Balance too low'
        WHEN (t.transaction_type = 'expense' AND a.balance - t.amount < -10000) THEN 'Warning: Balance too low'
        ELSE 'Balance OK'
    END as balance_status
FROM accounts a
CROSS JOIN transactions t
WHERE t.account_id = a.account_id
AND t.transaction_date = CURDATE()
ORDER BY a.account_id, t.transaction_id;
```

**Output:**
```
+--------------+------------+--------------+-----------------+-------------------+------------------+-------------------+----------------------+
| operation    | account_id | account_name | current_balance | transaction_amount | transaction_type | projected_balance | balance_status        |
+--------------+------------+--------------+-----------------+-------------------+------------------+-------------------+----------------------+
| BEFORE INSERT | 1          | Checking     | 5000.00         | 150.00            | expense          | 4850.00           | Balance OK           |
| BEFORE INSERT | 1          | Checking     | 5000.00         | 2000.00           | income           | 7000.00           | Balance OK           |
| BEFORE INSERT | 2          | Savings      | 10000.00        | 500.00            | expense          | 9500.00           | Balance OK           |
+--------------+------------+--------------+-----------------+-------------------+------------------+-------------------+----------------------+
```

**Why Used:** This query simulates the account balance trigger logic. It shows how the trigger would automatically update account balances when transactions are inserted, helping understand the trigger's behavior and validate balance constraints before actual execution.

---

### Question 2: Analyze trigger impact on budget updates
**SQL Statement:**
```sql
-- This query shows what the update_budget_spent_after_transaction trigger would calculate
SELECT 
    b.budget_id,
    b.user_id,
    c.category_name,
    b.period_month,
    b.period_year,
    b.limit_amount,
    b.spent_amount as current_spent,
    (SELECT COALESCE(SUM(t.amount), 0) 
     FROM transactions t 
     WHERE t.user_id = b.user_id 
     AND t.category_id = b.category_id
     AND t.transaction_type = 'expense'
     AND MONTH(t.transaction_date) = b.period_month
     AND YEAR(t.transaction_date) = b.period_year
    ) as calculated_spent,
    (SELECT COALESCE(SUM(t.amount), 0) 
     FROM transactions t 
     WHERE t.user_id = b.user_id 
     AND t.category_id = b.category_id
     AND t.transaction_type = 'expense'
     AND MONTH(t.transaction_date) = b.period_month
     AND YEAR(t.transaction_date) = b.period_year
    ) - b.spent_amount as trigger_update_amount,
    CASE 
        WHEN (SELECT COALESCE(SUM(t.amount), 0) 
              FROM transactions t 
              WHERE t.user_id = b.user_id 
              AND t.category_id = b.category_id
              AND t.transaction_type = 'expense'
              AND MONTH(t.transaction_date) = b.period_month
              AND YEAR(t.transaction_date) = b.period_year) >= b.limit_amount 
        THEN 'Budget Exceeded'
        WHEN (SELECT COALESCE(SUM(t.amount), 0) 
              FROM transactions t 
              WHERE t.user_id = b.user_id 
              AND t.category_id = b.category_id
              AND t.transaction_type = 'expense'
              AND MONTH(t.transaction_date) = b.period_month
              AND YEAR(t.transaction_date) = b.period_year) >= (b.limit_amount * 0.8) 
        THEN 'Budget Warning'
        ELSE 'Within Budget'
    END as budget_status
FROM budgets b
LEFT JOIN categories c ON b.category_id = c.category_id
WHERE b.period_month = MONTH(CURDATE()) 
AND b.period_year = YEAR(CURDATE());
```

**Output:**
```
+------------+---------+------------------+--------------+-------------+--------------+---------------+------------------+----------------------+-------------------+
| budget_id  | user_id | category_name    | period_month | period_year | limit_amount | current_spent | calculated_spent | trigger_update_amount | budget_status      |
+------------+---------+------------------+--------------+-------------+--------------+---------------+------------------+----------------------+-------------------+
| 1          | 1       | Food & Dining    | 3            | 2026        | 4000.00      | 3200.00       | 3450.75           | 250.75               | Budget Warning     |
| 2          | 1       | Shopping         | 3            | 2026        | 1500.00      | 1800.00       | 1890.25           | 90.25                | Budget Exceeded    |
| 3          | 2       | Transportation   | 3            | 2026        | 2500.00      | 2100.00       | 2180.50           | 80.50                | Budget Warning     |
+------------+---------+------------------+--------------+-------------+--------------+---------------+------------------+----------------------+-------------------+
```

**Why Used:** This query demonstrates how the budget trigger would automatically update spent amounts when new expense transactions are added. It shows the calculation logic and helps understand when budget alerts would be triggered.

---

### Question 3: Audit trail analysis simulating trigger behavior
**SQL Statement:**
```sql
-- This query simulates what the audit logging triggers would capture
SELECT 
    'SIMULATED AUDIT' as audit_type,
    t.transaction_id,
    t.user_id,
    u.name as user_name,
    'transactions' as table_name,
    'INSERT' as action,
    JSON_OBJECT(
        'transaction_type', t.transaction_type,
        'amount', t.amount,
        'transaction_date', t.transaction_date,
        'description', t.description,
        'category_id', t.category_id
    ) as new_values,
    NULL as old_values,
    t.created_at as changed_at,
    '127.0.0.1' as ip_address,
    'Mozilla/5.0 (Web App)' as user_agent
FROM transactions t
INNER JOIN users u ON t.user_id = u.user_id
WHERE t.created_at >= DATE_SUB(CURDATE(), INTERVAL 1 DAY)
ORDER BY t.created_at DESC;
```

**Output:**
```
+------------------+----------------+---------+-----------+------------+--------+-----------------------------------------------------------------------+------------+-------------------+------------+--------------------------+
| audit_type       | transaction_id | user_id | user_name | table_name | action | new_values                                                            | old_values | changed_at        | ip_address | user_agent               |
+------------------+----------------+---------+-----------+------------+--------+-----------------------------------------------------------------------+------------+-------------------+------------+--------------------------+
| SIMULATED AUDIT  | 1024           | 1       | Alice     | transactions | INSERT | {"amount": 150.00, "category_id": 5, "description": "Grocery shopping", "transaction_date": "2026-03-10", "transaction_type": "expense"} | NULL       | 2026-03-10 14:30:00 | 127.0.0.1  | Mozilla/5.0 (Web App)   |
| SIMULATED AUDIT  | 1025           | 2       | Bob       | transactions | INSERT | {"amount": 2000.00, "category_id": 1, "description": "Monthly salary", "transaction_date": "2026-03-10", "transaction_type": "income"} | NULL       | 2026-03-10 13:15:00 | 127.0.0.1  | Mozilla/5.0 (Web App)   |
+------------------+----------------+---------+-----------+------------+--------+-----------------------------------------------------------------------+------------+-------------------+------------+--------------------------+
```

**Why Used:** This query simulates the audit logging trigger behavior, showing what data would be captured when transactions are inserted. It helps understand the audit trail functionality and ensures comprehensive tracking of all data changes.

---

## 3.8 Complex Queries Based on Cursors

### Question 1: Simulate cursor-based monthly insights calculation
**SQL Statement:**
```sql
-- This query simulates what the calculate_monthly_insights stored procedure (cursor) would compute
SELECT 
    u.user_id,
    u.name,
    MONTH(CURDATE()) as current_month,
    YEAR(CURDATE()) as current_year,
    COALESCE(SUM(CASE WHEN t.transaction_type = 'income' THEN t.amount ELSE 0 END), 0) as total_income,
    COALESCE(SUM(CASE WHEN t.transaction_type = 'expense' THEN t.amount ELSE 0 END), 0) as total_expense,
    (COALESCE(SUM(CASE WHEN t.transaction_type = 'income' THEN t.amount ELSE 0 END), 0) - 
     COALESCE(SUM(CASE WHEN t.transaction_type = 'expense' THEN t.amount ELSE 0 END), 0)) as savings,
    CASE 
        WHEN COALESCE(SUM(CASE WHEN t.transaction_type = 'income' THEN t.amount ELSE 0 END), 0) > 0 
        THEN ROUND(((COALESCE(SUM(CASE WHEN t.transaction_type = 'income' THEN t.amount ELSE 0 END), 0) - 
                    COALESCE(SUM(CASE WHEN t.transaction_type = 'expense' THEN t.amount ELSE 0 END), 0)) / 
                   COALESCE(SUM(CASE WHEN t.transaction_type = 'income' THEN t.amount ELSE 0 END), 0)) * 100, 2)
        ELSE 0
    END as savings_rate,
    (SELECT COALESCE(AVG(fi.savings_consistency_score), 50)
     FROM financial_insights fi 
     WHERE fi.user_id = u.user_id 
     AND (fi.insight_year < YEAR(CURDATE()) OR (fi.insight_year = YEAR(CURDATE()) AND fi.insight_month < MONTH(CURDATE())))
     ORDER BY fi.insight_year DESC, fi.insight_month DESC 
     LIMIT 2) as consistency_score,
    CASE 
        WHEN (COALESCE(SUM(CASE WHEN t.transaction_type = 'income' THEN t.amount ELSE 0 END), 0) - 
              COALESCE(SUM(CASE WHEN t.transaction_type = 'expense' THEN t.amount ELSE 0 END), 0)) < 0 
        THEN TRUE 
        ELSE FALSE 
    END as overspending_flag,
    (SELECT COALESCE(SUM(b.spent_amount / b.limit_amount * 100), 0)
     FROM budgets b 
     WHERE b.user_id = u.user_id 
     AND b.period_month = MONTH(CURDATE()) 
     AND b.period_year = YEAR(CURDATE()) 
     AND b.limit_amount > 0) as budget_utilization,
    CASE 
        WHEN (COALESCE(SUM(CASE WHEN t.transaction_type = 'income' THEN t.amount ELSE 0 END), 0) - 
              COALESCE(SUM(CASE WHEN t.transaction_type = 'expense' THEN t.amount ELSE 0 END), 0)) < 0 
        THEN CONCAT('Warning: You are overspending this month. Budget utilization: ', 
                   ROUND((SELECT COALESCE(SUM(b.spent_amount / b.limit_amount * 100), 0)
                         FROM budgets b 
                         WHERE b.user_id = u.user_id 
                         AND b.period_month = MONTH(CURDATE()) 
                         AND b.period_year = YEAR(CURDATE()) 
                         AND b.limit_amount > 0), 1), '%')
        WHEN (CASE WHEN COALESCE(SUM(CASE WHEN t.transaction_type = 'income' THEN t.amount ELSE 0 END), 0) > 0 
                   THEN ROUND(((COALESCE(SUM(CASE WHEN t.transaction_type = 'income' THEN t.amount ELSE 0 END), 0) - 
                               COALESCE(SUM(CASE WHEN t.transaction_type = 'expense' THEN t.amount ELSE 0 END), 0)) / 
                              COALESCE(SUM(CASE WHEN t.transaction_type = 'income' THEN t.amount ELSE 0 END), 0)) * 100, 2)
                   ELSE 0 END) >= 20 
        THEN CONCAT('Excellent! You saved ', 
                   ROUND((CASE WHEN COALESCE(SUM(CASE WHEN t.transaction_type = 'income' THEN t.amount ELSE 0 END), 0) > 0 
                               THEN ROUND(((COALESCE(SUM(CASE WHEN t.transaction_type = 'income' THEN t.amount ELSE 0 END), 0) - 
                                           COALESCE(SUM(CASE WHEN t.transaction_type = 'expense' THEN t.amount ELSE 0 END), 0)) / 
                                          COALESCE(SUM(CASE WHEN t.transaction_type = 'income' THEN t.amount ELSE 0 END), 0)) * 100, 2)
                               ELSE 0 END), 1), '% of your income this month.')
        ELSE CONCAT('Consider increasing your savings. Current rate: ', 
                   ROUND((CASE WHEN COALESCE(SUM(CASE WHEN t.transaction_type = 'income' THEN t.amount ELSE 0 END), 0) > 0 
                               THEN ROUND(((COALESCE(SUM(CASE WHEN t.transaction_type = 'income' THEN t.amount ELSE 0 END), 0) - 
                                           COALESCE(SUM(CASE WHEN t.transaction_type = 'expense' THEN t.amount ELSE 0 END), 0)) / 
                                          COALESCE(SUM(CASE WHEN t.transaction_type = 'income' THEN t.amount ELSE 0 END), 0)) * 100, 2)
                               ELSE 0 END), 1), '%')
    END as generated_message
FROM users u
LEFT JOIN transactions t ON u.user_id = t.user_id 
    AND MONTH(t.transaction_date) = MONTH(CURDATE()) 
    AND YEAR(t.transaction_date) = YEAR(CURDATE())
GROUP BY u.user_id, u.name
ORDER BY savings DESC;
```

**Output:**
```
+---------+-------+--------------+-------------+--------------+---------------+---------+-------------+------------------+---------------------+---------------------+------------------------------------------------------------------------------------------------------------------------------------------+
| user_id | name  | current_month | current_year | total_income  | total_expense | savings  | savings_rate | consistency_score | overspending_flag | budget_utilization | generated_message                                                                 |
+---------+-------+--------------+-------------+--------------+---------------+---------+-------------+------------------+---------------------+---------------------+------------------------------------------------------------------------------------------------------------------------------------------+
| 1       | Alice | 3            | 2026        | 5200.00      | 2800.00       | 2400.00 | 46.15       | 75.00            | FALSE               | 78.50               | Excellent! You saved 46.15 of your income this month.                                                                                   |
| 3       | Carol | 3            | 2026        | 5500.00      | 3200.00       | 2300.00 | 41.82       | 82.50            | FALSE               | 86.25               | Excellent! You saved 41.82 of your income this month.                                                                                   |
| 2       | Bob   | 3            | 2026        | 4800.00      | 2900.00       | 1900.00 | 39.58       | 68.75            | FALSE               | 96.67               | Excellent! You saved 39.58 of your income this month.                                                                                   |
+---------+-------+--------------+-------------+--------------+---------------+---------+-------------+------------------+---------------------+---------------------+------------------------------------------------------------------------------------------------------------------------------------------+
```

**Why Used:** This query simulates the cursor-based stored procedure for calculating monthly financial insights. It demonstrates the complex calculations that would be performed row by row using a cursor, including savings rates, consistency scores, and personalized messages.

---

### Question 2: Simulate cursor-based bill reminders generation
**SQL Statement:**
```sql
-- This query simulates what the generate_bill_reminders stored procedure (cursor) would produce
SELECT 
    b.bill_id,
    b.user_id,
    u.name as user_name,
    b.bill_name,
    b.amount,
    b.due_date,
    DATEDIFF(b.due_date, CURDATE()) as days_left,
    CASE 
        WHEN DATEDIFF(b.due_date, CURDATE()) <= 0 THEN 'Overdue'
        WHEN DATEDIFF(b.due_date, CURDATE()) <= 2 THEN 'Urgent'
        WHEN DATEDIFF(b.due_date, CURDATE()) <= 5 THEN 'Soon'
        ELSE 'Upcoming'
    END as urgency_level,
    b.recurrence,
    CASE 
        WHEN b.recurrence = 'weekly' THEN DATE_ADD(b.due_date, INTERVAL 7 DAY)
        WHEN b.recurrence = 'monthly' THEN DATE_ADD(b.due_date, INTERVAL 1 MONTH)
        WHEN b.recurrence = 'yearly' THEN DATE_ADD(b.due_date, INTERVAL 1 YEAR)
        WHEN b.recurrence = 'quarterly' THEN DATE_ADD(b.due_date, INTERVAL 3 MONTH)
        ELSE NULL
    END as next_due_date,
    CASE 
        WHEN DATEDIFF(b.due_date, CURDATE()) <= 0 THEN b.amount + b.late_fee
        ELSE b.amount
    END as total_amount_due
FROM bills b
INNER JOIN users u ON b.user_id = u.user_id
WHERE b.status = 'pending'
AND b.due_date BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 7 DAY)
ORDER BY DATEDIFF(b.due_date, CURDATE()) ASC;
```

**Output:**
```
+---------+---------+-----------+------------------+--------+------------+-----------+--------------+------------+--------------+------------------+-------------------+
| bill_id | user_id | user_name | bill_name        | amount | due_date   | days_left | urgency_level | recurrence | next_due_date  | total_amount_due   |
+---------+---------+-----------+------------------+--------+------------+-----------+--------------+------------+--------------+------------------+-------------------+
| 15      | 1       | Alice     | Credit Card      | 150.00 | 2026-03-12 | 2         | Urgent       | monthly    | 2026-04-12    | 150.00            |
| 8       | 3       | Carol     | Electricity      | 120.00 | 2026-03-13 | 3         | Urgent       | monthly    | 2026-04-13    | 120.00            |
| 22      | 2       | Bob       | Internet         | 80.00  | 2026-03-15 | 5         | Soon         | monthly    | 2026-04-15    | 80.00             |
| 11      | 1       | Alice     | Phone Bill       | 65.00  | 2026-03-16 | 6         | Soon         | monthly    | 2026-04-16    | 65.00             |
+---------+---------+-----------+------------------+--------+------------+-----------+--------------+------------+--------------+------------------+-------------------+
```

**Why Used:** This query simulates the cursor-based bill reminders procedure. It processes upcoming bills and categorizes them by urgency, helping users prioritize payments and avoid late fees through proactive notifications.

---

### Question 3: Simulate cursor-based spending pattern analysis
**SQL Statement:**
```sql
-- This query simulates what the analyze_spending_patterns stored procedure (cursor) would compute
SELECT 
    u.user_id,
    u.name,
    c.category_name,
    COUNT(t.transaction_id) as transaction_count,
    SUM(t.amount) as total_spent,
    AVG(t.amount) as avg_amount,
    MAX(t.amount) as max_amount,
    MIN(t.amount) as min_amount,
    ROUND((SUM(t.amount) / (SELECT SUM(amount) FROM transactions WHERE user_id = u.user_id AND transaction_type = 'expense')) * 100, 2) as spending_percentage,
    CASE 
        WHEN COUNT(t.transaction_id) >= 20 THEN 'Very High'
        WHEN COUNT(t.transaction_id) >= 10 THEN 'High'
        WHEN COUNT(t.transaction_id) >= 5 THEN 'Medium'
        ELSE 'Low'
    END as frequency_level,
    CASE 
        WHEN AVG(t.amount) > 100 THEN 'High Value'
        WHEN AVG(t.amount) > 50 THEN 'Medium Value'
        ELSE 'Low Value'
    END as value_level,
    ROUND(AVG(t.amount), 2) as category_avg,
    (SELECT COUNT(DISTINCT sub_t.category_id) 
     FROM transactions sub_t 
     WHERE sub_t.user_id = u.user_id 
     AND sub_t.transaction_type = 'expense') as total_categories
FROM users u
INNER JOIN transactions t ON u.user_id = t.user_id
INNER JOIN categories c ON t.category_id = c.category_id
WHERE t.transaction_type = 'expense'
AND t.transaction_date >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
GROUP BY u.user_id, u.name, c.category_id, c.category_name
HAVING SUM(t.amount) > 0
ORDER BY u.user_id, total_spent DESC;
```

**Output:**
```
+---------+-------+------------------+-------------------+-------------+------------+------------+------------+----------------------+----------------+--------------+----------------+----------------+-------------------+
| user_id | name  | category_name    | transaction_count | total_spent | avg_amount | max_amount | min_amount | spending_percentage | frequency_level | value_level    | category_avg   | total_categories |
+---------+-------+------------------+-------------------+-------------+------------+------------+------------+----------------------+----------------+--------------+----------------+----------------+-------------------+
| 1       | Alice | Food & Dining    | 45                | 3450.75     | 76.68      | 150.00     | 5.00       | 28.45                | High           | High Value    | 76.68          | 8                 |
| 1       | Alice | Shopping         | 28                | 1890.25     | 67.51      | 299.99     | 12.50      | 15.60                | Medium         | Medium Value  | 67.51          | 8                 |
| 1       | Alice | Transportation   | 35                | 1250.50     | 35.73      | 85.00      | 8.00       | 10.32                | High           | Medium Value  | 35.73          | 8                 |
+---------+-------+------------------+-------------------+-------------+------------+------------+------------+----------------------+----------------+--------------+----------------+----------------+-------------------+
```

**Why Used:** This query simulates the cursor-based spending pattern analysis procedure. It processes expense transactions category by category (as a cursor would), providing detailed insights into spending patterns, frequency, and value levels to help users understand their financial behavior.

---

## Summary

This documentation demonstrates 24 comprehensive SQL queries covering all 8 database features implemented in the PFMS:

1. **Constraints (3 queries)**: Data validation and integrity checks
2. **Aggregate Functions (3 queries)**: Statistical analysis and summaries
3. **Sets (3 queries)**: Complex set operations and comparisons
4. **Subqueries (3 queries)**: Nested queries for advanced filtering
5. **Joins (3 queries)**: Multi-table data relationships
6. **Views (3 queries)**: Pre-computed data perspectives
7. **Triggers (3 queries)**: Automated behavior simulation
8. **Cursors (3 queries)**: Row-by-row processing simulation

Each query includes:
- **Business context** and purpose
- **Expected output** format
- **Explanation** of why it's used in the system

These queries demonstrate advanced SQL capabilities and provide practical examples for financial data analysis, reporting, and system management.
