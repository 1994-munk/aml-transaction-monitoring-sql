-- ====================================================================
-- Project: AML Transaction Monitoring SQL Engine
-- Description: DDL Schema creation and sample data seed for audit analytics
-- ====================================================================

-- Drop tables if they exist for clean re-runs
DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS accounts CASCADE;

-- Create accounts table
CREATE TABLE accounts (
    account_id SERIAL PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    account_tier VARCHAR(20) DEFAULT 'standard',
    country_code VARCHAR(3) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create transactions table
CREATE TABLE transactions (
    transaction_id SERIAL PRIMARY KEY,
    source_account_id INT REFERENCES accounts(account_id),
    destination_account_id INT REFERENCES accounts(account_id),
    amount NUMERIC(12, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    transaction_type VARCHAR(30) NOT NULL, -- e.g., 'wire', 'pos', 'p2p'
    status VARCHAR(20) DEFAULT 'completed',
    risk_score NUMERIC(5, 2) DEFAULT 0.00,
    executed_at TIMESTAMP NOT NULL
);

-- Optimization: Create indexes on high-frequency filter and join columns
CREATE INDEX idx_transactions_source ON transactions(source_account_id);
CREATE INDEX idx_transactions_timestamp ON transactions(executed_at);
CREATE INDEX idx_transactions_amount ON transactions(amount);

-- Seed Sample Data
INSERT INTO accounts (customer_name, account_tier, country_code) VALUES
('Alice Mwangi', 'premium', 'KE'),
('Bob Smith', 'standard', 'GB'),
('Charlie Ochieng', 'standard', 'KE'),
('Diana Vance', 'vip', 'US');

INSERT INTO transactions (source_account_id, destination_account_id, amount, transaction_type, executed_at) VALUES
(1, 2, 9500.00, 'wire', '2026-10-01 09:15:00'),
(1, 3, 9800.00, 'wire', '2026-10-01 14:30:00'),
(1, 4, 9900.00, 'wire', '2026-10-02 11:00:00'), -- Smurfing pattern detected
(2, 1, 45000.00, 'p2p', '2026-10-02 12:00:00'),
(2, 3, 44500.00, 'p2p', '2026-10-02 12:10:00'); -- Rapid velocity layering
