DROP TABLE IF EXISTS Employees;
CREATE TABLE Employees (
  emp_id INTEGER PRIMARY KEY, name TEXT, dept TEXT,
  salary INTEGER, hire_date TEXT, mgr_id INTEGER
);
INSERT INTO Employees VALUES
(1,'Arjun','Sales',120000,'2020-01-15',NULL),
(2,'Priya','Sales',95000,'2020-06-01',1),
(3,'Rahul','Sales',95000,'2021-03-10',1),
(4,'Kiran','Sales',72000,'2022-08-20',2),
(5,'Divya','Sales',68000,'2023-01-05',2),
(6,'Sneha','Tech',150000,'2019-05-11',NULL),
(7,'Vikram','Tech',135000,'2020-02-17',6),
(8,'Meera','Tech',135000,'2021-07-30',6),
(9,'Ravi','Tech',110000,'2022-11-14',7),
(10,'Tara','Tech',88000,'2023-04-22',7),
(11,'Aman','HR',90000,'2021-09-09',NULL),
(12,'Zoya','HR',75000,'2022-02-28',11);

DROP TABLE IF EXISTS Sales;
CREATE TABLE Sales (
  sale_id INTEGER PRIMARY KEY, emp_id INTEGER,
  sale_date TEXT, region TEXT, amount REAL
);
INSERT INTO Sales VALUES
(1,2,'2024-01-05','North',12000),(2,2,'2024-01-20','North',8000),
(3,3,'2024-01-11','South',15000),(4,3,'2024-02-14','South',9000),
(5,4,'2024-02-03','North',5000),(6,4,'2024-03-18','East',7000),
(7,5,'2024-03-02','South',11000),(8,2,'2024-03-25','North',14000),
(9,3,'2024-04-08','South',6000),(10,5,'2024-04-19','East',18000),
(11,2,'2024-05-06','North',9500),(12,4,'2024-05-21','North',4500),
(13,3,'2024-06-02','South',22000),(14,5,'2024-06-27','East',13000),
(15,2,'2024-07-14','North',16000);

DROP TABLE IF EXISTS Products;
CREATE TABLE Products (product_id INTEGER, category TEXT, price REAL, launch_date TEXT);
INSERT INTO Products VALUES
(1,'Laptop',85000,'2023-01-10'),(2,'Laptop',65000,'2023-06-15'),
(3,'Phone',45000,'2023-02-20'),(4,'Phone',32000,'2024-01-08'),
(5,'Phone',28000,'2024-03-12'),(6,'Tablet',38000,'2023-09-01'),
(7,'Tablet',22000,'2024-02-14'),(8,'Monitor',18000,'2023-11-05');


SHOW TABLES;

SELECT * FROM EMPLOYEES;
SELECT * FROM SALES;
SELECT * FROM PRODUCTS;

-- Q1 — Salary Ranking With Ties


-- Q1 — Salary Ranking With Ties

SELECT
    dept,
    name,
    salary,
    DENSE_RANK() OVER (
        PARTITION BY dept
        ORDER BY salary DESC
    ) AS salary_rank,
    MAX(salary) OVER (
        PARTITION BY dept
    ) - salary AS below_top_earner
FROM Employees
ORDER BY dept, salary_rank;

select  * from sales;

-- Q2 — Month-Over-Month Growth

WITH monthly_sales AS (
    SELECT
        DATE_FORMAT(sale_date, '%Y-%m') AS sale_month,
        SUM(amount) AS total_sales
    FROM Sales
    GROUP BY DATE_FORMAT(sale_date, '%Y-%m')
),
sales_with_previous AS (
    SELECT
        sale_month,
        total_sales,
        LAG(total_sales) OVER (
            ORDER BY sale_month
        ) AS previous_month_sales
    FROM monthly_sales
)
SELECT
    sale_month,
    total_sales,
    previous_month_sales,
    ROUND(
        (total_sales - previous_month_sales)
        / NULLIF(previous_month_sales, 0) * 100,
        2
    ) AS percentage_change
FROM sales_with_previous
ORDER BY sale_month;

-- Q3 — Top Performer Per Region

WITH employee_sales AS (
    SELECT
        s.region,
        e.emp_id,
        e.name,
        SUM(s.amount) AS total_sales
    FROM Sales s
    JOIN Employees e
        ON s.emp_id = e.emp_id
    GROUP BY s.region, e.emp_id, e.name
),
ranked_sales AS (
    SELECT
        region,
        name,
        total_sales,
        RANK() OVER (
            PARTITION BY region
            ORDER BY total_sales DESC
        ) AS sales_rank
    FROM employee_sales
)
SELECT
    region,
    name,
    total_sales
FROM ranked_sales
WHERE sales_rank = 1
ORDER BY region

#-- Q4 — Employees With No Sales
SELECT
    e.emp_id,
    e.name,
    e.dept
FROM Employees e
LEFT JOIN Sales s
    ON e.emp_id = s.emp_id
WHERE s.sale_id IS NULL
ORDER BY e.dept, e.name;




desc products;

-- Q6 — Products Against Category Average

SELECT
    category,
    product_id,
    price,

    ROUND(
        AVG(price) OVER (PARTITION BY category),
        2
    ) AS category_avg_price,

    ROUND(
        (price - AVG(price) OVER (PARTITION BY category))
        / NULLIF(AVG(price) OVER (PARTITION BY category), 0) * 100,
        2
    ) AS percentage_difference

FROM Products
ORDER BY category, price DESC;

-- Q7 — Running Total and 3-Sale Moving Average
-- The running total shows cumulative sales over time.
-- The 3-sale moving average shows the recent sales trend by smoothing
-- the current sale and previous two sales.

SELECT
    e.name,
    s.sale_date,
    s.amount,

    SUM(s.amount) OVER (
        PARTITION BY e.emp_id
        ORDER BY s.sale_date, s.sale_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total,

    ROUND(
        AVG(s.amount) OVER (
            PARTITION BY e.emp_id
            ORDER BY s.sale_date, s.sale_id
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS moving_avg_3_sales

FROM Sales s
JOIN Employees e
    ON s.emp_id = e.emp_id

WHERE e.name = 'Arjun'

ORDER BY s.sale_date, s.sale_id;

-- Q8 — Tenure Bands

SELECT
    CASE
        WHEN hire_date < '2021-01-01'
            THEN 'Before 2021'

        WHEN hire_date < '2023-01-01'
            THEN '2021 to 2022'

        ELSE '2023 onward'
    END AS tenure_band,

    COUNT(*) AS headcount,

    ROUND(AVG(salary), 2) AS average_salary

FROM Employees

GROUP BY
    CASE
        WHEN hire_date < '2021-01-01'
            THEN 'Before 2021'

        WHEN hire_date < '2023-01-01'
            THEN '2021 to 2022'

        ELSE '2023 onward'
    END

ORDER BY average_salary DESC;

 
 -- Q5 — Management Hierarchy Depth

WITH RECURSIVE employee_hierarchy AS (

    -- Level 1: Top-level employees
    SELECT
        emp_id,
        name,
        mgr_id,
        1 AS level
    FROM Employees
    WHERE mgr_id IS NULL

    UNION ALL

    -- Find employees reporting to previous level
    SELECT
        e.emp_id,
        e.name,
        e.mgr_id,
        h.level + 1
    FROM Employees e
    JOIN employee_hierarchy h
        ON e.mgr_id = h.emp_id
)

SELECT
    level,
    COUNT(*) AS employee_count,
    GROUP_CONCAT(name ORDER BY name SEPARATOR ', ') AS employee_names
FROM employee_hierarchy
GROUP BY level
ORDER BY level;