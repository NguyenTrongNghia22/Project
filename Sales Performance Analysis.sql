 /*
BUSINESS REQUIREMENT:
 1. TOTAL REVENUE OF SUCCESSFUL TRANSACTIONS.
 2. TOP 3 MONTH WITH FAILED TRANSACTIONS EACH YEAR.
 3. REVENUE OF EACH CATEGORY CONTRIBUTES TO THE TOTAL. 
 4. HOW TOTAL REVENUE CHANGES COMPARING TO THE BEGINNING(1/2019) ?
 5. REVENUE OF EACH MONTH 2019, 2020.
 6. CUSTOMER SEGMENTATION BY TRANSACTION AMOUNT.
 7. CUSTOMER SEGMENTATION BY RFM MODEL. 
 */ 



-- 1. TOTAL REVENUE OF SUCCESSFUL TRANSACTIONS. 
SELECT YEAR(transaction_time) as year,
		MONTH(transaction_time) as month,
		CONCAT(YEAR(transaction_time),'-',MONTH(transaction_time)) as date,
		SUM(charged_amount *1.0) as total_revenue
FROM fact_transaction_2019
WHERE status_id = 1
GROUP BY YEAR(transaction_time),
		MONTH(transaction_time)
UNION 
SELECT YEAR(transaction_time) as year,
		MONTH(transaction_time) as month,
		CONCAT(YEAR(transaction_time),'-',MONTH(transaction_time)) as date,
		SUM(charged_amount *1.0) as total_revenue 
FROM fact_transaction_2020 
WHERE status_id = 1
GROUP BY YEAR(transaction_time),
		MONTH(transaction_time)



-- 2. TOP 3 MONTH WITH FAILED TRANSACTIONS EACH YEAR.
WITH failed_tran as (
	SELECT YEAR(transaction_time) as year,
			MONTH(transaction_time) as month,
			COUNT(transaction_id) as number_failed_trans
	FROM fact_transaction_2019 
	WHERE status_id = 0
	GROUP BY YEAR(transaction_time),
			MONTH(transaction_time)
	UNION 
	SELECT YEAR(transaction_time) as year,
			MONTH(transaction_time) as month,
			COUNT(transaction_id) as number_failed_trans
	FROM fact_transaction_2020
	WHERE status_id = 0 
	GROUP BY YEAR(transaction_time) ,
			MONTH(transaction_time)
)
, rank_tran as (
	SELECT *,
			RANK () OVER (PARTITION BY year ORDER BY number_failed_trans) as rank
	FROM failed_tran
)
SELECT *
FROM rank_tran
WHERE rank < 4 
ORDER BY year, month



