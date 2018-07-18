/*Find User Segments*/
SELECT DISTINCT segment
FROM subscriptions;*/


/* Find Company operations span and determine what months can we calculate churn*/
SELECT MIN(subscription_start), MAX(subscription_start), MIN(subscription_end), MAX(subscription_end)
FROM subscriptions;*/

/*temp table to compare months with subscription dates*/
 WITH months AS 
 (SELECT '1' AS month, '2017-01-01'as first_day, '2017-01-31'as last_day
  UNION
  SELECT '2' AS month,'2017-02-01'as first_day, '2017-02-28'as last_day
  UNION
  SELECT '3' AS month,'2017-03-01'as first_day, '2017-03-31'as last_day
 ),
 
 cross_join AS 
 ( SELECT *
  FROM months
  CROSS JOIN
 subscriptions
 ),
 /*temp table to give every user in every month a status by segment*/
 status AS 
 (
 SELECT id, first_day AS month, subscription_start, subscription_end,
 CASE
  WHEN (subscription_start < first_day) AND (segment = 87) THEN 1
   ELSE 0
  END is_active_87,
CASE
  WHEN (subscription_end BETWEEN first_day AND last_day) AND (segment = 87) THEN 1
   ELSE 0
  END is_cancelled_87,
CASE
 WHEN (subscription_start < first_day) AND (segment = 30) THEN 1
   ELSE 0
  END is_active_30,
CASE
 WHEN (subscription_end BETWEEN first_day AND last_day) AND (segment = 30) THEN 1
   ELSE 0
  END is_cancelled_30
 FROM cross_join             
 ),
 /* temp table to calculate raw numbers of active users and cancellations for each month*/
 status_aggregate_monthly AS (
 SELECT month, SUM(is_active_87) AS sum_active_87, SUM(is_active_30) AS sum_active_30, SUM(is_cancelled_87) AS sum_cancelled_87, SUM(is_cancelled_30) AS sum_cancelled_30
 FROM status
 GROUP BY month),
 
/* temp table to calculate churn for each month*/
all_segment_monthly_churn AS (
SELECT month, ((1.0 * sum_cancelled_87 +sum_cancelled_30) / (sum_active_87 + sum_active_30)) AS churn_rate_all_segments
FROM status_aggregate_monthly                                                                                               
),

/* query data to get overall churn rates*/
SELECT *
FROM all_segment_monthly_churn;


/*calculate churn for each month by segment*/
monthly_churn_by_segment AS (
SELECT month, sum_active_87 AS active_users_87, sum_cancelled_87 AS cancellations_87, (1.0 * sum_cancelled_87 / sum_active_87) AS churn_87, sum_active_30 AS active_users_30, sum_cancelled_30 AS cancellations_30, (1.0 * sum_cancelled_30 / sum_active_30) AS churn_30 
 FROM status_aggregate_monthly)
 
 /*query data to compare churns between segments month by month*/
 SELECT month, churn_87, churn_30
 FROM monthly_churn_by_segment
 ORDER BY month ASC;
 
 /* BONUS question in project, use this query to calculate churn for any given time period*/
SELECT month, churn_87, churn_30
FROM monthly_churn_by_segment
WHERE month BETWEEN '2017-01-01' AND '2017-03-01';
ORDER BY month ASC;
 