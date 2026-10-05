--  Date-Logic Audit

-- 11. Kitne usage_logs aise hain jinki usage_date, us-user ke subscription end_date ke baad ki hai (impossible — cancel hone ke baad usage kaise).
-- 12. Kitne payments aise hain jinka payment_date, user ke signup_date se pehle ka hai.

-- Finding usage after subscription ended

-- Valid subscription -- Invalid usage records
SELECT
    ul.user_id,
    ul.usage_date,
    ul.feature_used,
    ul.session_duration_minutes
FROM usage_logs ul
WHERE NOT EXISTS (
    SELECT 1
    FROM subscriptions s
    WHERE s.user_id = ul.user_id
      AND ul.usage_date >= s.start_date
      AND (
          s.end_date IS NULL
          OR ul.usage_date <= s.end_date
      )
);
-- Counting how many time user actived after subscription ended 


-- Invalid usage records
SELECT
   count(*)
FROM usage_logs ul
WHERE NOT EXISTS (
    SELECT 1
    FROM subscriptions s
    WHERE s.user_id = ul.user_id
      AND ul.usage_date >= s.start_date
      AND (
          s.end_date IS NULL
          OR ul.usage_date <= s.end_date
      )
);

-- Finding payments done before signup date 

SELECT
	ph.*,
    u.signup_date
FROM payment_history ph
JOIN users u
	ON ph.user_id=u.user_id
    AND ph.status='success'
WHERE ph.payment_date < u.signup_date;


SELECT
count(*)
FROM payment_history ph
JOIN users u
	ON ph.user_id=u.user_id
    AND ph.status='success'
WHERE ph.payment_date < u.signup_date