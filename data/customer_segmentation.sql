-- creating table
CREATE TABLE online_retail (
    invoice_no VARCHAR(20),
    stock_code VARCHAR(20),
    description TEXT,
    quantity INTEGER,
    invoice_date TIMESTAMP,
    unit_price NUMERIC(10, 2),
    customer_id INTEGER,
    country VARCHAR(100)
);

SELECT *
FROM online_retail
LIMIT 10;

SELECT COUNT(*)
FROM online_retail;

-- unique customers
SELECT COUNT(DISTINCT customer_id) AS unique_customers
FROM online_retail;

--unique invoices
SELECT COUNT(DISTINCT invoice_no) AS unique_invoices
FROM online_retail;

--date range
SELECT
    MIN(invoice_date) AS first_transaction,
    MAX(invoice_date) AS last_transaction
FROM online_retail;

--countries
SELECT
    country,
    COUNT(*) AS transaction_rows
FROM online_retail
GROUP BY country
ORDER BY transaction_rows DESC;

--missing customerID
SELECT
    COUNT(*) AS total_rows,
    COUNT(customer_id) AS rows_with_customer_id,
    COUNT(*) - COUNT(customer_id) AS rows_without_customer_id
FROM online_retail;

--cancelled invoices
SELECT
    COUNT(*) AS cancelled_rows
FROM online_retail
WHERE invoice_no LIKE 'C%';

--negative/returned items
SELECT
    COUNT(*) AS negative_quantity_rows
FROM online_retail
WHERE quantity < 0;

--zero or negative unit price (invalid prices)
SELECT
    COUNT(*) AS zero_or_negative_price_rows
FROM online_retail
WHERE unit_price <= 0;

--clean rows (valid purchase rows)
SELECT COUNT(*) AS clean_rows
FROM online_retail
WHERE customer_id IS NOT NULL
  AND invoice_no NOT LIKE 'C%'
  AND quantity > 0
  AND unit_price > 0;

--cleaned table
CREATE TABLE online_retail_clean AS
SELECT *
FROM online_retail
WHERE customer_id IS NOT NULL
  AND invoice_no NOT LIKE 'C%'
  AND quantity > 0
  AND unit_price > 0;

SELECT COUNT(*) AS clean_rows
FROM online_retail_clean;
SELECT *
FROM online_retail_clean
LIMIT 10;

--created "total_amount"
SELECT
    invoice_no,
    customer_id,
    quantity,
    unit_price,
    quantity * unit_price AS total_amount
FROM online_retail_clean
LIMIT 10;

--RFM
SELECT
    customer_id,
    -- Recency
    DATE '2011-12-10' - MAX(invoice_date::DATE) AS recency,
    -- Frequency
    COUNT(DISTINCT invoice_no) AS frequency,
    -- Monetary
    SUM(quantity * unit_price) AS monetary

FROM online_retail_clean
GROUP BY customer_id;

--minimum and maximum values of the calculated RFM metrics
SELECT
    MIN(recency) AS minimum_recency,
    MAX(recency) AS maximum_recency,
    MIN(frequency) AS minimum_frequency,
    MAX(frequency) AS maximum_frequency,
    MIN(monetary) AS minimum_monetary,
    MAX(monetary) AS maximum_monetary
FROM (
    SELECT
        customer_id,
        DATE '2011-12-10' - MAX(invoice_date::DATE) AS recency,
        COUNT(DISTINCT invoice_no) AS frequency,
        SUM(quantity * unit_price) AS monetary
    FROM online_retail_clean
    GROUP BY customer_id
) AS rfm;

--creating final RFM analysis
CREATE TABLE customer_rfm AS
SELECT
    customer_id,
    DATE '2011-12-10' - MAX(invoice_date::DATE) AS recency,
    COUNT(DISTINCT invoice_no) AS frequency,
    SUM(quantity * unit_price) AS monetary

FROM online_retail_clean
GROUP BY customer_id;

SELECT *
FROM customer_rfm
LIMIT 10;

SELECT COUNT(*) AS total_customers
FROM customer_rfm;

-- Calculate the average value of each customer's order
SELECT
    customer_id,
    SUM(quantity * unit_price) /
        COUNT(DISTINCT invoice_no) AS average_purchase_value
FROM online_retail_clean
GROUP BY customer_id;

-- Calculate the number of days between each customer's first and last purchase
SELECT
    customer_id,
    MIN(invoice_date) AS first_purchase_date,
    MAX(invoice_date) AS last_purchase_date,
    MAX(invoice_date)::DATE - MIN(invoice_date)::DATE
        AS customer_lifespan_days
FROM online_retail_clean
GROUP BY customer_id;