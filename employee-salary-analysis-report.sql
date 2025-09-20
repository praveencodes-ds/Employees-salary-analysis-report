

CREATE DATABASE cte_DB;
USE cte_DB;

DROP TABLE IF EXISTS employees ; 

-- Create employees table
CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    name VARCHAR(10) NOT NULL,
    join_date DATE NOT NULL,
    department VARCHAR(10) NOT NULL
);

-- Insert sample data
INSERT INTO employees (employee_id, name, join_date, department)
VALUES
(1, 'Alice', '2018-06-15', 'IT'),
(2, 'Bob', '2019-02-10', 'Finance'),
(3, 'Charlie', '2017-09-20', 'HR'),
(4, 'David', '2020-01-05', 'IT'),
(5, 'Eve', '2016-07-30', 'Finance'),
(6, 'Sumit', '2016-06-30', 'Finance');

DROP TABLE IF EXISTS salary_history; 

-- Create salary_history table
CREATE TABLE salary_history (
    employee_id INT,
    change_date DATE NOT NULL,
    salary DECIMAL(10,2) NOT NULL,
    promotion VARCHAR(3)
);

-- Insert sample data
INSERT INTO salary_history (employee_id, change_date, salary, promotion)
VALUES
(1, '2018-06-15', 50000, 'No'),
(1, '2019-08-20', 55000, 'No'),
(1, '2021-02-10', 70000, 'Yes'),
(2, '2019-02-10', 48000, 'No'),
(2, '2020-05-15', 52000, 'Yes'),
(2, '2023-01-25', 68000, 'Yes'),
(3, '2017-09-20', 60000, 'No'),
(3, '2019-12-10', 65000, 'No'),
(3, '2022-06-30', 72000, 'Yes'),
(4, '2020-01-05', 45000, 'No'),
(4, '2021-07-18', 49000, 'No'),
(5, '2016-07-30', 55000, 'No'),
(5, '2018-11-22', 62000, 'Yes'),
(5, '2021-09-10', 15000, 'Yes'),
(6, '2016-08-30', 55000, 'No'),
(6, '2017-11-22', 50000, 'No'),
(6, '2018-11-22', 40000, 'No'),
(6, '2021-09-10', 75000, 'Yes');
  
SELECT * FROM Employees;
SELECT * FROM Salary_History;

  
--   Tasks

# 1 - Find the latest salary for each employee.
WITH cte AS (
SELECT *, 
RANK() OVER(PARTITION BY Employee_id ORDER BY Change_Date DESC) AS rn 
FROM Salary_History 
)
SELECT Employee_id, salary AS Latest_salary
FROM cte 
WHERE rn = 1;

SELECT employee_id, MAX(salary) AS Latest_salary 
FROM Salary_History 
GROUP BY Employee_id ;
 
# 2 - Calculate the total number of promotions each employee has received.
SELECT employee_id, COUNT(*) AS No_of_promotions 
FROM salary_history 
WHERE Promotion = "Yes" 
GROUP BY employee_id;

# 3 - Determine the maximum salary hike percentage between any two consecutive salary changes for each employee.
WITH prev_salary_cte AS ( 
SELECT * ,
LEAD(salary, 1) OVER(PARTITION BY Employee_id ORDER BY Change_Date DESC) AS prev_salary 
FROM salary_history 
) 
SELECT employee_id, 
	MAX(ROUND((salary - prev_salary) * 100.0 / prev_salary, 2)) AS Max_salary_growth 
FROM prev_salary_cte 
GROUP BY employee_id;

# 4 - Identify employees whose salary has never decreased over time.
WITH prev_salary_cte AS ( 
SELECT * ,
LEAD(salary, 1) OVER(PARTITION BY Employee_id ORDER BY Change_Date DESC) AS prev_salary 
FROM salary_history 
)
SELECT DISTINCT employee_id, 'N' AS Never_decreased 
FROM prev_salary_cte 
WHERE salary < prev_salary;

# 5 - Find the average time (in months) between salary changes for each employee.
WITH prev_salary_cte AS ( 
SELECT * ,
LEAD(salary, 1) OVER(PARTITION BY Employee_id ORDER BY Change_Date DESC) AS prev_salary, 
LEAD(change_date, 1) OVER(PARTITION BY Employee_id ORDER BY Change_Date DESC) AS prev_change_date   
FROM salary_history 
)
SELECT employee_id, 
	ROUND(AVG(TIMESTAMPDIFF(MONTH, prev_change_date, change_date)), 2) AS Avg_months_between_changes 
FROM prev_salary_cte 
WHERE prev_change_date IS NOT NULL 
GROUP BY employee_id;

