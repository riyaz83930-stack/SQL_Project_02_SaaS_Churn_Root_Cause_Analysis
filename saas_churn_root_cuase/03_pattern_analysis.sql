-- : Churn Signal Discovery (core-finding)
-- ═══════════════════════════════════════


DROP view user_usage_log;

CREATE VIEW user_usage_log AS 
SELECT
	u.user_id,
    TRIM(u.name) AS name,
    TRIM(LOWER(u.status)) AS status,
    ul.usage_id,
    ul.usage_date,
    ul.feature_used,
    ul.session_duration_minutes,
    s.subscription_id,
    s.start_date,
    s.end_date,
    s.status AS sub_satatus
FROM users u
JOIN usage_logs ul
	ON u.user_id=ul.user_id
JOIN subscriptions s
	ON u.user_id=s.user_id
    AND ul.usage_date>=s.start_date 
    AND(
		s.end_date IS NULL
        OR
        ul.usage_date<=s.end_date
        )
    
    ;
    
-- CALCULATING LAST 45 DAYS AVG USAGE FOR CHURNED USER
-- DROP view churned_user_usage_behaviour ;
CREATE VIEW 
churned_user_usage_behaviour AS 
WITH 
daily_usage AS 
			   (
				SELECT 
					user_id,
					usage_date,
					status,
					SUM(session_duration_minutes) AS daily_usage
				FROM user_usage_log
				GROUP BY 
					user_id,
					status,
					usage_date
				)
 ,churned_dates AS 
				(
                SELECT 
                user_id,
                MAX(end_date) AS churned_date
                FROM user_usage_log
                WHERE end_date IS NOT NULL 
                GROUP BY user_id
                )
,churned_merge AS 
				(
                SELECT
					d.user_id,
                    d.daily_usage,
                    d.status,
                    d.usage_date,
                    c.churned_date
                FROM daily_usage d
                JOIN churned_dates c
					ON d.user_id=c.user_id
                    AND d.status='churned'
                )
,churned_analysis AS 
				(
                SELECT 
					user_id,
                    AVG(daily_usage) AS lifetime_avg_usage,
                    AVG(
						CASE 
							WHEN usage_date BETWEEN (DATE_SUB(churned_date,INTERVAL 45 DAY)) AND churned_date THEN daily_usage
                        END
                        ) AS last_45_day_avg_usage,
					MAX(churned_date) AS churned_date
					
                FROM churned_merge
                GROUP BY user_id
                )
                
	SELECT 
		user_id,
		ROUND(lifetime_avg_usage,2) AS lifetime_avg_usage,
		ROUND(last_45_day_avg_usage,2) AS last_45_day_avg_usage,
		ROUND(((last_45_day_avg_usage-lifetime_avg_usage)/lifetime_avg_usage*100),2) AS pct_change,
		CASE
			WHEN last_45_day_avg_usage< lifetime_avg_usage THEN 'Usage Drop'
			ELSE 'Usage Increase'
		END AS pattern_notice,
        churned_date
	FROM churned_analysis
			
	ORDER BY  pct_change
       
;

-- SELECT
-- *
-- FROM churned_user_usage_behaviour;

CREATE VIEW churned_user_ticket AS 
SELECT
	user_id,
    COUNT(DISTINCT (ticket_id)) AS tickets
FROM 
(
SELECT
	c.*,
	s.ticket_id,
	s.ticket_date
FROM support_tickets s
RIGHT JOIN churned_user_usage_behaviour c
						ON s.user_id=c.user_id
                        AND s.priority='High'
                        AND s.ticket_date BETWEEN (DATE_SUB(c.churned_date ,INTERVAL 30 DAY)) AND c.churned_date
                        AND(
							s.status!='Resolved'
                            OR
                            s.resolved_date IS NULL 
                            )
					
					ORDER BY c.user_id
                    )t
GROUP BY user_id;


CREATE VIEW churned_user_failed_payment AS 

SELECT
	c.user_id,
    COUNT(DISTINCT(payment_id)) AS payment
FROM payment_history ph
RIGHT JOIN churned_user_usage_behaviour c
	ON ph.user_id=c.user_id
    AND ph.status='Failed'
    AND payment_date BETWEEN (DATE_SUB(c.churned_date,INTERVAL 1 MONTH)) AND c.churned_date
GROUP BY c.user_id;

 -- FINAL ANALYSIS
 
