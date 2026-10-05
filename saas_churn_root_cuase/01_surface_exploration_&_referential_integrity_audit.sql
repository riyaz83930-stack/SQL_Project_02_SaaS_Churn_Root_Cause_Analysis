

-- Row counts
SELECT 'users' AS table_name, COUNT(*) AS row_count FROM users
UNION ALL
SELECT 'subscriptions', COUNT(*) FROM subscriptions
UNION ALL
SELECT 'usage_logs', COUNT(*) FROM usage_logs
UNION ALL
SELECT 'support_tickets', COUNT(*) FROM support_tickets
UNION ALL
SELECT 'payment_history', COUNT(*) FROM payment_history;


-- Users NULL audit
SELECT
    'users' AS table_name,
    SUM(user_id IS NULL) AS user_id_nulls,
    ROUND(SUM(user_id IS NULL) / COUNT(*) * 100, 2) AS user_id_null_pct,
    SUM(name IS NULL) AS name_nulls,
    ROUND(SUM(name IS NULL) / COUNT(*) * 100, 2) AS name_null_pct,
    SUM(email IS NULL) AS email_nulls,
    ROUND(SUM(email IS NULL) / COUNT(*) * 100, 2) AS email_null_pct,
    SUM(signup_date IS NULL) AS signup_date_nulls,
    ROUND(SUM(signup_date IS NULL) / COUNT(*) * 100, 2) AS signup_date_null_pct,
    SUM(plan_type IS NULL) AS plan_type_nulls,
    ROUND(SUM(plan_type IS NULL) / COUNT(*) * 100, 2) AS plan_type_null_pct,
    SUM(status IS NULL) AS status_nulls,
    ROUND(SUM(status IS NULL) / COUNT(*) * 100, 2) AS status_null_pct
FROM users;


-- Subscription NULL audit
SELECT
    'subscriptions' AS table_name,
    SUM(subscription_id IS NULL) AS subscription_id_nulls,
    ROUND(SUM(subscription_id IS NULL) / COUNT(*) * 100, 2) AS subscription_id_null_pct,
    SUM(user_id IS NULL) AS user_id_nulls,
    ROUND(SUM(user_id IS NULL) / COUNT(*) * 100, 2) AS user_id_null_pct,
    SUM(plan_name IS NULL) AS plan_name_nulls,
    ROUND(SUM(plan_name IS NULL) / COUNT(*) * 100, 2) AS plan_name_null_pct,
    SUM(start_date IS NULL) AS start_date_nulls,
    ROUND(SUM(start_date IS NULL) / COUNT(*) * 100, 2) AS start_date_null_pct,
    SUM(end_date IS NULL) AS end_date_nulls,
    ROUND(SUM(end_date IS NULL) / COUNT(*) * 100, 2) AS end_date_null_pct,
    SUM(monthly_amount IS NULL) AS monthly_amount_nulls,
    ROUND(SUM(monthly_amount IS NULL) / COUNT(*) * 100, 2) AS monthly_amount_null_pct,
    SUM(status IS NULL) AS status_nulls,
    ROUND(SUM(status IS NULL) / COUNT(*) * 100, 2) AS status_null_pct
FROM subscriptions;


-- Usage NULL audit
SELECT
    'usage_logs' AS table_name,
    SUM(usage_id IS NULL) AS usage_id_nulls,
    ROUND(SUM(usage_id IS NULL) / COUNT(*) * 100, 2) AS usage_id_null_pct,
    SUM(user_id IS NULL) AS user_id_nulls,
    ROUND(SUM(user_id IS NULL) / COUNT(*) * 100, 2) AS user_id_null_pct,
    SUM(usage_date IS NULL) AS usage_date_nulls,
    ROUND(SUM(usage_date IS NULL) / COUNT(*) * 100, 2) AS usage_date_null_pct,
    SUM(feature_used IS NULL) AS feature_used_nulls,
    ROUND(SUM(feature_used IS NULL) / COUNT(*) * 100, 2) AS feature_used_null_pct,
    SUM(session_duration_minutes IS NULL) AS session_duration_nulls,
    ROUND(SUM(session_duration_minutes IS NULL) / COUNT(*) * 100, 2) AS session_duration_null_pct
