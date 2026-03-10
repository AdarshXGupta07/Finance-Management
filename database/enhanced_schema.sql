-- Enhanced Personal Finance Management System (PFMS)
-- With additional constraints, sets, joins, views, triggers, and cursors
CREATE DATABASE IF NOT EXISTS pfms_db;
USE pfms_db;

-- Enhanced Users table with additional constraints
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

-- Enhanced Accounts table with SET type and additional constraints
CREATE TABLE account_types (
    type_id INT PRIMARY KEY AUTO_INCREMENT,
    type_name VARCHAR(50) NOT NULL UNIQUE
);

INSERT INTO account_types (type_name) VALUES 
('Savings'), ('Checking'), ('Credit Card'), ('Investment'), ('Cash'), ('Other');

CREATE TABLE accounts (
    account_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    account_name VARCHAR(100) NOT NULL CHECK (LENGTH(account_name) >= 2),
    account_type_id INT NOT NULL,
    balance DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK (balance >= -10000),
    currency VARCHAR(3) DEFAULT 'USD' CHECK (currency IN ('USD', 'EUR', 'GBP', 'JPY', 'INR')),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_accounts_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_accounts_type FOREIGN KEY (account_type_id) REFERENCES account_types(type_id),
    CONSTRAINT uq_user_account_name UNIQUE (user_id, account_name)
);

-- Enhanced Categories with SET for tags
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

-- Enhanced Transactions with more constraints
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

-- Enhanced Budgets with complex constraints
CREATE TABLE budgets (
    budget_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    category_id INT NULL,
    period_month TINYINT NOT NULL CHECK (period_month BETWEEN 1 AND 12),
    period_year SMALLINT NOT NULL CHECK (period_year >= 2020 AND period_year <= 2030),
    limit_amount DECIMAL(12,2) NOT NULL CHECK (limit_amount > 0 AND limit_amount <= 1000000),
    spent_amount DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK (spent_amount >= 0),
    alert_threshold DECIMAL(5,2) DEFAULT 80.00 CHECK (alert_threshold BETWEEN 50 AND 100),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_budget_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_budget_category FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE SET NULL,
    CONSTRAINT uq_user_budget UNIQUE (user_id, category_id, period_month, period_year),
    CONSTRAINT chk_spent_vs_limit CHECK (spent_amount <= limit_amount)
);

-- Enhanced Goals with progress tracking
CREATE TABLE goals (
    goal_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    goal_name VARCHAR(100) NOT NULL CHECK (LENGTH(goal_name) >= 3),
    target_amount DECIMAL(12,2) NOT NULL CHECK (target_amount > 0 AND target_amount <= 10000000),
    current_amount DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK (current_amount >= 0 AND current_amount <= target_amount),
    deadline DATE CHECK (deadline > CURDATE() OR deadline IS NULL),
    priority ENUM('low', 'medium', 'high') DEFAULT 'medium',
    status ENUM('active', 'achieved', 'paused', 'cancelled') DEFAULT 'active',
    auto_contribute BOOLEAN DEFAULT FALSE,
    contribution_amount DECIMAL(12,2) CHECK (contribution_amount > 0 OR contribution_amount IS NULL),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_goal_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT chk_progress CHECK (current_amount <= target_amount),
    CONSTRAINT chk_deadline_status CHECK (status != 'active' OR (deadline IS NULL OR deadline > CURDATE()))
);

-- Enhanced Bills with payment tracking
CREATE TABLE bills (
    bill_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    bill_name VARCHAR(100) NOT NULL CHECK (LENGTH(bill_name) >= 2),
    amount DECIMAL(12,2) NOT NULL CHECK (amount > 0 AND amount <= 100000),
    due_date DATE NOT NULL CHECK (due_date >= CURDATE() - INTERVAL 1 MONTH),
    recurrence ENUM('weekly', 'monthly', 'yearly', 'quarterly') NOT NULL DEFAULT 'monthly',
    status ENUM('pending', 'paid', 'overdue', 'cancelled') DEFAULT 'pending',
    paid_date DATE CHECK (paid_date IS NULL OR paid_date <= CURDATE()),
    late_fee DECIMAL(12,2) DEFAULT 0 CHECK (late_fee >= 0),
    autopay BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_bill_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT chk_paid_date CHECK (status != 'paid' OR paid_date IS NOT NULL),
    CONSTRAINT chk_overdue CHECK (status != 'overdue' OR due_date < CURDATE())
);