CREATE VIEW  churned_user_analysis AS 
SELECT
	b.*,
    t.tickets AS within_30_day_high_priority_unresolved_ticket,
    p.payment AS failed_payment_within_30_day,
    CASE
		WHEN b.pattern_notice='Usage Drop' AND t.tickets>0 AND p.payment>0 THEN 'Drop-UnresolvedTicket-FailedPayment'
        WHEN b.pattern_notice='Usage Increase' AND t.tickets >0 AND p.payment >0 THEN 'Increase-UnresolvedTicket-FailedPayment'
        WHEN b.pattern_notice='Usage Drop' AND (t.tickets>0 AND p.payment <=0) THEN 'Drop - with unresolved ticket'
        WHEN b.pattern_notice='Usage Drop' AND (t.tickets <=0 AND p.payment>0) THEN 'Drop - with failed payment'
        WHEN b.pattern_notice='Usage Increase' AND (t.tickets>0 AND p.payment <1) THEN 'increase-with unresolved ticket'
        WHEN b.pattern_notice='Usage Increase' AND (t.tickets <=0 AND p.payment>0) THEN 'Increase - with failed payment'
        WHEN b.pattern_notice='Usage Drop'  THEN 'Drop Only'
		WHEN b.pattern_notice='Usage Increase'  THEN 'Increase Only'
    END AS category
FROM churned_user_usage_behaviour b
JOIN churned_user_ticket t
	ON b.user_id=t.user_id
JOIN churned_user_failed_payment p
	ON b.user_id=p.user_id
    ;
    
    

-- CALCULATING AVG USAGE BEHAVIOUR FOR ACTIVE USERS 



-- DROP view active_user_usage_behaviour;
CREATE VIEW 
active_user_usage_behaviour AS
 
WITH 
daily_usage AS 
			   (
				SELECT 
					user_id,
					usage_date,
					status,
					SUM(session_duration_minutes) AS daily_usage
				FROM user_usage_log
				GROUP BY 
					user_id,
					status,
					usage_date
				)
,active_analysis AS 
				(
                SELECT 
					user_id,
                    AVG(daily_usage) AS lifetime_avg_usage,
                    AVG(
						CASE 
							WHEN usage_date BETWEEN (DATE_SUB('2026-09-15',INTERVAL 45 DAY)) AND '2026-09-15' THEN daily_usage
                        END
                        ) AS last_45_day_avg_usage,
					'2026-09-15' AS churned_date
					
                FROM daily_usage
                GROUP BY user_id
                )
                
	SELECT 
		user_id,
		ROUND(lifetime_avg_usage,2) AS lifetime_avg_usage,
		ROUND(last_45_day_avg_usage,2) AS last_45_day_avg_usage,
		ROUND(((last_45_day_avg_usage-lifetime_avg_usage)/lifetime_avg_usage*100),2) AS pct_change,
		CASE
			WHEN last_45_day_avg_usage< lifetime_avg_usage THEN 'Usage Drop'
			ELSE 'Usage Increase'
		END AS pattern_notice,
        churned_date
	FROM active_analysis
			
	ORDER BY  pct_change
       
;

-- SELECT
-- *
-- FROM active_user_usage_behaviour;

-- DROP view active_user_ticket;

CREATE VIEW active_user_ticket AS 
SELECT
	user_id,
    COUNT(DISTINCT (ticket_id)) AS tickets
FROM 
(
SELECT
	c.*,
	s.ticket_id,
	s.ticket_date
FROM support_tickets s
RIGHT JOIN active_user_usage_behaviour c
						ON s.user_id=c.user_id
                        AND s.priority='High'
                        AND s.ticket_date BETWEEN (DATE_SUB(c.churned_date ,INTERVAL 30 DAY)) AND c.churned_date
                        AND(
							s.status!='Resolved'
                            OR
                            s.resolved_date IS NULL 
                            )
					
					ORDER BY c.user_id
                    )t
GROUP BY user_id;


-- DROP view active_user_failed_payment;
CREATE VIEW active_user_failed_payment AS 

SELECT
	c.user_id,
    COUNT(DISTINCT(payment_id)) AS payment
FROM payment_history ph
RIGHT JOIN active_user_usage_behaviour c
	ON ph.user_id=c.user_id
    AND ph.status='Failed'
    AND payment_date BETWEEN (DATE_SUB(c.churned_date,INTERVAL 1 MONTH)) AND c.churned_date
GROUP BY c.user_id;


 -- FINAL ANALYSIS
 
 
 -- DROP view active_user_analysis;
 
