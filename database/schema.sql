-- Personal Finance Management System (ER-aligned)
CREATE DATABASE IF NOT EXISTS pfms_db;
USE pfms_db;

CREATE TABLE users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE accounts (
    account_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    account_name VARCHAR(100) NOT NULL,
    account_type VARCHAR(50) NOT NULL,
    balance DECIMAL(12,2) NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_accounts_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

CREATE TABLE categories (
    category_id INT PRIMARY KEY AUTO_INCREMENT,
    category_name VARCHAR(100) NOT NULL,
    category_type ENUM('income', 'expense') NOT NULL,
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT uq_category UNIQUE (category_name, category_type)
);

CREATE TABLE transactions (
    transaction_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    account_id INT NULL,
    category_id INT NULL,
    transaction_type ENUM('income', 'expense') NOT NULL,
    amount DECIMAL(12,2) NOT NULL CHECK (amount > 0),
    transaction_date DATE NOT NULL,
    description VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_txn_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_txn_account FOREIGN KEY (account_id) REFERENCES accounts(account_id) ON DELETE SET NULL,
    CONSTRAINT fk_txn_category FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE SET NULL
);

CREATE TABLE budgets (
    budget_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    category_id INT NULL,
    period_month TINYINT NOT NULL CHECK (period_month BETWEEN 1 AND 12),
    period_year SMALLINT NOT NULL,
    limit_amount DECIMAL(12,2) NOT NULL CHECK (limit_amount > 0),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_budget_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_budget_category FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE SET NULL
);

CREATE TABLE goals (
    goal_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    goal_name VARCHAR(100) NOT NULL,
    target_amount DECIMAL(12,2) NOT NULL CHECK (target_amount > 0),
    current_amount DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK (current_amount >= 0),
    deadline DATE,
    status ENUM('active', 'achieved', 'paused') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_goal_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

CREATE TABLE bills (
    bill_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    bill_name VARCHAR(100) NOT NULL,
    amount DECIMAL(12,2) NOT NULL CHECK (amount > 0),
    due_date DATE NOT NULL,
    recurrence ENUM('weekly', 'monthly', 'yearly') NOT NULL DEFAULT 'monthly',
    status ENUM('pending', 'paid', 'overdue') NOT NULL DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_bill_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);
