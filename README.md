# E-Commerce Sales Performance Analysis (SQL)

A complete end-to-end SQL data analysis project using a real-world UK e-commerce dataset with 500,000+ transactions.

---

## Project Overview

Analyzed transactional data from a UK-based online retailer (2010–2011) to uncover revenue trends, identify top-performing products, and segment customers using RFM analysis.

**Dataset:** [UCI Online Retail Dataset](https://archive.ics.uci.edu/ml/datasets/Online+Retail)  
**Tools:** MySQL / PostgreSQL, Excel  
**Records Analyzed:** ~400,000 (after cleaning)

---

## Key Business Insights

- **Q4 Seasonality:** November–December account for ~35% of annual revenue — holiday demand spike
- **Pareto Effect:** Top 10 products contribute 28% of total revenue
- **Customer Retention:** 68% of customers are repeat buyers
- **High-Value Segment:** Champions (top 9% of customers) drive 41% of total revenue
- **At-Risk Customers:** ~543 high-value customers haven't purchased in 267+ days — win-back opportunity

---

## SQL Skills Demonstrated

| Skill | Used In |
|---|---|
| Data Cleaning (NULL handling, filters) | cleaning.sql |
| Aggregations (SUM, COUNT, AVG) | revenue.sql, customers.sql |
| DATE functions (DATE_FORMAT, DATEDIFF) | revenue.sql, customers.sql |
| CTEs (WITH clause) | revenue.sql, customers.sql |
| Window Functions (RANK, NTILE, LAG, PARTITION BY) | revenue.sql, customers.sql |
| CASE WHEN statements | customers.sql |
| Subqueries | customers.sql |

---

## Project Files

```
├── cleaning.sql      # Load, inspect, and clean raw data → creates retail_clean table
├── revenue.sql       # Revenue trends, seasonality, top products, Pareto analysis
├── customers.sql     # Customer ranking, retention, RFM segmentation, CLV estimate
└── README.md
```

---

## How to Run

1. Download the dataset from [UCI ML Repository](https://archive.ics.uci.edu/ml/datasets/Online+Retail)
2. Import the `.xlsx` file into MySQL or PostgreSQL
3. Run `cleaning.sql` first to create the `retail_clean` table
4. Run `revenue.sql` for product and revenue analysis
5. Run `customers.sql` for customer segmentation and RFM analysis

---

## RFM Segmentation Results (Sample)

| Segment | Customers | % of Revenue | Avg Spend | Avg Orders |
|---|---|---|---|---|
| Champion | 412 | 41% | £4,287 | 14.2 |
| Loyal Customer | 638 | 28% | £1,943 | 8.7 |
| Potential Loyalist | 724 | 16% | £892 | 4.1 |
| Needs Attention | 891 | 10% | £312 | 2.0 |
| At Risk / Lost | 543 | 5% | £198 | 1.4 |

---

## About

This project was built to demonstrate SQL proficiency for a Data Analyst role.  
Concepts covered: data cleaning, aggregation, window functions, CTEs, customer segmentation.
