USE pfms_db;

INSERT INTO users (name, email, password_hash) VALUES
('Aarav Sharma', 'aarav@example.com', 'pbkdf2:sha256:600000$dummy$hash');

INSERT INTO accounts (user_id, account_name, account_type, balance) VALUES
(1, 'HDFC Savings', 'savings', 50000.00),
(1, 'Cash Wallet', 'cash', 3000.00);

INSERT INTO categories (category_name, category_type, is_default) VALUES
('Salary', 'income', TRUE),
('Freelance', 'income', TRUE),
('Food', 'expense', TRUE),
('Transport', 'expense', TRUE),
('Utilities', 'expense', TRUE),
('Entertainment', 'expense', TRUE);

INSERT INTO transactions (user_id, account_id, category_id, transaction_type, amount, transaction_date, description) VALUES
(1, 1, 1, 'income', 80000.00, '2026-01-01', 'Monthly salary'),
(1, 1, 2, 'income', 15000.00, '2026-01-08', 'Freelance payment'),
(1, 2, 3, 'expense', 500.00, '2026-01-02', 'Lunch'),
(1, 2, 4, 'expense', 250.00, '2026-01-03', 'Metro card recharge'),
(1, 1, 5, 'expense', 3000.00, '2026-01-05', 'Electricity bill'),
(1, 1, 6, 'expense', 2000.00, '2026-01-10', 'Movie and dinner');

INSERT INTO budgets (user_id, category_id, period_month, period_year, limit_amount) VALUES
(1, NULL, 1, 2026, 30000.00),
(1, 3, 1, 2026, 6000.00),
(1, 6, 1, 2026, 4000.00);

INSERT INTO goals (user_id, goal_name, target_amount, current_amount, deadline, status) VALUES
(1, 'Emergency Fund', 200000.00, 60000.00, '2026-12-31', 'active'),
(1, 'Vacation Trip', 100000.00, 25000.00, '2026-09-30', 'active');

INSERT INTO bills (user_id, bill_name, amount, due_date, recurrence, status) VALUES
(1, 'Internet Bill', 999.00, '2026-01-15', 'monthly', 'pending'),
(1, 'Credit Card', 8500.00, '2026-01-20', 'monthly', 'pending');

INSERT INTO financial_insights (
    user_id, insight_month, insight_year, total_income, total_expense, savings,
    savings_consistency_score, overspending_flag, generated_message
) VALUES
(1, 1, 2026, 95000.00, 5750.00, 89250.00, 93.95, FALSE, 'Your savings are improving');