FROM usage_logs;


-- Support NULL audit
SELECT
    'support_tickets' AS table_name,
    SUM(ticket_id IS NULL) AS ticket_id_nulls,
    ROUND(SUM(ticket_id IS NULL) / COUNT(*) * 100, 2) AS ticket_id_null_pct,
    SUM(user_id IS NULL) AS user_id_nulls,
    ROUND(SUM(user_id IS NULL) / COUNT(*) * 100, 2) AS user_id_null_pct,
    SUM(ticket_date IS NULL) AS ticket_date_nulls,
    ROUND(SUM(ticket_date IS NULL) / COUNT(*) * 100, 2) AS ticket_date_null_pct,
    SUM(category IS NULL) AS category_nulls,
    ROUND(SUM(category IS NULL) / COUNT(*) * 100, 2) AS category_null_pct,
    SUM(priority IS NULL) AS priority_nulls,
    ROUND(SUM(priority IS NULL) / COUNT(*) * 100, 2) AS priority_null_pct,
    SUM(status IS NULL) AS status_nulls,
    ROUND(SUM(status IS NULL) / COUNT(*) * 100, 2) AS status_null_pct,
    SUM(resolved_date IS NULL) AS resolved_date_nulls,
    ROUND(SUM(resolved_date IS NULL) / COUNT(*) * 100, 2) AS resolved_date_null_pct
FROM support_tickets;


-- Payment NULL audit
SELECT
    'payment_history' AS table_name,
    SUM(payment_id IS NULL) AS payment_id_nulls,
    ROUND(SUM(payment_id IS NULL) / COUNT(*) * 100, 2) AS payment_id_null_pct,
    SUM(user_id IS NULL) AS user_id_nulls,
    ROUND(SUM(user_id IS NULL) / COUNT(*) * 100, 2) AS user_id_null_pct,
    SUM(payment_date IS NULL) AS payment_date_nulls,
    ROUND(SUM(payment_date IS NULL) / COUNT(*) * 100, 2) AS payment_date_null_pct,
    SUM(amount IS NULL) AS amount_nulls,
    ROUND(SUM(amount IS NULL) / COUNT(*) * 100, 2) AS amount_null_pct,
    SUM(status IS NULL) AS status_nulls,
    ROUND(SUM(status IS NULL) / COUNT(*) * 100, 2) AS status_null_pct
FROM payment_history;


-- Churn status
SELECT
    status,
    COUNT(*) AS user_count,
    ROUND(COUNT(*) / (SELECT COUNT(*) FROM users) * 100, 2) AS user_pct
FROM users
GROUP BY status;


-- Invalid amounts
SELECT
    'subscriptions.monthly_amount' AS column_name,
    COUNT(*) AS invalid_rows
FROM subscriptions
WHERE monthly_amount <= 0

UNION ALL

SELECT
    'usage_logs.session_duration_minutes',
    COUNT(*)
FROM usage_logs
WHERE session_duration_minutes <= 0

UNION ALL

SELECT
    'payment_history.amount',
    COUNT(*)
FROM payment_history
WHERE amount <= 0;


-- Distinct text values
SELECT DISTINCT status FROM users;

SELECT DISTINCT plan_type FROM users;

SELECT DISTINCT plan_name FROM subscriptions;

SELECT DISTINCT status FROM subscriptions;

SELECT DISTINCT feature_used FROM usage_logs;

SELECT DISTINCT category FROM support_tickets;

SELECT DISTINCT priority FROM support_tickets;

SELECT DISTINCT status FROM support_tickets;

SELECT DISTINCT status FROM payment_history;