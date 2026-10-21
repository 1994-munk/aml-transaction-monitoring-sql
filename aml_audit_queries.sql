-- ====================================================================
-- Core Analytical SQL Queries for Financial Crime Detection
-- ====================================================================

-- -----------------------------------------------------------------
-- QUERY 1: Structuring (Smurfing) Detection
-- Objective: Flag accounts executing multiple high-value transfers 
-- just below the $10,000 regulatory reporting threshold within 48 hours.
-- -----------------------------------------------------------------
WITH suspicious_threshold_transfers AS (
    SELECT 
        source_account_id,
        transaction_id,
        amount,
        executed_at,
        COUNT(*) OVER (
            PARTITION BY source_account_id 
            ORDER BY executed_at 
            RANGE BETWEEN INTERVAL '48 hours' PRECEDING AND CURRENT ROW
        ) as cluster_count
    FROM transactions
    WHERE amount BETWEEN 9000.00 AND 9999.99
    AND status = 'completed'
)
SELECT 
    a.customer_name,
    t.source_account_id,
    COUNT(t.transaction_id) as near_threshold_count,
    SUM(t.amount) as total_flagged_volume,
    MIN(t.executed_at) as window_start,
    MAX(t.executed_at) as window_end
FROM suspicious_threshold_transfers t
JOIN accounts a ON t.source_account_id = a.account_id
GROUP BY t.source_account_id, a.customer_name
HAVING COUNT(t.transaction_id) >= 3;


-- -----------------------------------------------------------------
-- QUERY 2: Rapid Velocity & Layering Check (Using Window Functions)
-- Objective: Detect accounts that receive funds and transfer them out 
-- to another destination within a 30-minute window (Layering behavior).
-- -----------------------------------------------------------------
WITH account_timeline AS (
    SELECT 
        transaction_id,
        source_account_id as active_account,
        destination_account_id,
        amount,
        executed_at,
        LEAD(executed_at) OVER (PARTITION BY source_account_id ORDER BY executed_at) as next_transaction_time,
        LEAD(amount) OVER (PARTITION BY source_account_id ORDER BY executed_at) as next_amount
    FROM transactions
)
SELECT 
    active_account,
    transaction_id as outgoing_tx_id,
    amount as outgoing_amount,
    executed_at as outflow_time,
    next_transaction_time as inflow_time,
    EXTRACT(EPOCH FROM (next_transaction_time - executed_at)) / 60 as time_gap_minutes
FROM account_timeline
WHERE next_transaction_time IS NOT NULL
  AND (next_transaction_time - executed_at) <= INTERVAL '30 minutes';


-- -----------------------------------------------------------------
-- QUERY 3: Account Behavioral Outlier Analysis
-- Objective: Calculate standard deviation of transaction amounts per 
-- account to isolate anomalies exceeding 2.5 standard deviations.
-- -----------------------------------------------------------------
WITH account_stats AS (
    SELECT 
        source_account_id,
        AVG(amount) as avg_amount,
        STDDEV(amount) as stddev_amount
    FROM transactions
    GROUP BY source_account_id
)
SELECT 
    t.transaction_id,
    t.source_account_id,
    a.customer_name,
    t.amount,
    s.avg_amount,
    ROUND(((t.amount - s.avg_amount) / NULLIF(s.stddev_amount, 0)), 2) as z_score
FROM transactions t
JOIN account_stats s ON t.source_account_id = s.source_account_id
JOIN accounts a ON t.source_account_id = a.account_id
WHERE s.stddev_amount > 0 
  AND ABS((t.amount - s.avg_amount) / s.stddev_amount) > 2.0;