-- Enhanced Financial Insights with more metrics
CREATE TABLE financial_insights (
    insight_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    insight_month TINYINT NOT NULL CHECK (insight_month BETWEEN 1 AND 12),
    insight_year SMALLINT NOT NULL CHECK (insight_year >= 2020 AND insight_year <= 2030),
    total_income DECIMAL(12,2) NOT NULL DEFAULT 0,
    total_expense DECIMAL(12,2) NOT NULL DEFAULT 0,
    savings DECIMAL(12,2) NOT NULL DEFAULT 0,
    savings_rate DECIMAL(5,2) NOT NULL DEFAULT 0 CHECK (savings_rate BETWEEN -100 AND 100),
    savings_consistency_score DECIMAL(5,2) NOT NULL DEFAULT 0 CHECK (savings_consistency_score BETWEEN 0 AND 100),
    overspending_flag BOOLEAN NOT NULL DEFAULT FALSE,
    budget_utilization DECIMAL(5,2) DEFAULT 0 CHECK (budget_utilization BETWEEN 0 AND 150),
    top_expense_category VARCHAR(100),
    financial_health_score DECIMAL(5,2) DEFAULT 0 CHECK (financial_health_score BETWEEN 0 AND 100),
    generated_message VARCHAR(500) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_insight_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT uq_monthly_insight UNIQUE (user_id, insight_month, insight_year)
);

-- Transaction Tags junction table for many-to-many relationship
CREATE TABLE transaction_tags (
    transaction_id INT NOT NULL,
    tag_name VARCHAR(50) NOT NULL,
    PRIMARY KEY (transaction_id, tag_name),
    CONSTRAINT fk_txn_tag_transaction FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id) ON DELETE CASCADE
);

-- User Preferences table
CREATE TABLE user_preferences (
    preference_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    date_format VARCHAR(20) DEFAULT '%Y-%m-%d',
    timezone VARCHAR(50) DEFAULT 'UTC',
    email_notifications BOOLEAN DEFAULT TRUE,
    budget_alerts BOOLEAN DEFAULT TRUE,
    goal_reminders BOOLEAN DEFAULT TRUE,
    bill_reminders BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_pref_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT uq_user_preferences UNIQUE (user_id)
);

-- Audit Log table for tracking changes
CREATE TABLE audit_log (
    log_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    table_name VARCHAR(50) NOT NULL,
    record_id INT NOT NULL,
    action ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
    old_values JSON,
    new_values JSON,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45),
    user_agent TEXT,
    CONSTRAINT fk_audit_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL
);

-- ==================== VIEWS ====================

-- View for user financial summary
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

-- View for budget performance
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
        WHEN b.spent_amount >= (b.limit_amount * b.alert_threshold / 100) THEN 'Near Limit'
        ELSE 'On Track'
    END as status,
    c.category_name,
    CONCAT(b.period_month, '-', b.period_year) as period,
    u.name as user_name
FROM budgets b
LEFT JOIN categories c ON b.category_id = c.category_id
LEFT JOIN users u ON b.user_id = u.user_id
WHERE b.is_active = TRUE;

-- View for transaction analytics
CREATE VIEW transaction_analytics AS
SELECT 
    t.user_id,
    u.name as user_name,
    t.transaction_type,
    c.category_name,
    COUNT(*) as transaction_count,
    SUM(t.amount) as total_amount,
    AVG(t.amount) as average_amount,
    MIN(t.amount) as min_amount,
    MAX(t.amount) as max_amount,
    DATE_FORMAT(t.transaction_date, '%Y-%m') as month_year
FROM transactions t
LEFT JOIN users u ON t.user_id = u.user_id
LEFT JOIN categories c ON t.category_id = c.category_id
WHERE t.transaction_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
GROUP BY t.user_id, u.name, t.transaction_type, c.category_name, DATE_FORMAT(t.transaction_date, '%Y-%m');

-- View for goal progress
CREATE VIEW goal_progress AS
SELECT 
    g.goal_id,
    g.user_id,
    u.name as user_name,
    g.goal_name,
    g.target_amount,
    g.current_amount,
    CASE 
        WHEN g.target_amount = 0 THEN 0
        ELSE ROUND((g.current_amount / g.target_amount) * 100, 2)
    END as completion_percentage,
    CASE 
        WHEN g.deadline IS NULL THEN 'No Deadline'
        WHEN CURDATE() > g.deadline AND g.status = 'active' THEN 'Overdue'
        WHEN g.current_amount >= g.target_amount THEN 'Completed'
        ELSE 'In Progress'
    END as progress_status,
    DATEDIFF(g.deadline, CURDATE()) as days_remaining,
    g.priority,
    g.status
