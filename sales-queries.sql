-- =====================================================================
-- Sales Performance Analysis (January to June 2026)
-- Author   : Adetola Samuel
-- Database : PostgreSQL
-- Tables   : customers, products, transactions
-- Revenue  : quantity * unit_price * (1 - discount)
--            (discount is stored as a fraction, so 0.05 means 5%)
-- Run the sections below in order.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1. CREATE THE TABLES
-- No foreign keys are added on purpose: two transactions use codes that
-- are missing from the lookup tables (see section 4) and would be rejected.
-- ---------------------------------------------------------------------
create table customers (
    customer_id    text primary key,
    customer_name  text,
    city           text,
    customer_type  text
);

create table products (
    product_id    text primary key,
    product_name  text,
    category      text,
    unit_price    int
);

create table transactions (
    transaction_id    text primary key,
    customer_id       text,
    product_id        text,
    transaction_date  date,
    quantity          int,
    discount          numeric
);


-- ---------------------------------------------------------------------
-- 2. LOAD THE DATA
-- Import the three CSV files (customers and products first).
-- In pgAdmin: right-click each table > Import/Export Data > Header: on.
-- Or in psql, replace the paths and run:
--   \copy customers    from 'Customers.csv'    csv header
--   \copy products     from 'Products.csv'     csv header
--   \copy transactions from 'Transactions.csv' csv header
-- ---------------------------------------------------------------------
select * from transactions limit 10;   -- quick look at the loaded data


-- ---------------------------------------------------------------------
-- 3. DATA CORRECTION
-- T0120 was recorded with quantity -2. It was treated as a data entry
-- mistake and corrected to 2. To treat it as a real return instead,
-- skip this statement (total revenue then becomes 41,563,200).
-- ---------------------------------------------------------------------
update transactions
set quantity = 2
where transaction_id = 'T0120';


-- ---------------------------------------------------------------------
-- 4. DATA QUALITY CHECKS
-- ---------------------------------------------------------------------
-- 4a. Number of transactions loaded (expected: 150)
select count(*) as total_transactions
from transactions;

-- 4b. Transactions whose product is not in the products table
--     (expected: T0080 with product P999, left out of all revenue results)
select t.*
from transactions as t
left join products as p on t.product_id = p.product_id
where p.product_id is null;

-- 4c. Transactions whose customer is not in the customers table
--     (expected: T0040 with customer C999, about 450,000 in revenue;
--      it is left out of the customer, city and customer type results)
select t.*
from transactions as t
left join customers as c on t.customer_id = c.customer_id
where c.customer_id is null;

-- 4d. Zero or negative quantities (expected: none after section 3)
select *
from transactions
where quantity <= 0;


-- ---------------------------------------------------------------------
-- 5. HEADLINE NUMBERS (JOIN + aggregations)
-- Expected: revenue 43,363,200 | transactions 149 | units 450 | average 291,028
-- ---------------------------------------------------------------------
select
    sum(t.quantity * p.unit_price * (1 - t.discount))        as total_revenue,
    count(*)                                                 as total_transactions,
    sum(t.quantity)                                          as total_units_sold,
    round(avg(t.quantity * p.unit_price * (1 - t.discount))) as avg_transaction_value
from transactions as t
join products as p on t.product_id = p.product_id;


-- ---------------------------------------------------------------------
-- 6. REVENUE BY PRODUCT (JOIN, GROUP BY, SUM)
-- Highest: Monitor 7,992,000 | Printer 7,104,000 | Laptop 6,570,000
-- ---------------------------------------------------------------------
select p.product_name, p.product_id,
       sum(t.quantity * p.unit_price * (1 - t.discount)) as total_revenue
from transactions as t
join products as p on t.product_id = p.product_id
group by p.product_name, p.product_id
order by total_revenue desc;


-- ---------------------------------------------------------------------
-- 7. REVENUE BY PRODUCT CATEGORY
-- Highest: Electronics 25,484,000
-- ---------------------------------------------------------------------
select p.category,
       sum(t.quantity * p.unit_price * (1 - t.discount)) as total_revenue
from transactions as t
join products as p on t.product_id = p.product_id
group by p.category
order by total_revenue desc;


-- ---------------------------------------------------------------------
-- 8. REVENUE BY CUSTOMER
-- Highest: Ibrahim Sani 4,716,000
-- ---------------------------------------------------------------------
select c.customer_name, c.customer_id,
       sum(t.quantity * p.unit_price * (1 - t.discount)) as total_revenue
from transactions as t
join customers as c on t.customer_id = c.customer_id
join products  as p on t.product_id  = p.product_id
group by c.customer_name, c.customer_id
order by total_revenue desc;


-- ---------------------------------------------------------------------
-- 9. REVENUE BY CITY
-- Highest: Kano 7,222,000 | Abuja 7,071,000 | Lagos 6,473,250
-- ---------------------------------------------------------------------
select c.city,
       sum(t.quantity * p.unit_price * (1 - t.discount)) as total_revenue
from transactions as t
join customers as c on t.customer_id = c.customer_id
join products  as p on t.product_id  = p.product_id
group by c.city
order by total_revenue desc;


-- ---------------------------------------------------------------------
-- 10. REVENUE BY CUSTOMER TYPE
-- Retail 23,975,850 | Corporate 16,320,350 | Wholesale 2,617,000
-- ---------------------------------------------------------------------
select c.customer_type,
       sum(t.quantity * p.unit_price * (1 - t.discount)) as total_revenue
from transactions as t
join customers as c on t.customer_id = c.customer_id
join products  as p on t.product_id  = p.product_id
group by c.customer_type
order by total_revenue desc;


-- ---------------------------------------------------------------------
-- 11. AVERAGE REVENUE PER TRANSACTION (AVG)
-- Expected: about 291,028
-- ---------------------------------------------------------------------
select avg(t.quantity * p.unit_price * (1 - t.discount)) as avg_transaction_value
from transactions as t
join products as p on t.product_id = p.product_id;


-- ---------------------------------------------------------------------
-- 12. MONTHLY REVENUE TREND
-- Jan 9,642,250 | Feb 5,319,850 | Mar 8,660,250
-- Apr 5,289,950 | May 9,167,500 | Jun 5,283,400
-- ---------------------------------------------------------------------
select to_char(date_trunc('month', t.transaction_date), 'Mon') as month,
       sum(t.quantity * p.unit_price * (1 - t.discount))       as total_revenue
from transactions as t
join products as p on t.product_id = p.product_id
group by date_trunc('month', t.transaction_date)
order by date_trunc('month', t.transaction_date);