# 6 - Rank employees by their salary growth rate (from first to last recorded salary), breaking ties by earliest join date.
WITH cte AS (
SELECT *, 
RANK() OVER(PARTITION BY Employee_id ORDER BY Change_Date DESC) AS rn_desc, 
RANK() OVER(PARTITION BY Employee_id ORDER BY Change_Date ASC) AS rn_asc
FROM Salary_History 
), 
salary_ratio_cte AS (  
SELECT CTE.employee_id,  
MAX(CASE WHEN rn_desc=1 THEN salary END) / MAX(CASE WHEN rn_asc=1 THEN salary END) AS salary_growth_ratio, 
MIN(change_date) AS join_date
FROM cte 
JOIN employees e ON cte.employee_id = e.employee_id 
GROUP BY cte.employee_id 
), 
salary_growth_rank_cte AS (  
SELECT employee_id, salary_growth_ratio,
RANK() OVER(ORDER BY salary_growth_ratio DESC, join_date ASC) RankByGrowth 
FROM salary_ratio_cte 
) 
SELECT * FROM salary_growth_rank_cte; 



-- ==============================================================================

WITH cte AS (
SELECT *, 
RANK() OVER(PARTITION BY Employee_id ORDER BY Change_Date DESC) AS rn_desc, 
RANK() OVER(PARTITION BY Employee_id ORDER BY Change_Date ASC) AS rn_asc, 
LEAD(salary, 1) OVER(PARTITION BY Employee_id ORDER BY Change_Date DESC) AS prev_salary,  
LEAD(change_date, 1) OVER(PARTITION BY Employee_id ORDER BY Change_Date DESC) AS prev_change_date 
FROM Salary_History 
),  
/* 
latest_salary_cte AS (
SELECT Employee_id, salary AS Latest_salary
FROM cte 
WHERE rn_desc = 1
), 

promotions_cte AS ( 
SELECT employee_id, COUNT(*) AS no_of_promotions 
FROM cte 
WHERE Promotion = "Yes" 
GROUP BY employee_id 
),
prev_salary_cte AS ( 
SELECT * ,
LEAD(salary, 1) OVER(PARTITION BY Employee_id ORDER BY Change_Date DESC) AS prev_salary,  
LEAD(change_date, 1) OVER(PARTITION BY Employee_id ORDER BY Change_Date DESC) AS prev_change_date   
FROM cte 
),
salary_growth_cte AS ( 
SELECT employee_id, 
	MAX(ROUND((salary - prev_salary) * 100.0 / prev_salary, 2)) AS Max_salary_growth 
FROM cte 
GROUP BY employee_id
), 
salary_decreased_cte AS ( 
SELECT DISTINCT employee_id, 'N' AS Never_decreased 
FROM cte 
WHERE salary < prev_salary
), 
avg_months_cte AS ( 
SELECT employee_id, 
	ROUND(AVG(TIMESTAMPDIFF(MONTH, prev_change_date, change_date)), 2) AS Avg_months_between_changes 
FROM cte 
GROUP BY employee_id 
), 
*/ 
salary_ratio_cte AS (  
SELECT employee_id, 
MAX(CASE WHEN rn_desc=1 THEN salary END) / MAX(CASE WHEN rn_asc=1 THEN salary END) AS salary_growth_ratio, 
MIN(change_date) AS join_date
FROM cte 
GROUP BY employee_id 
), 
salary_growth_rank_cte AS (  
SELECT employee_id, 
RANK() OVER(ORDER BY salary_growth_ratio DESC, join_date ASC) RankByGrowth 
FROM salary_ratio_cte 
)

SELECT cte.employee_id, 
MAX(CASE WHEN rn_desc=1 THEN salary END) AS latest_salary, 
SUM(CASE WHEN promotion = 'Yes' THEN 1 ELSE 0 END) AS no_of_promotions, 
MAX(ROUND((salary - prev_salary) * 100.0 / prev_salary, 2)) AS Max_salary_growth, 
CASE WHEN MAX(CASE WHEN salary < prev_salary THEN 1 ELSE 0 END)=0 THEN 'Y' ELSE 'N' END AS NeverDecreased, 
ROUND(AVG(TIMESTAMPDIFF(MONTH, prev_change_date, change_date)), 2) AS Avg_months_between_changes, 
RANK() OVER(ORDER BY sr.salary_growth_ratio DESC, sr.join_date ASC) AS RankByGrowth 
FROM cte 
LEFT JOIN salary_ratio_cte sr ON cte.employee_id = sr.employee_id 
GROUP BY cte.employee_id, sr.salary_growth_ratio, sr.join_date 
ORDER BY cte.employee_id;








/* 
SELECT e.employee_id, e.name, s.latest_salary, ISNULL(p.no_of_promotions, 0) AS no_of_promotions, 
	msg.max_salary_growth, ISNULL(sd.never_decreased,'Y') AS never_decreased, 
    am.Avg_months_between_changes, rbg.RankByGrowth 
FROM employees e 
LEFT JOIN latest_salary_cte ls ON e.employee_id = ls.employee_id 
LEFT JOIN promotions_cte p ON e.employee_id = p.employee_id 
LEFT JOIN salary_growth_cte msg ON e.employee_id = msg.employee_id 
LEFT JOIN salary_decreased_cte sd ON e.employee_id = sd.employee_id 
LEFT JOIN avg_months_cte am ON e.employee_id = am.employee_id 
LEFT JOIN salary_growth_rank_cte rbg ON e.employee_id = rbg.employee_id ;

SELECT * FROM employees;

*/