FROM goals g
LEFT JOIN users u ON g.user_id = u.user_id;

-- ==================== TRIGGERS ====================

-- Trigger to update account balance when transaction is added
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
    
    -- Insert into audit log
    INSERT INTO audit_log (user_id, table_name, record_id, action, new_values)
    VALUES (NEW.user_id, 'transactions', NEW.transaction_id, 'INSERT', JSON_OBJECT(
        'transaction_type', NEW.transaction_type,
        'amount', NEW.amount,
        'transaction_date', NEW.transaction_date,
        'description', NEW.description
    ));
END//
DELIMITER ;

-- Trigger to update account balance when transaction is updated
DELIMITER //
CREATE TRIGGER update_account_balance_after_update
AFTER UPDATE ON transactions
FOR EACH ROW
BEGIN
    DECLARE old_account_id INT;
    DECLARE new_account_id INT;
    DECLARE old_amount DECIMAL(12,2);
    DECLARE new_amount DECIMAL(12,2);
    DECLARE old_type VARCHAR(20);
    DECLARE new_type VARCHAR(20);
    
    SET old_account_id = OLD.account_id;
    SET new_account_id = NEW.account_id;
    SET old_amount = OLD.amount;
    SET new_amount = NEW.amount;
    SET old_type = OLD.transaction_type;
    SET new_type = NEW.transaction_type;
    
    -- Reverse old transaction effect
    IF old_account_id IS NOT NULL THEN
        UPDATE accounts 
        SET balance = CASE 
            WHEN old_type = 'income' THEN balance - old_amount
            WHEN old_type = 'expense' THEN balance + old_amount
            ELSE balance
        END,
        updated_at = CURRENT_TIMESTAMP
        WHERE account_id = old_account_id;
    END IF;
    
    -- Apply new transaction effect
    IF new_account_id IS NOT NULL THEN
        UPDATE accounts 
        SET balance = CASE 
            WHEN new_type = 'income' THEN balance + new_amount
            WHEN new_type = 'expense' THEN balance - new_amount
            ELSE balance
        END,
        updated_at = CURRENT_TIMESTAMP
        WHERE account_id = new_account_id;
    END IF;
    
    -- Insert into audit log
    INSERT INTO audit_log (user_id, table_name, record_id, action, old_values, new_values)
    VALUES (NEW.user_id, 'transactions', NEW.transaction_id, 'UPDATE', 
            JSON_OBJECT('amount', old_amount, 'transaction_type', old_type),
            JSON_OBJECT('amount', new_amount, 'transaction_type', new_type));
END//
DELIMITER ;

-- Trigger to update budget spent amount
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

-- Trigger to update goal progress
DELIMITER //
CREATE TRIGGER update_goal_progress_after_transaction
AFTER INSERT ON transactions
FOR EACH ROW
BEGIN
    IF NEW.transaction_type = 'income' THEN
        UPDATE goals 
        SET current_amount = LEAST(current_amount + NEW.amount, target_amount),
            updated_at = CURRENT_TIMESTAMP
        WHERE user_id = NEW.user_id 
        AND auto_contribute = TRUE 
        AND status = 'active';
    END IF;
END//
DELIMITER ;

-- Trigger to update bill status
DELIMITER //
CREATE TRIGGER update_bill_status_daily
AFTER UPDATE ON bills
FOR EACH ROW
BEGIN
    -- Update overdue bills
    IF NEW.status = 'pending' AND NEW.due_date < CURDATE() THEN
        UPDATE bills 
        SET status = 'overdue',
            updated_at = CURRENT_TIMESTAMP
        WHERE bill_id = NEW.bill_id;
    END IF;
    
    -- Insert into audit log
    INSERT INTO audit_log (user_id, table_name, record_id, action, old_values, new_values)
    VALUES (NEW.user_id, 'bills', NEW.bill_id, 'UPDATE', 
            JSON_OBJECT('status', OLD.status),
            JSON_OBJECT('status', NEW.status));
END//
DELIMITER ;

-- ==================== STORED PROCEDURES (for cursor operations) ====================

