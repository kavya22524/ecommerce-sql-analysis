-- ============================================================
-- E-Commerce Sales Performance Analysis
-- FILE: customers.sql
-- PURPOSE: Customer behavior, retention, ranking & RFM segmentation
-- Run cleaning.sql first to create retail_clean table
-- ============================================================


-- -------------------------------------------------------
-- SECTION A: CUSTOMER OVERVIEW
-- -------------------------------------------------------

WITH customer_summary AS (
    SELECT
        CustomerID,
        COUNT(DISTINCT InvoiceNo)         AS total_orders,
        ROUND(SUM(Revenue), 2)           AS total_spent,
        MIN(InvoiceDate)                 AS first_purchase,
        MAX(InvoiceDate)                 AS last_purchase
    FROM retail_clean
    GROUP BY CustomerID
)
SELECT
    COUNT(*)                                                          AS total_customers,
    SUM(CASE WHEN total_orders > 1 THEN 1 ELSE 0 END)                AS repeat_customers,
    ROUND(100.0 * SUM(CASE WHEN total_orders > 1 THEN 1 ELSE 0 END)
          / COUNT(*), 2)                                              AS repeat_rate_pct,
    ROUND(AVG(total_orders), 2)                                       AS avg_orders_per_customer,
    ROUND(AVG(total_spent), 2)                                        AS avg_lifetime_value,
    ROUND(MAX(total_spent), 2)                                        AS highest_spender,
    ROUND(MIN(total_spent), 2)                                        AS lowest_spender
FROM customer_summary;


-- -------------------------------------------------------
-- SECTION B: CUSTOMER ORDER FREQUENCY DISTRIBUTION
-- -------------------------------------------------------

SELECT
    total_orders                         AS number_of_orders,
    COUNT(*) AS customer_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_customers
FROM (
    SELECT CustomerID, COUNT(DISTINCT InvoiceNo) AS total_orders
    FROM retail_clean
    GROUP BY CustomerID
) order_counts
GROUP BY total_orders
ORDER BY total_orders;


-- -------------------------------------------------------
-- SECTION C: TOP 20 CUSTOMERS BY SPENDING
-- -------------------------------------------------------

SELECT
    CustomerID,
    Country,
    COUNT(DISTINCT InvoiceNo)             AS total_orders,
    SUM(Quantity)                         AS total_items,
    ROUND(SUM(Revenue), 2)               AS total_spent,
    ROUND(AVG(Revenue), 2)               AS avg_order_value,
    MIN(InvoiceDate)                     AS first_purchase,
    MAX(InvoiceDate)                     AS last_purchase
FROM retail_clean
GROUP BY CustomerID, Country
ORDER BY total_spent DESC
LIMIT 20;


-- -------------------------------------------------------
-- SECTION D: RANK CUSTOMERS USING WINDOW FUNCTIONS
-- -------------------------------------------------------

WITH customer_spend AS (
    SELECT
        CustomerID,
        Country,
        ROUND(SUM(Revenue), 2)            AS total_spent,
        COUNT(DISTINCT InvoiceNo)         AS total_orders,
        MIN(InvoiceDate)                  AS first_purchase,
        MAX(InvoiceDate)                  AS last_purchase
    FROM retail_clean
    GROUP BY CustomerID, Country
)
SELECT
    CustomerID,
    Country,
    total_spent,
    total_orders,
    RANK()       OVER (ORDER BY total_spent DESC)                       AS global_rank,
    RANK()       OVER (PARTITION BY Country ORDER BY total_spent DESC)  AS country_rank,
    NTILE(10)    OVER (ORDER BY total_spent DESC)                       AS spending_decile,
    ROUND(total_spent / SUM(total_spent) OVER () * 100, 4)             AS pct_of_total_revenue
FROM customer_spend
ORDER BY global_rank
LIMIT 50;


-- -------------------------------------------------------
-- SECTION E: NEW VS RETURNING CUSTOMERS PER MONTH
-- -------------------------------------------------------

WITH first_purchase AS (
    SELECT
        CustomerID,
        MIN(DATE_FORMAT(InvoiceDate, '%Y-%m')) AS first_month
    FROM retail_clean
    GROUP BY CustomerID
),
monthly_customers AS (
    SELECT
        DATE_FORMAT(r.InvoiceDate, '%Y-%m')   AS month,
        r.CustomerID,
        fp.first_month
    FROM retail_clean r
    JOIN first_purchase fp ON r.CustomerID = fp.CustomerID
    GROUP BY DATE_FORMAT(r.InvoiceDate, '%Y-%m'), r.CustomerID, fp.first_month
)
SELECT
    month,
    COUNT(DISTINCT CustomerID)                                                      AS total_customers,
    COUNT(DISTINCT CASE WHEN month = first_month THEN CustomerID END)               AS new_customers,
    COUNT(DISTINCT CASE WHEN month != first_month THEN CustomerID END)              AS returning_customers,
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN month != first_month THEN CustomerID END)
          / COUNT(DISTINCT CustomerID), 1)                                          AS returning_pct
FROM monthly_customers
GROUP BY month
ORDER BY month;


-- -------------------------------------------------------
-- SECTION F: RFM ANALYSIS
-- -------------------------------------------------------