CREATE VIEW active_user_analysis AS  
SELECT
	b.*,
    t.tickets AS within_30_day_high_priority_unresolved_ticket,
    p.payment AS failed_payment_within_30_day,
    CASE
		WHEN b.pattern_notice='Usage Drop' AND t.tickets>0 AND p.payment>0 THEN 'Drop-UnresolvedTicket-FailedPayment'
        WHEN b.pattern_notice='Usage Increase' AND t.tickets >0 AND p.payment >0 THEN 'Increase-UnresolvedTicket-FailedPayment'
        WHEN b.pattern_notice='Usage Drop' AND (t.tickets>0 AND p.payment <=0) THEN 'Drop - with unresolved ticket'
        WHEN b.pattern_notice='Usage Drop' AND (t.tickets <=0 AND p.payment>0) THEN 'Drop - with failed payment'
        WHEN b.pattern_notice='Usage Increase' AND (t.tickets>0 AND p.payment <=0) THEN 'increase-with unresolved ticket'
        WHEN b.pattern_notice='Usage Increase' AND (t.tickets <=0 AND p.payment>0) THEN 'Increase - with failed payment'
        WHEN b.pattern_notice='Usage Drop'  THEN 'Drop Only'
		WHEN b.pattern_notice='Usage Increase'  THEN 'Increase Only'
    END AS category
FROM active_user_usage_behaviour b
JOIN active_user_ticket t
	ON b.user_id=t.user_id
JOIN active_user_failed_payment p
	ON b.user_id=p.user_id;
    
-- REPORT
SELECT
	*,
    ROUND((churned_category_count/(SELECT COUNT(*) FROM churned_user_analysis)*100),2) AS pct_contribution
FROM 
(
SELECT
	category,
    COUNT(*) AS churned_category_count
FROM churned_user_analysis
GROUP BY category 
)t
ORDER BY pct_contribution DESC
;
SELECT
	*,
    ROUND((active_category_count/(SELECT COUNT(*) FROM active_user_analysis)*100),2) AS pct_contribution
FROM 
(SELECT
	category,
    COUNT(*) AS active_category_count
FROM active_user_analysis
GROUP BY category
)t
ORDER BY pct_contribution DESC;



SELECT
*
FROM churned_user_analysis;

SELECT
*
FROM active_user_analysis;



-- USER DROP ANALYSIS


SELECT
	CASE
		WHEN pct_change <0 AND pct_change >=-10 THEN '0-10% drop'
        WHEN pct_change <-11 AND pct_change >=-20 THEN '10-20% drop'
        WHEN pct_change <-21 AND pct_change >=-30 THEN '20-30% drop'
        WHEN pct_change <-31 AND pct_change>=-40 THEN '30-40% drop'
        WHEN pct_change <-41 AND pct_change >=-50 THEN '40-50% drop'
        WHEN pct_change <-50   THEN 'Severe (>50%) drop'
        ELSE NULL 
    END AS bucket,
    COUNT(user_id) AS churned_user_in
FROM churned_user_analysis
GROUP BY  CASE
		WHEN pct_change <0 AND pct_change >=-10 THEN '0-10% drop'
        WHEN pct_change <-11 AND pct_change >=-20 THEN '10-20% drop'
        WHEN pct_change <-21 AND pct_change >=-30 THEN '20-30% drop'
        WHEN pct_change <-31 AND pct_change>=-40 THEN '30-40% drop'
        WHEN pct_change <-41 AND pct_change >=-50 THEN '40-50% drop'
        WHEN pct_change <-50   THEN 'Severe (>50%) drop'
        ELSE NULL 
    END 





;

SELECT
	CASE
		WHEN pct_change <0 AND pct_change >=-10 THEN '0-10% drop'
        WHEN pct_change <-11 AND pct_change >=-20 THEN '10-20% drop'
        WHEN pct_change <-21 AND pct_change >=-30 THEN '20-30% drop'
        WHEN pct_change <-31 AND pct_change>=-40 THEN '30-40% drop'
        WHEN pct_change <-41 AND pct_change >=-50 THEN '40-50% drop'
        WHEN pct_change <-50   THEN 'Severe (>50%) drop'
        ELSE NULL 
    END AS bucket,
    COUNT(user_id) AS active_user_in
FROM active_user_analysis
GROUP BY  CASE
		WHEN pct_change <0 AND pct_change >=-10 THEN '0-10% drop'
        WHEN pct_change <-11 AND pct_change >=-20 THEN '10-20% drop'
        WHEN pct_change <-21 AND pct_change >=-30 THEN '20-30% drop'
        WHEN pct_change <-31 AND pct_change>=-40 THEN '30-40% drop'
        WHEN pct_change <-41 AND pct_change >=-50 THEN '40-50% drop'
        WHEN pct_change <-50   THEN 'Severe (>50%) drop'
        ELSE NULL 
    END 




