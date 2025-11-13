# Case Study - Foodie_Fi
## Table of Contents
- [Introduction](introduction)
- [Data Overview](data-overview)
- [A. Customer Journey](a.-customer-journey)
- [B. Data Analysis](b.-data-analysis)
- [C. Payments Table](c.-payments-table)

## Introduction
Foodie Fi is a food focused subscription based streaming service with video content from around the world. They offer several subscription plans- basic monthly, pro monthly, and pro yearly. Every customer gets a one week free trial before beginning the paid subscription of their choice.

## Data Overview
The Foodie Fi database has only two tables- ```plans``` and ```customers```.

![Database Relationship Diagram](/images/f_f_0_1.png)

The ```plans``` table lists the ```plan_id```, ```plan_name```, and ```price```. 'Churn' is included as a plan to indicate when a customer cancels their subscription. The primary key for this table is ```plan_id```

| plan_id	| plan_name	    | price |
|---------|---------------|-------|
| 0	      | trial	        | 0     |
| 1	      | basic monthly	| 9.90  |
| 2	      | pro monthly	  | 19.90 |
| 3	      | pro annual	  | 199   |
| 4	      | churn         |	null  | 

The ```subscriptions``` table lists each ```customer_id```, the ```plan_id``` for every subscription that customer has had, and the ```start_date``` for each subcription. The foreign key ```plan_id``` ties this table to ```plans```. A sample of this data is provided below.
| customer_id	| plan_id	| start_date |
|-------------|---------|------------|
| 1	          | 0	      | 2020-08-01 |
| 1	          | 1	      | 2020-08-08 |
| 2	          | 0	      | 2020-09-20 |
| 2	          | 3	      | 2020-09-27 |
| 11	        | 0	      | 2020-11-19 |
| 11	        | 4	      | 2020-11-26 |
| 13	        | 0	      | 2020-12-15 |
| 13	        | 1	      | 2020-12-22 |
| 13	        | 2	      | 2021-03-29 |
| 15	        | 0	      | 2020-03-17 |
| 15	        | 2	      | 2020-03-24 |
| 15	        | 4	      | 2020-04-29 |
| 16	        | 0	      | 2020-05-31 |
| 16	        | 1	      | 2020-06-07 |
| 16	        | 3	      | 2020-10-21 |
| 18	        | 0	      | 2020-07-06 |
| 18	        | 2	      | 2020-07-13 |
| 19	        | 0	      | 2020-06-22 |
| 19	        | 2	      | 2020-06-29 |
| 19	        | 3	      | 2020-08-29 |

## A. Customer Journey
### 1. Write a brief description of the onboarding journey for the 8 customers in the sample data from the ```subscriptions``` table. Try to keep it as short as possible - you may also want to run some sort of join to make your explanations a bit easier!
#### Explanation
We wrote a query to generate a short description of customer onboarding, which will handle both customers who enroll after the free trial and customers who churn without subscribing.

After a free trial period beginning 2020-08-01, Customer 1 successfully enrolled in the basic monthly subscription on 2020-08-08.
After a free trial period beginning 2020-09-20, Customer 2 successfully enrolled in the pro annual subscription on 2020-09-27.
Unfortunatly, Customer 11 chose not to enroll in a plan after their free trial ended on 2020-12-03.
After a free trial period beginning 2020-12-15, Customer 13 successfully enrolled in the basic monthly subscription on 2020-12-22.
After a free trial period beginning 2020-03-17, Customer 15 successfully enrolled in the pro monthly subscription on 2020-03-24.
After a free trial period beginning 2020-05-31, Customer 16 successfully enrolled in the basic monthly subscription on 2020-06-07.
After a free trial period beginning 2020-07-06, Customer 18 successfully enrolled in the pro monthly subscription on 2020-07-13.
After a free trial period beginning 2020-06-22, Customer 19 successfully enrolled in the pro monthly subscription on 2020-06-29.

We began with a CTE that assigns a number to each row, which we will use to determine which ```plan_id``` came second for each customer. Then, we used a ```CASE WHEN` statement with ```CONCAT``` to generate a sentence for each customer.

#### Code
```sql
WITH CTE as (
SELECT customer_id, start_date,
	ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY start_date ASC) AS row
			FROM subscriptions
			)
SELECT CASE
		WHEN s.plan_id != 4
		THEN CONCAT('After a free trial period beginning ', DATEADD(DAY, -7, S.start_date), ', Customer ',s.customer_id, ' successfully enrolled in the ', 
				p.plan_name, ' subscription on ', s.start_date, '.')
		ELSE CONCAT('Unfortunatly, Customer ', s.customer_id, ' chose not to enroll in a plan after their free trial ended on ', DATEADD(DAY, 7, s.start_date), '.')
		END AS customer_journey
FROM subscriptions AS s
JOIN plans AS p ON s.plan_id = p.plan_id
JOIN CTE c ON s.customer_id = c.customer_id
	AND s.start_date = c.start_date
WHERE s.customer_id IN (1,2,11,13,15,16,18,19)
	AND row = 2;
```

## B. Data Analysis

## C. Payments Table

