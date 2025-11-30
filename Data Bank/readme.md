# Case Study - Data Bank

## Table of Contents
- [Business Task](#business-task)
-  [Data Overview](#data-overview)
-  [Case Study Questions Part A](#case-study-questions-part-a)
-  [Case Study Questions Part B](#case-study-questions-part-b)
    
## Business Task

## Data Overview

## Case Study Questions Part A
### 1. How many unique nodes are there in the Data Bank system?
#### Explanation
- There are several nodes in each region. The node ids start with 1 in each region. so a simple COUNT DISTINCT would not count all the nodes.
- Unfortunately, SQL Server does not accept COUNT(DISTINCT value_1, value_2) to count unique data pairs.
- We'll work around that with a CTE counting the number of nodes in each region, and then summing those counts.
#### Code
```sql
WITH cte_node_count AS (
	SELECT region_name, COUNT(DISTINCT node_id) AS node_count
	FROM customer_nodes AS c
	JOIN regions AS r ON c.region_id = r.region_id
	GROUP BY region_name
	)
SELECT SUM(node_count) AS total_nodes
FROM cte_node_count;
```
#### Results
| total_nodes |
|-------------|
| 25          |

### 2. What is the number of nodes in each region?
#### Explanation
- This is just the CTE from the previous question.
#### Code
``` sql
SELECT region_name, COUNT(DISTINCT node_id) AS node_count
FROM customer_nodes AS c
JOIN regions AS r ON c.region_id = r.region_id
GROUP BY region_name;
```
#### Results
| region_name	| node_count |
|-------------|------------|
| Africa	    | 5          |
| America	    | 5          |
| Asia	      | 5          |
| Australia	  | 5          |
| Europe	    | 5          |

### 3. How many customers are allocated to each region?
#### Explanation
- Group by region
- COUNT DISTINCT on customer_id
#### Code
```sql
SELECT region_name, COUNT(DISTINCT customer_id) AS customer_count
FROM customer_nodes AS c
JOIN regions AS r ON c.region_id = r.region_id
GROUP BY region_name;
```
#### Results
| region_name	| customer_count |
|-------------|----------------|
| Africa	    | 102            |
| America	    | 105            |
| Asia	      | 95             |
| Australia	  | 110            |
| Europe	    | 88             |

### 4. After how many days on average are customers reallocated to a different node?
#### Explanation
- The end date of the current node assignment is '9999-12-31'. First, we need to replace that date with NULL so it doesn't throw off the results. 
#### Code
```sql
UPDATE customer_nodes
SET end_date = NULL
where end_date = '9999-12-31'
```
```sql
SELECT AVG(DATEDIFF(day, start_date, end_date)) AS avg_days
FROM customer_nodes;
```
#### Results
| avg_days |
|----------|
| 14       |

### 5. What is the median, 80th and 95th precentile for this same reallocation days metric for each region?
#### Explanation
- Create a CTE that joins the  ```customer_nodes``` and ```regions``` tables, and calculates the days at each node for each customer.
- From that CTE, use the  ```PERCENTILE_DISC``` window function to find the required percentile, with a SELECT DISTINCT clause to return one row per region.
#### Code
```sql
WITH cte_days AS (
	SELECT c.customer_id AS customer_id,
		c.start_date AS start_date, 
		c.end_date AS end_date, 
		r.region_name AS region_name,
		r.region_id AS region_id,
		DATEDIFF(day, start_date, end_date) AS days_at_node
	FROM customer_nodes AS c 
	JOIN regions AS r ON c.region_id = r.region_id
)
SELECT DISTINCT region_name, 
	PERCENTILE_DISC(0.5) 
		WITHIN GROUP (ORDER BY days_at_node) 
		OVER(PARTITION BY region_id) AS median,
	PERCENTILE_DISC(0.80) 
		WITHIN GROUP (ORDER BY days_at_node) 
		OVER(PARTITION BY region_id) AS perc_80,
	PERCENTILE_DISC(0.95) 
		WITHIN GROUP (ORDER BY days_at_node) 
		OVER(PARTITION BY region_id) AS perc_90
FROM cte_days; 
```
#### Results
| region_name | median	| perc_80	| perc_90 |
|-------------|---------|---------|---------|
| Africa	  | 15	    | 24	    | 28      |
| Asia	      | 15	    | 23	    | 28      |
| America	  | 15	    | 23	    | 28      |
| Australia	  | 15	    | 23	    | 28      |
| Europe	  | 15	    | 24	    | 28      |

## Case Study Questions Part B
### 1. What is the unique count and total amount for each transaction type?
#### Explanation
-
#### Code
```sql
SELECT txn_type,
	COUNT(*) AS txn_count,
	SUM(txn_amount) AS txn_total
FROM customer_transactions
GROUP BY txn_type;
```
#### Results
| txn_type   | txn_count | txn_total |
|----------- |-----------|-----------|
| withdrawal | 1580      | 793003    |
| deposit    | 2671      | 1359168   |
| purchase   | 1617      | 806537    |

### 2. What is the average total historical deposit counts and amounts for all customers?
#### Explanation
-
#### Code
```sql
WITH cte_counts AS (
	SELECT COUNT(*) AS txn_count,
		SUM(txn_amount) AS txn_total
	FROM customer_transactions
	GROUP BY customer_id
	)
SELECT AVG(txn_count) AS avg_count,
	AVG(txn_total) AS avg_total
FROM cte_counts;
```
#### Results
| avg_count | avg_total |
|-----------|-----------|
| 11        | 5917      |

### 3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
#### Explanation
-
#### Code
```sql
SELECT COUNT(*) AS total
FROM (SELECT customer_id
	FROM customer_transactions
	GROUP BY customer_id
	HAVING COUNT(CASE WHEN txn_type = 'deposit' THEN 1 ELSE 0 END) > 1
		AND COUNT(CASE WHEN txn_type = 'withdrawal' OR txn_type = 'purchase' THEN 1 ELSE 0 END) >1
	) AS filtered;
```
#### Results
| total |
|-------|
| 500   |

### 4. What is the closing balance for each customer at the end of each month?
#### Explanation
- Assume every customer started on 2020-01-01 with an account balance of $0.
#### Code
```sql

```
#### Results
| 
|-
| 

### 5. What is the percentage of customers who increase their closing balance by more than 5% over the four month period?
