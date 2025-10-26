# Case Study - Danny's Dinner
## Business Task
Danny’s Diner, a new Japanese restaurant, has asked for assistance in using customer data to help them run the business, and has provided a sample of customer data to work with. The stakeholders have asked for SQL queries to answer a series of questions. 
## Data Overview
The data given comprises three tables. 
![Entity Relationship Diagram](/images/dannys_diner_database_diagram.png)
## Case Study Questions
### 1. What is the total amount each customer spent at the restaurant?
``` sql
SELECT customer_id, 
	SUM(price) AS total_spent
FROM sales AS s
JOIN menu AS m on s.product_id = m.product_id
GROUP BY s.customer_id;
```
#### Explanation
- We need to JOIN the ```sales``` and ```menu``` tables, then GROUP BY ```sales.customer_id``` to find each sum.
#### Answer
| customer_id | total_spend |
| ----------- | ----------- |
| A           | 76          |
| B           | 74          |
| C           | 36          |
