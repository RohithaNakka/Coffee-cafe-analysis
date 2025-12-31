select * from city;
select * from customers;
select * from products;
select * from sales;
-- 1. HOW many people in each city are estimated to consume coffee , given the 25% of the population does
select city_name,
	round(
    (population * 0.25)/1000000,2) as coffee_consumers,
    city_rank
    from city
    order by 2 desc;
    
-- 2. Total revenue from coffee sales
-- what is the total revenue generated from coffee sales across all cities in the last quarter in the last quarter of 2025
SELECT 
a3.city_name,
sum(a1.total) as tot_revenue
from sales a1
join customers a2
on a1.customer_id = a2.customer_id
join city as a3
on a3.city_id = a2.city_id
where extract(year from a1.sale_date) = 2023
and
extract(quarter from a1.sale_date) = 4
group by 1
order by 2 desc;

-- 3.Sales Count for Each Product
-- How many units of each coffee product have been sold?
select 
	a4.product_name, 
    count(a1.sale_id) as tot_orders
    from products as a4
    left join 
    sales a1
    on a1.product_id = a4.product_id
    group by 1
    order by 2 desc;
    
-- 4.Average Sales Amount per City
-- What is the average sales amount per customer in each city?
SELECT 
    a3.city_name,
    SUM(a1.total) AS tot_revenue,
    COUNT(DISTINCT a1.customer_id) AS tot_cx,
    ROUND(SUM(a1.total) / COUNT(DISTINCT a1.customer_id), 2) AS avg_sale_pr_cx
FROM sales a1
JOIN customers a2 
    ON a1.customer_id = a2.customer_id
JOIN city a3 
    ON a3.city_id = a2.city_id
WHERE YEAR(a1.sale_date) = 2023 
  AND QUARTER(a1.sale_date) = 4
GROUP BY a3.city_name
ORDER BY tot_revenue DESC;

-- 5. City Population and Coffee Consumers
-- Provide a list of cities along with their populations and estimated coffee consumers.
select a3.city_name, 
round((a3.population * 0.25)/1000000, 2) as coffee_consumers_in_millions,
count(distinct a2.customer_id) as estimated_coffee_consumers
from city as a3
join customers as a2
on a3.city_id = a2.city_id
group by a3.city_name, coffee_consumers_in_millions
order by estimated_coffee_consumers desc;

-- 6. Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?
select * from
(select 
		a3.city_name,
        a4.product_name,
        count(a1.sale_id) as tot_orders,
        dense_rank() over(partition by a3.city_name order by count(a1.sale_id) desc ) as rankk
from sales a1
join products a4
on a1.product_id = a4.product_id
join customers a2 
on a2.customer_id = a1.customer_id
join city a3
on a3.city_id = a2.city_id
group by 1,2) as t1
where rankk <= 3;

-- 7. Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?
select a3.city_name,
	count(distinct a2.customer_id) as unique_ct
    from city a3
    left join customers a2
    on a3.city_id = a2.city_id
    join sales a1
    on a1.customer_id = a2.customer_id
    where
    a1.product_id in(1,2,3,4,5,6,7,8,9,10,11,12,13,14)
    group by 1;
    
-- 8.Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer

    WITH ct AS (
    SELECT 
        a3.city_name,
        SUM(a1.total) AS tot_revenue,
        COUNT(DISTINCT a1.customer_id) AS tot_cx,
        ROUND(SUM(a1.total) / COUNT(DISTINCT a1.customer_id), 2) AS avg_sale_pr_cx
    FROM sales a1
    JOIN customers a2 ON a1.customer_id = a2.customer_id
    JOIN city a3 ON a3.city_id = a2.city_id
    GROUP BY a3.city_name
),
cr AS (
    SELECT 
        city_name,
        estimated_rent
    FROM city
)
SELECT 
    cr.city_name,
    cr.estimated_rent,
    ct.tot_cx,
    ct.avg_sale_pr_cx,
    ROUND(cr.estimated_rent / ct.tot_cx, 2) AS avg_rent_per_cx
FROM ct 
JOIN cr ON cr.city_name = ct.city_name
ORDER BY avg_sale_pr_cx DESC;

-- 9. Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly).

with ms as (
select a3.city_name,
month(a1.sale_date) as month,
year(a1.sale_date) as year,
sum(a1.total) as tot_sale
from sales a1
join customers a2
on a1.customer_id = a2.customer_id
join city a3
on a3.city_id = a2.city_id
group by 1,2,3
order by 1,3,2),
gr as(
select 
		city_name,
        month, year, 
        tot_sale as cr_mon_sal,
        lag(tot_sale, 1) over(partition by city_name order by year, month) as last_mon_sal
        from ms
	)
select city_name,
month, 
year,
cr_mon_sal,
last_mon_sal,
round((cr_mon_sal- last_mon_sal)/last_mon_sal*100,2)
as gr
from gr
where last_mon_sal is not null;

-- 10. Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer

 WITH ct AS (
    SELECT 
        a3.city_name,
        SUM(a1.total) AS tot_revenue,
        COUNT(DISTINCT a1.customer_id) AS tot_cx,
         ROUND(SUM(a1.total) / COUNT(DISTINCT a1.customer_id), 2) AS avg_sale_pr_cx
from sales a1
join customers a2
on a1.customer_id = a2.customer_id
join city as a3
on a3.city_id = a2.city_id
group by 1
order by 2 desc
),
cr as(
select a3.city_name, 
estimated_rent,
round((a3.population * 0.25)/1000000,3) as estimated_coffee_consu_in_mls
from city a3)
SELECT 
    cr.city_name,tot_revenue,
    cr.estimated_rent as tot_rent,
    estimated_coffee_consu_in_mls,
    ct.tot_cx,
    ct.avg_sale_pr_cx,
    ROUND(cr.estimated_rent / ct.tot_cx, 2) AS avg_rent_per_cx
FROM ct 
JOIN cr ON cr.city_name = ct.city_name
order by 2 desc;