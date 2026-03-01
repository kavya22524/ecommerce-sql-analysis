-- ============================================================
-- E-Commerce Sales Performance Analysis
-- FILE: cleaning.sql
-- PURPOSE: Load, inspect, and clean the UCI Online Retail dataset
-- Dataset: https://archive.ics.uci.edu/ml/datasets/Online+Retail
-- ============================================================


-- -------------------------------------------------------
-- STEP 1: Create raw table (run this before importing data)
-- -------------------------------------------------------
CREATE TABLE IF NOT EXISTS online_retail (
    InvoiceNo    VARCHAR(20),
    StockCode    VARCHAR(20),
    Description  VARCHAR(255),
    Quantity     INT,
    InvoiceDate  DATETIME,
    UnitPrice    DECIMAL(10, 2),
    CustomerID   INT,
    Country      VARCHAR(100)
);

-- -------------------------------------------------------
-- STEP 2: Inspect raw data
-- -------------------------------------------------------

-- Total row count
SELECT COUNT(*) AS total_rows FROM online_retail;

-- Sample rows
SELECT * FROM online_retail LIMIT 10;

-- Check for nulls and bad values
SELECT
    SUM(CASE WHEN CustomerID  IS NULL    THEN 1 ELSE 0 END) AS null_customers,
    SUM(CASE WHEN Description IS NULL    THEN 1 ELSE 0 END) AS null_description,
    SUM(CASE WHEN Quantity    <= 0       THEN 1 ELSE 0 END) AS invalid_quantity,
    SUM(CASE WHEN UnitPrice   <= 0       THEN 1 ELSE 0 END) AS invalid_price,
    SUM(CASE WHEN InvoiceNo LIKE 'C%'    THEN 1 ELSE 0 END) AS cancellations
FROM online_retail;

-- Check countries
SELECT Country, COUNT(*) AS orders
FROM online_retail
GROUP BY Country
ORDER BY orders DESC;

-- Date range
SELECT
    MIN(InvoiceDate) AS earliest_date,
    MAX(InvoiceDate) AS latest_date
FROM online_retail;


-- -------------------------------------------------------
-- STEP 3: Create clean table
-- -------------------------------------------------------

DROP TABLE IF EXISTS retail_clean;

CREATE TABLE retail_clean AS
SELECT
    InvoiceNo,
    StockCode,
    TRIM(Description)                  AS Description,
    Quantity,
    CAST(InvoiceDate AS DATE)          AS InvoiceDate,
    UnitPrice,
    CustomerID,
    Country,
    ROUND(Quantity * UnitPrice, 2)     AS Revenue
FROM online_retail
WHERE
    CustomerID  IS NOT NULL        -- Remove transactions with no customer
    AND Quantity    > 0            -- Remove returns / negative quantities
    AND UnitPrice   > 0            -- Remove free or erroneous items
    AND InvoiceNo NOT LIKE 'C%';   -- Remove cancelled invoices


-- -------------------------------------------------------
-- STEP 4: Validate cleaned data
-- -------------------------------------------------------

-- Row count after cleaning
SELECT COUNT(*) AS clean_rows FROM retail_clean;

-- Confirm no nulls remain
SELECT
    SUM(CASE WHEN CustomerID IS NULL THEN 1 ELSE 0 END) AS null_customers,
    SUM(CASE WHEN Revenue    <= 0    THEN 1 ELSE 0 END) AS zero_revenue
FROM retail_clean;

-- Summary stats
SELECT
    ROUND(SUM(Revenue), 2)            AS total_revenue,
    COUNT(DISTINCT InvoiceNo)         AS total_orders,
    COUNT(DISTINCT CustomerID)        AS unique_customers,
    COUNT(DISTINCT StockCode)         AS unique_products,
    ROUND(AVG(Quantity), 2)           AS avg_quantity_per_line,
    ROUND(AVG(UnitPrice), 2)          AS avg_unit_price
FROM retail_clean;
