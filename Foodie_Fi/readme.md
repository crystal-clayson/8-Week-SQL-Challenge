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
### 1. Write a brief description of the onboarding journey for the 8 customers in the sample data from the ```subscriptions``` table.

## B. Data Analysis

## C. Payments Table