-- 3. REVENUE OF EACH CATEGORY CONTRIBUTES TO THE TOTAL OVER TIME: 
WITH category AS
(
    SELECT
        YEAR(transaction_time) AS year
        ,MONTH(transaction_time) AS month
        ,CONCAT(YEAR(transaction_time), '-', MONTH(transaction_time)) AS date 
        ,sce.category 
        ,SUM(1.0*charged_amount) AS total_revenue
    FROM (SELECT * FROM fact_transaction_2019 
			UNION 
		  SELECT * FROM fact_transaction_2020 ) AS fact
    LEFT JOIN dim_scenario AS sce
        ON fact.scenario_id = sce.scenario_id 
    WHERE status_id = 1
    GROUP BY YEAR(transaction_time), MONTH(transaction_time), sce.category 
), category_label AS
(
    SELECT 
        year 
        ,month 
        ,date 
		,total_revenue
        ,SUM(CASE WHEN category = 'Billing' THEN total_revenue ELSE 0 END) AS Billing
        ,SUM(CASE WHEN category = 'Delivery' THEN total_revenue ELSE 0 END) AS Delivery
        ,SUM(CASE WHEN category = 'Entertainment' THEN total_revenue ELSE 0 END) AS Entertainment
        ,SUM(CASE WHEN category = 'FnB' THEN total_revenue ELSE 0 END) AS FnB
        ,SUM(CASE WHEN category = 'Game' THEN total_revenue ELSE 0 END) AS Game
        ,SUM(CASE WHEN category = 'Marketplace' THEN total_revenue ELSE 0 END) AS Marketplace
        ,SUM(CASE WHEN category = 'Movies' THEN total_revenue ELSE 0 END) AS Movies
        ,SUM(CASE WHEN category = 'Not Payment' THEN total_revenue ELSE 0 END) AS [Not_Payment]
        ,SUM(CASE WHEN category = 'Other Services' THEN total_revenue ELSE 0 END) AS [Other_Services]
        ,SUM(CASE WHEN category = 'Shopping' THEN total_revenue ELSE 0 END) AS Shopping
        ,SUM(CASE WHEN category = 'Telco' THEN total_revenue ELSE 0 END) AS Telco
        ,SUM(CASE WHEN category = 'Transportation' THEN total_revenue ELSE 0 END) AS Transportation
        ,SUM(CASE WHEN category = 'Traveling' THEN total_revenue ELSE 0 END) AS Traveling
        ,SUM(CASE WHEN category IS NULL THEN total_revenue ELSE 0 END) AS Unknown 
    FROM category
    GROUP BY year, month, date 
)
SELECT
    year 
    ,month 
    ,date 
    ,FORMAT(Billing / total_revenue, 'p') AS Billing_pct
    ,FORMAT(Delivery / total_revenue, 'p') AS Delivery_pct
    ,FORMAT(Entertainment / total_revenue, 'p') AS Entertainment_pct
    ,FORMAT(FnB / total_revenue, 'p') AS FnB_pct
    ,FORMAT(Game / total_revenue, 'p') AS Game_pct
    ,FORMAT(Marketplace / total_revenue, 'p') AS Marketplace_pct
    ,FORMAT(Movies / total_revenue, 'p') AS Movies_pct
    ,FORMAT(Not_Payment / total_revenue, 'p') AS Not_Payment_pct
    ,FORMAT(Other_Services / total_revenue, 'p') AS Other_Services_pct
    ,FORMAT(Shopping / total_revenue, 'p') AS Shopping_pct
    ,FORMAT(Telco / total_revenue, 'p') AS Telco_pct
    ,FORMAT(Transportation / total_revenue, 'p') AS Transportation_pct
    ,FORMAT(Traveling / total_revenue, 'p') AS Traveling_pct
    ,FORMAT(Unknown / total_revenue, 'p') AS Unknown_pct
 FROM category_label



-- 4. HOW TOTAL REVENUE CHANGES COMPARING TO THE BEGINNING(1/2019) ? 
WITH change_table as 
(
	SELECT YEAR(transaction_time) as year
			,MONTH(transation_time) as month
			,CONCAT(YEAR(transaction_time),'-',MONTH(transation_time)) as date
			,SUM(charged_amount) as total_revenue
	FROM (SELECT * FROM fact+_transaction_2019
			UNION
		  SELECT * FROM fact_transation_2020) as fact
	WHERE status_id = 1 
	GROUP YEAR(transaction_time), MONTH(transaction_time)
)
SELECT *,
        ,FIRST_VALUE(total_revenue) as begin_revenue
		,FORMAT((total_revenue / FIRST_VALUE(total_revenue)) OVER (ORDER BY year,month ) - 1, 'p') as change_rate
FROM change_table 




-- 5. REVENUE OF EACH MONTH 2019, 2020. 
WITH CTE AS 
(
    SELECT 
        CAST(transaction_time AS DATE) AS transaction_time  
        ,SUM(1.0*charged_amount) AS charged_amount  
    FROM fact_transaction_2019 
    GROUP BY CAST(transaction_time AS DATE)  
    UNION
    SELECT 
        CAST(transaction_time AS DATE) AS transaction_time  
        ,SUM(1.0*charged_amount) AS charged_amount  
    FROM fact_transaction_2020
    GROUP BY CAST(transaction_time AS DATE)
), CTE2 AS 
(
    SELECT 
        YEAR(transaction_time) AS year 
        ,MONTH(transaction_time) AS month
        ,CONCAT(YEAR(transaction_time), '-', MONTH(transaction_time)) AS date
        ,SUM(charged_amount) AS charged_amount 
        ,LAG(CONCAT(YEAR(transaction_time), '-', MONTH(transaction_time))) OVER(PARTITION BY MONTH(transaction_time) ORDER BY MONTH(transaction_time)) AS month_preyear
        ,LAG(SUM(charged_amount)) OVER(PARTITION BY MONTH(transaction_time) ORDER BY MONTH(transaction_time)) AS amount_month_preyear
    FROM CTE 
    GROUP BY YEAR(transaction_time), MONTH(transaction_time)
)
SELECT 
    date 
    ,month 
    ,charged_amount
    ,month_preyear 
    ,amount_month_preyear
    ,FORMAT(charged_amount / amount_month_preyear - 1, 'p') AS pct_diff