-- Step 1: Calculate raw RFM values per customer
WITH rfm_base AS (
    SELECT
        CustomerID,
        Country,
        DATEDIFF('2011-12-31', MAX(InvoiceDate))   AS recency_days,
        COUNT(DISTINCT InvoiceNo)                  AS frequency,
        ROUND(SUM(Revenue), 2)                     AS monetary
    FROM retail_clean
    GROUP BY CustomerID, Country
),

-- Step 2: Score each metric into quintiles (1=worst, 5=best)
rfm_scored AS (
    SELECT
        CustomerID,
        Country,
        recency_days,
        frequency,
        monetary,
        -- Recency: lower days = better = higher score
        NTILE(5) OVER (ORDER BY recency_days DESC)  AS r_score,
        -- Frequency: higher orders = better = higher score
        NTILE(5) OVER (ORDER BY frequency ASC)      AS f_score,
        -- Monetary: higher spend = better = higher score
        NTILE(5) OVER (ORDER BY monetary ASC)       AS m_score
    FROM rfm_base
),

-- Step 3: Combine scores and assign segment labels
rfm_segments AS (
    SELECT
        CustomerID,
        Country,
        recency_days,
        frequency,
        monetary,
        r_score,
        f_score,
        m_score,
        (r_score + f_score + m_score)  AS rfm_total,
        CASE
            WHEN (r_score + f_score + m_score) >= 13 THEN 'Champion'
            WHEN (r_score + f_score + m_score) >= 10 THEN 'Loyal Customer'
            WHEN (r_score + f_score + m_score) >= 7  THEN 'Potential Loyalist'
            WHEN r_score <= 2 AND (f_score + m_score) >= 6 THEN 'At Risk - High Value'
            WHEN r_score <= 2                         THEN 'Lost'
            ELSE 'Needs Attention'
        END AS segment
    FROM rfm_scored
)

-- Final output: full RFM table
SELECT *
FROM rfm_segments
ORDER BY rfm_total DESC;


-- -------------------------------------------------------
-- SECTION G: RFM SEGMENT SUMMARY REPORT
-- -------------------------------------------------------

WITH rfm_base AS (
    SELECT
        CustomerID,
        DATEDIFF('2011-12-31', MAX(InvoiceDate))   AS recency_days,
        COUNT(DISTINCT InvoiceNo)                  AS frequency,
        ROUND(SUM(Revenue), 2)                     AS monetary
    FROM retail_clean
    GROUP BY CustomerID
),
rfm_scored AS (
    SELECT *,
        NTILE(5) OVER (ORDER BY recency_days DESC)  AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC)      AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC)       AS m_score
    FROM rfm_base
),
rfm_segments AS (
    SELECT *,
        (r_score + f_score + m_score) AS rfm_total,
        CASE
            WHEN (r_score + f_score + m_score) >= 13 THEN 'Champion'
            WHEN (r_score + f_score + m_score) >= 10 THEN 'Loyal Customer'
            WHEN (r_score + f_score + m_score) >= 7  THEN 'Potential Loyalist'
            WHEN r_score <= 2 AND (f_score + m_score) >= 6 THEN 'At Risk - High Value'
            WHEN r_score <= 2                         THEN 'Lost'
            ELSE 'Needs Attention'
        END AS segment
    FROM rfm_scored
)
SELECT
    segment,
    COUNT(*)                              AS customer_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_of_customers,
    ROUND(SUM(monetary), 2)              AS total_revenue,
    ROUND(100.0 * SUM(monetary) / SUM(SUM(monetary)) OVER (), 1) AS pct_of_revenue,
    ROUND(AVG(monetary), 2)              AS avg_spend,
    ROUND(AVG(frequency), 1)             AS avg_orders,
    ROUND(AVG(recency_days), 0)          AS avg_recency_days
FROM rfm_segments
GROUP BY segment
ORDER BY avg_spend DESC;


-- -------------------------------------------------------
-- SECTION H: CUSTOMER LIFETIME VALUE (CLV) ESTIMATE
-- -------------------------------------------------------

-- Simple CLV: average order value x purchase frequency x estimated lifespan
WITH clv_base AS (
    SELECT
        CustomerID,
        COUNT(DISTINCT InvoiceNo)            AS total_orders,
        ROUND(SUM(Revenue), 2)              AS total_spent,
        ROUND(SUM(Revenue) / COUNT(DISTINCT InvoiceNo), 2) AS avg_order_value,
        DATEDIFF(MAX(InvoiceDate), MIN(InvoiceDate)) AS customer_lifespan_days
    FROM retail_clean
    GROUP BY CustomerID
    HAVING total_orders > 1
)
SELECT
    CustomerID,
    total_orders,
    total_spent,
    avg_order_value,
    customer_lifespan_days,
    -- Annualized purchase rate
    ROUND(total_orders / NULLIF(customer_lifespan_days, 0) * 365, 1) AS orders_per_year,
    -- Estimated 3-year CLV
    ROUND(avg_order_value * (total_orders / NULLIF(customer_lifespan_days, 0) * 365) * 3, 2) AS estimated_3yr_clv
FROM clv_base
ORDER BY estimated_3yr_clv DESC
LIMIT 30;