DELIMITER //
-- Procedure to calculate monthly financial insights using cursor
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
    
    -- Calculate budget utilization
    SELECT COALESCE(SUM(spent_amount / limit_amount * 100), 0) INTO budget_util_val
    FROM budgets 
    WHERE user_id = p_user_id 
    AND period_month = p_month 
    AND period_year = p_year 
    AND limit_amount > 0;
    
    -- Calculate consistency score (based on last 3 months)
    SELECT AVG(savings_consistency_score) INTO consistency_score_val
    FROM financial_insights 
    WHERE user_id = p_user_id 
    AND (insight_year < p_year OR (insight_year = p_year AND insight_month < p_month))
    ORDER BY insight_year DESC, insight_month DESC 
    LIMIT 2;
    
    IF consistency_score_val IS NULL THEN
        SET consistency_score_val = 50; -- Default score
    END IF;
    
    -- Determine overspending flag
    IF budget_util_val > 100 OR savings_val < 0 THEN
        SET overspending_flag_val = TRUE;
    END IF;
    
    -- Calculate financial health score
    SET health_score_val = 
        (CASE WHEN savings_rate_val > 20 THEN 25 ELSE GREATEST(0, savings_rate_val * 1.25) END) +
        (CASE WHEN budget_util_val <= 80 THEN 25 ELSE GREATEST(0, 25 - (budget_util_val - 80) * 0.5) END) +
        (CASE WHEN consistency_score_val >= 80 THEN 25 ELSE consistency_score_val * 0.3125 END) +
        (CASE WHEN overspending_flag_val = FALSE THEN 25 ELSE 0 END);
    
    -- Generate message
    SET message_val = CASE
        WHEN overspending_flag_val = TRUE THEN 
            CONCAT('Warning: You are overspending this month. Budget utilization: ', ROUND(budget_util_val, 1), '%')
        WHEN savings_rate_val >= 20 THEN 
            CONCAT('Excellent! You saved ', ROUND(savings_rate_val, 1), '% of your income this month.')
        WHEN savings_rate_val >= 10 THEN 
            CONCAT('Good job! You saved ', ROUND(savings_rate_val, 1), '% of your income this month.')
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
        savings_rate = VALUES(savings_rate),
        savings_consistency_score = VALUES(savings_consistency_score),
        overspending_flag = VALUES(overspending_flag),
        budget_utilization = VALUES(budget_utilization),
        financial_health_score = VALUES(financial_health_score),
        generated_message = VALUES(generated_message);
END//
DELIMITER ;

-- Procedure to generate bill reminders using cursor
DELIMITER //
CREATE PROCEDURE generate_bill_reminders(IN p_user_id INT)
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE bill_id_val INT;
    DECLARE bill_name_val VARCHAR(100);
    DECLARE due_date_val DATE;
    DECLARE amount_val DECIMAL(12,2);
    DECLARE days_left INT;
    
    -- Cursor for upcoming bills
    DECLARE bill_cursor CURSOR FOR 
        SELECT bill_id, bill_name, due_date, amount
        FROM bills 
        WHERE user_id = p_user_id 
        AND status = 'pending'
        AND due_date BETWEEN CURDATE() AND CURDATE() + INTERVAL 7 DAY
        ORDER BY due_date ASC;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    -- Create temporary table for reminders
    CREATE TEMPORARY TABLE IF NOT EXISTS bill_reminders (
        bill_id INT,
        bill_name VARCHAR(100),
        due_date DATE,
        amount DECIMAL(12,2),
        days_left INT,
        urgency_level VARCHAR(20)
    );
    
    OPEN bill_cursor;
    
    bill_loop: LOOP
        FETCH bill_cursor INTO bill_id_val, bill_name_val, due_date_val, amount_val;
        IF done THEN
            LEAVE bill_loop;
        END IF;
        
        SET days_left = DATEDIFF(due_date_val, CURDATE());
        
        INSERT INTO bill_reminders VALUES 
            (bill_id_val, bill_name_val, due_date_val, amount_val, days_left,
             CASE 
                 WHEN days_left <= 0 THEN 'Overdue'
                 WHEN days_left <= 2 THEN 'Urgent'
                 WHEN days_left <= 5 THEN 'Soon'
                 ELSE 'Upcoming'
             END);
    END LOOP;
    
    CLOSE bill_cursor;
    
    -- Return the reminders
    SELECT * FROM bill_reminders ORDER BY days_left ASC;
    
    DROP TEMPORARY TABLE bill_reminders;
