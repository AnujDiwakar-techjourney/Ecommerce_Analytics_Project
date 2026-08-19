-- ============================================================
-- E-Commerce Sales & Customer Intelligence — SQL Analysis
-- Database: PostgreSQL | ecommerce_db
-- ============================================================

-- Sanity checks: confirm row counts after loading from Python/pandas
SELECT COUNT(*) FROM orders_master;   -- expect 99,441
SELECT COUNT(*) FROM rfm_segments;    -- expect 95,560 unique customers


-- ============================================================
-- Query 1: Monthly Revenue Trend
-- Business question: How has revenue changed over time?
-- Note: order_purchase_timestamp is stored as text after the
-- pandas .to_sql() load, so it's cast to timestamp inline.
-- ============================================================
SELECT
    DATE_TRUNC('month', order_purchase_timestamp::timestamp) AS order_month,
    ROUND(SUM(total_price)::numeric, 2) AS total_revenue,
    COUNT(DISTINCT order_id) AS total_orders
FROM orders_master
WHERE order_status != 'canceled'
GROUP BY order_month
ORDER BY order_month;


-- ============================================================
-- Query 2: Top 5 Product Categories by Revenue
-- Business question: Which categories drive the most revenue?
-- Note: one category group is blank — these are ~611 orders
-- with missing item-level data (incomplete/likely cancelled
-- orders that still have an order_id but no linked product).
-- ============================================================
SELECT
    main_category,
    ROUND(SUM(total_price)::numeric, 2) AS total_revenue,
    COUNT(DISTINCT order_id) AS total_orders
FROM orders_master
WHERE order_status != 'canceled'
GROUP BY main_category
ORDER BY total_revenue DESC   
LIMIT 5;


-- ============================================================
-- Query 3: Top 10 Customers by Lifetime Spend (Window Function)
-- Business question: Who are our highest-value customers, and
-- are they still active?
-- Insight: Several top-10 lifetime spenders fall in the "At Risk"
-- or "Needs Attention" segments — high historical value does not
-- guarantee recent engagement. These are strong win-back targets.
-- ============================================================
SELECT
    customer_unique_id,
    recency,
    frequency,
    monetary,
    segment,
    RANK() OVER (ORDER BY monetary DESC) AS spend_rank
FROM rfm_segments
ORDER BY spend_rank
LIMIT 10;