FROM CTE2
WHERE amount_month_preyear IS NOT NULL



-- 6. CUSTOMER SEGMENTATION BY CHARGED AMOUNT.
/* Classify customers with successful transactions into 4 groups:
Total transaction amount over 5,000,000 is "New Customer"
Total transaction amount over 10,000,000 is “Potential Customer”
Total transaction amount over 50,000,000 is "Loyal Customer"
And other is "Unknow"
Then calculate the proportion of each customer group. 
*/ 

WITH customer_amount as (
	SELECT customer_id , 
			SUM(CAST(charged_amount AS float) as total_amount
	FROM ( SELECT * FROM fact+_transaction_2019
				UNION
		   SELECT * FROM fact_transation_2020) as fact
	WHERE status_id = 1
	GROUP BY customer_id
)
, customer_label as (
	SELECT *,
			CASE WHEN total_amount > 50000000 THEN 'Loyal Customer'
				 WHEN total_amount > 10000000 THEN 'Potential Customer'
				 WHEN total_amount >  5000000 THEN 'New Customer'
				 ELSE 'unknow' 
				 END AS label 
	FROM customer_amount 
)
SELECT label
		,COUNT(customer_id) as number_customer 
		,(SELECT COUNT(customer_id) FROM customer_amount) as total_customers
		, FORMAT(COUNT(customer_id)* 1.0/ (SELECT COUNT(customer_id) FROM customer_amount) , 'p') as pct
FROM customer_label 
GROUP BY label



-- 7. CUSTOMER SEGMENTATION BY RFM MODEL.

WITH customer as (
	SELECT customer_id
			,DATEDIFF(day,MAX(transaction_time),'2020-12-31') as recency
			,COUNT(transaction_id) as frequency 
			,SUM( 1.0 * charged_amount) as monetary
	FROM (SELECT * FROM fact_transaction_2019
			UNION
		  SELECT * FROM fact_transaction_2020)
	WHERE status_id = 1 
	GROUP By customer_id 
) 
, rfm_rank as (
SELECT *
		,PERCENT_RANK () OVER (ORDER BY recency ASC ) as r_rank
		,PERCENT_RANK () OVER (ORDER BY frequency DESC ) as f_rank
		,PERCENT_RANK () OVER (ORDER BY monetary DESC ) as m_rank
FROM customer 
)
, rfm_table as (
	SELECT *
			,CASE WHEN r_rank > 0.75 THEN 4
				  WHEN r_rank > 0.5 THEN 3
				  WHEN r_rank > 0.25 THEN 2
				  ELSE 1 
				  END AS r_tier
			,CASE WHEN f_rank > 0.75 THEN 4
				  WHEN f_rank > 0.5 THEN 3
				  WHEN f_rank > 0.25 THEN 2
				  ELSE 1
				  END AS f_tier
			,CASE WHEN m_rank > 0.75 THEN 4
				  WHEN m_rank > 0.5 THEN 3
				  WHEN m_rank > 0.25 THEN 2
				  ELSE 1
				  END AS m_tier
	FROM rfm_rank 
)
, rfm_score as (
	SELECT *
			,CONCAT(r_tier, f_tier, m_tier) as rfm_score
	FROM rfm_table
)
, segment as (
	SELECT *,
		CASE 
		WHEN rfm_score = '111' THEN 'Best Customers' 
		WHEN rfm_score LIKE '[3-4][3-4][1-4]' THEN 'Lost Bad Customers' 
		WHEN rfm_score LIKE '[3-4]2[1-4]' THEN 'Lost Customers' 
		WHEN rfm_score LIKE '31[1-4]' THEN 'Almost Lost Customers' 
		WHEN rfm_score LIKE '[1-2][1-3]1' THEN 'Big Spenders' 
		WHEN rfm_score LIKE '11[2-4]' THEN 'Loyal Customers'
		WHEN rfm_score LIKE '[1-2]4[1-4]' THEN 'New Customers' 
		WHEN rfm_score LIKE '[3-4]1[1-4]' THEN 'Hibernating' 
		WHEN rfm_score LIKE '[1-2][2-3][2-4]' THEN 'Potential Loyalists' 
		ELSE 'Unknown'
		END as cus_segment
) 
SELECT cus_segment
		,COUNT(customer_id) as number_customer
		,SUM(COUNT(customer_id)) OVER() AS total_customers
		,FORMAT (COUNT(customer_id) * 1.0 / SUM(COUNT(customer_id)) OVER() , 'p') AS pct
FROM segment 
GROUP BY cus_segment