END//
DELIMITER ;

-- Procedure to analyze spending patterns using cursor
DELIMITER //
CREATE PROCEDURE analyze_spending_patterns(IN p_user_id INT, IN p_months INT)
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE category_name_val VARCHAR(100);
    DECLARE total_spent_val DECIMAL(12,2);
    DECLARE transaction_count_val INT;
    DECLARE avg_amount_val DECIMAL(12,2);
    
    -- Cursor for category-wise spending
    DECLARE spending_cursor CURSOR FOR 
        SELECT 
            c.category_name,
            SUM(t.amount) as total_spent,
            COUNT(t.transaction_id) as transaction_count,
            AVG(t.amount) as avg_amount
        FROM transactions t
        JOIN categories c ON t.category_id = c.category_id
        WHERE t.user_id = p_user_id 
        AND t.transaction_type = 'expense'
        AND t.transaction_date >= DATE_SUB(CURDATE(), INTERVAL p_months MONTH)
        GROUP BY c.category_id, c.category_name
        ORDER BY total_spent DESC;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    -- Create temporary table for analysis
    CREATE TEMPORARY TABLE IF NOT EXISTS spending_analysis (
        category_name VARCHAR(100),
        total_spent DECIMAL(12,2),
        transaction_count INT,
        avg_amount DECIMAL(12,2),
        spending_percentage DECIMAL(5,2),
        frequency_level VARCHAR(20)
    );
    
    OPEN spending_cursor;
    
    spending_loop: LOOP
        FETCH spending_cursor INTO category_name_val, total_spent_val, transaction_count_val, avg_amount_val;
        IF done THEN
            LEAVE spending_loop;
        END IF;
        
        INSERT INTO spending_analysis VALUES 
            (category_name_val, total_spent_val, transaction_count_val, avg_amount_val, 0,
             CASE 
                 WHEN transaction_count_val >= 20 THEN 'Very High'
                 WHEN transaction_count_val >= 10 THEN 'High'
                 WHEN transaction_count_val >= 5 THEN 'Medium'
                 ELSE 'Low'
             END);
    END LOOP;
    
    CLOSE spending_cursor;
    
    -- Calculate percentages
    UPDATE spending_analysis 
    SET spending_percentage = (total_spent / (SELECT SUM(total_spent) FROM spending_analysis)) * 100;
    
    -- Return the analysis
    SELECT * FROM spending_analysis ORDER BY total_spent DESC;
    
    DROP TEMPORARY TABLE spending_analysis;
END//
DELIMITER ;

-- ==================== INDEXES ====================

-- Additional indexes for better performance
CREATE INDEX idx_transactions_user_date ON transactions(user_id, transaction_date);
CREATE INDEX idx_transactions_category_date ON transactions(category_id, transaction_date);
CREATE INDEX idx_bills_user_due_date ON bills(user_id, due_date);
CREATE INDEX idx_goals_user_status ON goals(user_id, status);
CREATE INDEX idx_budgets_user_period ON budgets(user_id, period_month, period_year);
CREATE INDEX idx_audit_log_user_date ON audit_log(user_id, changed_at);
CREATE INDEX idx_financial_insights_user_period ON financial_insights(user_id, insight_year, insight_month);

-- ==================== SAMPLE DATA ====================

-- Insert sample account types
INSERT INTO account_types (type_name) VALUES 
('Savings'), ('Checking'), ('Credit Card'), ('Investment'), ('Cash'), ('Other');

-- Insert default categories
INSERT INTO categories (category_name, category_type, is_default, tags, color_code) VALUES
('Salary', 'income', TRUE, 'essential', '#28a745'),
('Freelance', 'income', TRUE, 'business', '#17a2b8'),
('Investment Returns', 'income', TRUE, 'investment', '#ffc107'),
('Food & Dining', 'expense', TRUE, 'essential', '#dc3545'),
('Transportation', 'expense', TRUE, 'essential', '#6c757d'),
('Shopping', 'expense', TRUE, 'discretionary', '#e83e8c'),
('Entertainment', 'expense', TRUE, 'lifestyle', '#6610f2'),
('Healthcare', 'expense', TRUE, 'health', '#20c997'),
('Education', 'expense', TRUE, 'education', '#fd7e14'),
('Utilities', 'expense', TRUE, 'essential', '#6f42c1');
