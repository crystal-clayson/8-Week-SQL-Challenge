# Case Study - Danny's Dinner
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

