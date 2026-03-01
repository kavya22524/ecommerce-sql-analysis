-- ============================================================
-- E-Commerce Sales Performance Analysis
-- FILE: revenue.sql
-- PURPOSE: Revenue trends, seasonality, and top product analysis
-- Run cleaning.sql first to create retail_clean table
-- ============================================================


-- -------------------------------------------------------
-- SECTION A: OVERALL REVENUE SUMMARY
-- -------------------------------------------------------

SELECT
    ROUND(SUM(Revenue), 2)            AS total_revenue,
    COUNT(DISTINCT InvoiceNo)         AS total_orders,
    COUNT(DISTINCT CustomerID)        AS unique_customers,
    ROUND(AVG(Revenue), 2)            AS avg_revenue_per_line,
    ROUND(SUM(Revenue) / COUNT(DISTINCT InvoiceNo), 2) AS avg_order_value
FROM retail_clean;


-- -------------------------------------------------------
-- SECTION B: MONTHLY REVENUE TRENDS
-- -------------------------------------------------------

-- Monthly revenue, orders, and active customers
SELECT
    DATE_FORMAT(InvoiceDate, '%Y-%m')     AS month,
    ROUND(SUM(Revenue), 2)               AS monthly_revenue,
    COUNT(DISTINCT InvoiceNo)            AS total_orders,
    COUNT(DISTINCT CustomerID)           AS active_customers,
    ROUND(AVG(Revenue), 2)               AS avg_order_value
FROM retail_clean
GROUP BY DATE_FORMAT(InvoiceDate, '%Y-%m')
ORDER BY month;


-- Month-over-month revenue growth %
WITH monthly AS (
    SELECT
        DATE_FORMAT(InvoiceDate, '%Y-%m')  AS month,
        ROUND(SUM(Revenue), 2)            AS monthly_revenue
    FROM retail_clean
    GROUP BY DATE_FORMAT(InvoiceDate, '%Y-%m')
)
SELECT
    month,
    monthly_revenue,
    LAG(monthly_revenue) OVER (ORDER BY month)  AS prev_month_revenue,
    ROUND(
        100.0 * (monthly_revenue - LAG(monthly_revenue) OVER (ORDER BY month))
        / LAG(monthly_revenue) OVER (ORDER BY month),
    1) AS mom_growth_pct
FROM monthly
ORDER BY month;


-- -------------------------------------------------------
-- SECTION C: QUARTERLY REVENUE BREAKDOWN
-- -------------------------------------------------------

SELECT
    YEAR(InvoiceDate)                     AS year,
    QUARTER(InvoiceDate)                  AS quarter,
    ROUND(SUM(Revenue), 2)               AS quarterly_revenue,
    COUNT(DISTINCT InvoiceNo)            AS orders
FROM retail_clean
GROUP BY YEAR(InvoiceDate), QUARTER(InvoiceDate)
ORDER BY year, quarter;


-- -------------------------------------------------------
-- SECTION D: DAY-OF-WEEK REVENUE PATTERNS
-- -------------------------------------------------------

SELECT
    DAYNAME(InvoiceDate)                  AS day_of_week,
    DAYOFWEEK(InvoiceDate)               AS day_num,
    ROUND(SUM(Revenue), 2)               AS total_revenue,
    COUNT(DISTINCT InvoiceNo)            AS total_orders,
    ROUND(AVG(Revenue), 2)               AS avg_order_value
FROM retail_clean
GROUP BY DAYNAME(InvoiceDate), DAYOFWEEK(InvoiceDate)
ORDER BY day_num;


-- -------------------------------------------------------
-- SECTION E: TOP 10 PRODUCTS BY REVENUE
-- -------------------------------------------------------

SELECT
    StockCode,
    Description,
    SUM(Quantity)                         AS total_units_sold,
    ROUND(SUM(Revenue), 2)               AS total_revenue,
    COUNT(DISTINCT InvoiceNo)            AS times_ordered,
    COUNT(DISTINCT CustomerID)           AS unique_customers,
    ROUND(AVG(UnitPrice), 2)             AS avg_unit_price
FROM retail_clean
GROUP BY StockCode, Description
ORDER BY total_revenue DESC
LIMIT 10;


-- -------------------------------------------------------
-- SECTION F: TOP 10 PRODUCTS BY UNITS SOLD
-- -------------------------------------------------------

SELECT
    StockCode,
    Description,
    SUM(Quantity)                         AS total_units_sold,
    ROUND(SUM(Revenue), 2)               AS total_revenue,
    ROUND(AVG(UnitPrice), 2)             AS avg_unit_price
FROM retail_clean
GROUP BY StockCode, Description
ORDER BY total_units_sold DESC
LIMIT 10;


-- -------------------------------------------------------
-- SECTION G: REVENUE BY COUNTRY
-- -------------------------------------------------------

SELECT
    Country,
    ROUND(SUM(Revenue), 2)               AS total_revenue,
    COUNT(DISTINCT CustomerID)           AS customers,
    COUNT(DISTINCT InvoiceNo)            AS orders,
    ROUND(SUM(Revenue) / COUNT(DISTINCT InvoiceNo), 2) AS avg_order_value
FROM retail_clean
GROUP BY Country
ORDER BY total_revenue DESC
LIMIT 15;


-- -------------------------------------------------------
-- SECTION H: REVENUE CONTRIBUTION (PARETO ANALYSIS)
-- -------------------------------------------------------

-- What % of revenue do top N products contribute?
WITH product_revenue AS (
    SELECT
        StockCode,
        Description,
        ROUND(SUM(Revenue), 2)  AS product_revenue
    FROM retail_clean
    GROUP BY StockCode, Description
),
ranked AS (
    SELECT *,
        RANK() OVER (ORDER BY product_revenue DESC) AS rnk,
        SUM(product_revenue) OVER ()                AS grand_total,
        SUM(product_revenue) OVER (ORDER BY product_revenue DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total
    FROM product_revenue
)
SELECT
    rnk,
    StockCode,
    Description,
    product_revenue,
    ROUND(100.0 * product_revenue / grand_total, 2)      AS pct_of_total,
    ROUND(100.0 * running_total / grand_total, 2)        AS cumulative_pct
FROM ranked
ORDER BY rnk
LIMIT 20;
