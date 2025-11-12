# Case Study - Danny's Dinner

# Table of Contents
- [Business Task](#business-task)
-  [Data Overview](#data-overview)
-  [Case_Study_Questions](#case-study-questions)
    
## Business Task
Danny’s Diner, a new Japanese restaurant, has asked for assistance in using customer data to help them run the business, and has provided a sample of customer data to work with. The stakeholders have asked for SQL queries to answer a series of questions. 

## Data Overview
The data given comprises three tables. 
![Entity Relationship Diagram](/images/dannys_diner_database_diagram.png)

## Case Study Questions
### 1. What is the total amount each customer spent at the restaurant?
#### Code
``` sql
SELECT customer_id, 
	SUM(price) AS total_spent
FROM sales AS s
JOIN menu AS m on s.product_id = m.product_id
GROUP BY s.customer_id;
```
#### Explanation
- JOIN the ```sales``` and ```menu``` tables to get both the customer id and the item prices
- GROUP BY ```sales.customer_id```
- Aggregate SUM function to find the total spend for each customer
#### Answer
| customer_id | total_spend |
| ----------- | ----------- |
| A           | 76          |
| B           | 74          |
| C           | 36          |

### 2. How many days has each customer visited the restaurant?
#### Code
``` sql
SELECT customer_id, 
	COUNT(DISTINCT order_date) AS total_days
FROM sales 
GROUP BY customer_id;
```
#### Explanation
- GROUP BY ```sales.customer_id```
- COUNT DISTINCT ```order_date``` to find the number of days each customer visited, without double counting days with multiple orders.
#### Answer
| customer_id | total_days |
|-------------|------------|
| A           | 4          |
| B	          | 6          |
| C           |	2          |

### 3. What was the first item from the menu purchased by each customer?
#### Code
``` sql
WITH cte AS (
	SELECT customer_id, order_date, product_name,
		RANK () OVER (PARTITION BY customer_id ORDER BY order_date ASC) AS rnk
	FROM sales AS s
	JOIN menu AS m ON s.product_id = m.product_id
    )
SELECT customer_id, product_name
FROM cte
WHERE rnk = 1
GROUP BY customer_id, product_name;
```
#### Explanation
- ```RANK () OVER (PARTITION BY customer_id)``` will return the order in which items were ordered by each customer.
- Putting those values into a ```cte``` and selecting rows with ```rnk``` of 1 returns the first item ordered by each customer.
- In the case of customer A, two items were ordered at the same time, so both are returned.
#### Answer
| customer_id | product_name |
|-------------|--------------|
| A           | curry        |
| A           | sushi        |
| B           |	curry        |
| C           |	ramen        |

### 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
#### Code
``` sql
SELECT TOP 1 product_name, 
	COUNT(*) AS orders
FROM sales AS s
JOIN menu AS m ON s.product_id = m.product_id
GROUP BY product_name
ORDER BY orders DESC;
```
#### Explanation
- JOIN ON ```sales.product_id = menu.product_id``` to link the product name with the product id
- GROUP BY product name and COUNT all entries for each group
- ORDER BY the ordrers total

#### Answer
| product_name | orders |
|--------------|--------|
| ramen        | 8      |

### 5. Which item was the most popular for each customer?
#### Code
``` sql
WITH cte5 AS (
	SELECT customer_id, product_name,
		COUNT(order_date) AS orders,
		RANK () OVER (PARTITION BY customer_id ORDER BY COUNT(*) DESC) AS rnk
	FROM sales AS s
	JOIN menu AS m ON s.product_id = m.product_id
	GROUP BY product_name, customer_id
	)
SELECT customer_id, product_name, orders
FROM cte5
WHERE rnk = 1;
```
#### Explanation
- In the case of a tie for the top item for each customer, all tied items need to be in the results.
- Create a CTE with ``` RANK () OVER (PARTITION BY customer_id ORDER BY COUNT(*) DESC)  ```
- SELECT the items with a ```rnk``` of 1. 
#### Answer
| customer_id | product_name | orders |
| ------------|--------------|--------|
| A           | ramen        | 3      |
| B           | curry        | 2      |
| B           | ramen        | 2      |
| B           | sushi        | 2      |
| C           | ramen        | 3      |

### 6. Which item was purchased first by the customer after they became a member?
#### Code
``` sql
WITH cte6 AS (
    SELECT s.customer_id, s.order_date, m.product_name,
			RANK () OVER (PARTITION BY s.customer_id ORDER BY s.order_date ASC) AS rnk
	FROM sales AS s
	JOIN members AS mem ON s.customer_id = mem.customer_id
	JOIN menu AS m ON s.product_id = m.product_id
	WHERE order_date >= join_date
    )
SELECT customer_id, product_name
FROM cte6
WHERE rnk = 1;
```
#### Explanation
- Only customers A and B are members, so we need to make sure that customer C does not appear in the results.
- JOIN multiple times to get ```order_date``` from ```sales```, ```join_date``` from ```members```, and ```product_name``` from ```menu```
- Create a CTE from the joined tables, with ```RANK () OVER (PARTITION BY s.customer_id ORDER BY s.order_date ASC)``` and filtering for ```order_date``` after ```join_date```
- SELECT rows from the CTE with ```rnk``` of 1.
#### Answer
| customer_id | product_name |
|-------------|--------------|
| A           | curry        |
| B           | sushi        |

### 7. Which item was purchased just before the customer became a member?
#### Code
``` sql
WITH cte7 AS (
    SELECT s.customer_id, order_date, m.product_name,
			RANK () OVER (PARTITION BY s.customer_id ORDER BY s.order_date DESC) AS rnk
	FROM sales AS s
	JOIN members AS mem ON s.customer_id = mem.customer_id
	JOIN menu AS m ON s.product_id = m.product_id
	WHERE order_date < join_date
    )
SELECT customer_id, product_name
FROM cte7
WHERE rnk = 1;
```
#### Explanation
- JOIN multiple times to get ```order_date``` from ```sales```, ```join_date``` from ```members```, and ```product_name``` from ```menu```
- Create a CTE from the joined tables, with ```RANK () OVER (PARTITION BY s.customer_id ORDER BY s.order_date DESC)``` and filtering for ```order_date``` before ```join_date```
- SELECT rows from the CTE with ```rnk``` of 1.
#### Answer
| customer_id | product_name |
|-------------|--------------|
| A           | sushi        |
| A           | curry        |
| B           | sushi        |

### 8. What is the total items and amount spent for each member before they became a member?
#### Code
``` sql
SELECT s.customer_id AS customer, 
	COUNT(order_date) AS total_items,
    SUM(price) AS total_spend
FROM sales AS s
JOIN members AS mem ON s.customer_id = mem.customer_id
JOIN menu AS m ON s.product_id = m.product_id
WHERE order_date < join_date
GROUP BY s.customer_id;
```
#### Explanation
- JOIN multiple times to get ```order_date``` from ```sales```, ```join_date``` from ```members```, and ```product_name``` from ```menu```
- Filter for ```order_date``` before ```join_date```
- GROUP BY customer_id and use COUNT and SUM to get the required figures.
#### Answer
| customer | total_items | total_spend |
|----------|-------------|-------------|
| A        | 2           | 25          |
| B        | 3           | 40          |

### 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
#### Code
``` sql
SELECT s.customer_id AS customer, 
	SUM(CASE WHEN s.product_id = 1 THEN price * 2*10 ELSE price*10 END) AS points
FROM sales AS s
JOIN members AS mem ON s.customer_id = mem.customer_id
JOIN menu AS m ON s.product_id = m.product_id
WHERE order_date < join_date
GROUP BY s.customer_id;
```
#### Explanation
- JOIN multiple times to get ```order_date``` from ```sales```, ```join_date``` from ```members```, and ```product_name``` from ```menu```
- Filter for ```order_date``` on or after the ```join_date```.
- GROUP BY  ```customer_id```
- SUM CASE WHEN to handle the points multipliers.
#### Answer
| customer | points |
|----------|--------|
| A        | 510    |
| B        | 440    |

### 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
#### Code
``` sql
WITH cte10 AS (
    SELECT s.customer_id, s.order_date, s.product_id, m.product_name, m.price, mem.join_date,
		CASE 
			WHEN order_date BETWEEN join_date AND DATEADD(DAY, 6, join_date) THEN price*10*2
            WHEN s.product_id = 1 THEN price*10*2
        ELSE price*10
	END AS points
	FROM sales AS s
	JOIN members AS mem ON s.customer_id = mem.customer_id
	JOIN menu AS m ON s.product_id = m.product_id
	WHERE order_date BETWEEN '2021-01-01' AND '2021-01-31'
    )
SELECT customer_id,
	SUM(points) AS jan_points
FROM cte10
GROUP BY customer_id;
```
#### Explanation
- Create a CTE
	- JOIN multiple times to get ```order_date``` from ```sales```, ```join_date``` from ```members```, and ```product_name``` from ```menu```
	- Filter for ```order_date``` during January
   	- Use CASE WHEN to assign 2x points during the first week after joining, 2x points on sushi always, and 1x points on all other purchases.
-SELECT the SUM of points from the CTE.
	
#### Answer
| customer_id | jan_points |
|-------------|------------|
| A           | 1370       |
| B           | 820        |
