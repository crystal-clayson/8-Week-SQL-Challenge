- [Case Study - Pizza Runners](#case-study---pizza-runners)
  * [Business Task](#business-task)
  * [Data Overview](#data-overview)
  * [Data Cleaning](#data-cleaning)
  * [A. Pizza Metrics](#a-pizza-metrics)
  * [B. Runner and Customer Experience](#b-runner-and-customer-experience)
  * [C. Ingredient Optimisation](#c-ingredient-optimisation)
  * [D. Pricing and Ratings](#d-pricing-and-ratings)
  * [E. Menu Expansion](#e-menu-expansion)

<small><i><a href='http://ecotrust-canada.github.io/markdown-toc/'>Table of contents generated with markdown-toc</a></i></small>

# Case Study - Pizza Runners

## Business Task
After the success of his Japanese eatery, Danny has now opened a pizza delivery business. He ahs recruited runners to deliver pizzas from Pizza Runner Headquarters. Danny has gathered data regarding orders and needs us to clean and analyze the data to optimise operations.

## Data Overview
The data comprises six tables. The ```runners``` table lists the ```runner_id``` and ```registration_date``` for each runner. The ```customer_orders``` table details each order, with a row for each pizza in the order. The ```pizza_id``` relates to the type of pizza which was ordered whilst the exclusions are the ```ingredient_id values``` which should be removed from the pizza and the ```extras``` are the ```ingredient_id``` values which need to be added to the pizza. This table also includes the ```order_time``` timestamp.

The ```runner_orders``` table shows the ```runner_id``` assigned to each order, as well as the ```pickup_time```, ```distance```, and ```duration``` that describe each delivery trip. If the order was cancelled before pickup, this information is in the ```cancellation``` column.

The ```pizza_names``` table related the ```pizza_id``` to the ```pizza_name```. The ```pizza_recipes``` table lists the ```toppings``` for each ```pizza_id```. Finally, the ```pizza_toppings``` table shows what each topping is.

![Data Relationship Diagram](/images/pizza_runners_database_diagram.png)

## Data Cleaning
We need to do some data cleaning to standardize the data before doing any analysis. We'll start with the ```customer_orders``` table. 

![Dirty customer_orders table](/images/p_r_0_1.png)

Looking at the ```exclusions``` and ```extras``` columns, we see some ```'null'``` and ```NULL``` values, and will set those to empty strings.

``` sql
UPDATE customer_orders
SET exclusions = ''
WHERE exclusions = 'null';

UPDATE customer_orders
SET extras = ''
WHERE extras = 'null' OR 
	extras IS NULL;
```
![Clean customer_orders table](/images/p_r_0_2.png)

The ```runner_orders``` table also has non-standardized handling of missing values.
![Dirty runner_orders table](/images/p_r_0_3.png)
For the ```cancellation``` column, we'll set missing values to empty strings. However, we will need to do some calculations later with the  ```pickup_times```, ```distance``` and ```duration``` columns, and will set these to ```NULL```.
```sql
UPDATE runner_orders
SET cancellation = ''
WHERE cancellation = 'null'
	OR cancellation IS NULL;

UPDATE runner_orders
SET pickup_time = NULL
WHERE pickup_time = ''
	OR pickup_time = 'null';

UPDATE runner_orders
SET distance = NULL
WHERE distance = ''
	OR distance = 'null';

UPDATE runner_orders
SET duration = NULL
WHERE duration = ''
	OR duration = 'null';
```
We also need to standardize the ```distance``` and ```duration``` columns and finally, change the data type so we can run calculations on them later.

```sql
UPDATE runner_orders
	SET distance = TRIM('kms ' FROM distance);
UPDATE runner_orders
	SET duration = TRIM('minutes ' FROM duration);

ALTER TABLE runner_orders
ALTER COLUMN duration DECIMAL(3,1);
ALTER TABLE runner_orders
ALTER COLUMN distance DECIMAL(3,1);
```
![Clean runner_orders](/images/p_r_0_4.png)

The remainder of the tables appear ready to use.
```sql
SELECT * FROM runners;
SELECT * FROM pizza_names;
SELECT * FROM pizza_recipes;
SELECT * FROM pizza_toppings;
```
![runners, pizza_names, pizza_recipes, and pizza_toppings tables](/images/p_r_0_5.png)

## A. Pizza Metrics
### 1. How many pizzas were ordered?
#### Explanation
The ```customer_orders``` table has one row for each pizza ordered, so we will do a ```COUNT``` of all rows ```FROM customer_orders``` to find the total number of pizzas ordered.
#### Code
``` sql
SELECT COUNT(*) AS total_pizzas
FROM customer_orders; 
```
#### Results
|total_pizzas|
|------------|
|      14    |

### 2. How many unique customer orders were made?
#### Explanation
The ```runner_orders``` table has one row for each customer order, so we will do a ```COUNT``` of all rows ```FROM runner_orders``` to find the total number of unique customer orders.
#### Code
```sql
SELECT COUNT(*) AS total_orders
FROM runner_orders;
```
#### Results
|total_orders|
|------------|
|     10     |

### 3. How many successful orders were delivered by each runner?
#### Explanation
Using the ```runner_orders``` table, we need to filter out orders that were cancelled before pickup, then group by the runner id and count each row.
#### Code
```sql
SELECT runner_id, 
	COUNT(*) AS orders_delivered
FROM runner_orders
WHERE cancellation = ''
GROUP BY runner_id;
```
#### Results
|runner_id|orders_delivered|
|---------|----------------|
|    1    |       4        |
|    2    |       3        |
|    3    |       1        |

### 4. How many of each type of pizza was delivered?
We'll need to pull ``` pizza_id``` from the ```customer_orders``` table, ```pizza_name``` from the ```pizza_names``` table, and ```cancellation``` from the ```runner_orders``` table. Then, we'll filter to remove orders that weren't delivered, group by the pizza name, and count all rows in each group.
#### Explanation
#### Code
```sql
SELECT pn.pizza_name, COUNT(*) AS total_delivered
FROM runner_orders AS ro
JOIN customer_orders AS co
	ON ro.order_id = co.order_id
JOIN pizza_names AS pn
	ON co.pizza_id = pn.pizza_id
WHERE cancellation = ''
GROUP BY pn.pizza_name;
```
#### Results
| pizza_name | total_delivered |
|------------|-----------------|
| Meatlovers |        9        |
| Vegetarian |        3        |

### 5. How many Vegetarian and Meatlovers were ordered by each customer?
#### Explanation
We'll join the 	```pizza_names``` table to the ```customer_orders``` table so that we can include the pizza name in our result for better understanding of the results. Then, aggregate the data by both ```pizza_name``` and ```customer_id``` and count each row.
#### Code
```sql
SELECT co.customer_id, pn.pizza_name, COUNT(*) AS total_ordered
FROM customer_orders AS co
JOIN pizza_names AS pn
	ON co.pizza_id = pn.pizza_id
GROUP BY pn.pizza_name, co.customer_id
ORDER BY co.customer_id
```
#### Results
| customer_id | pizza_name | total_ordered |
|-------------|------------|---------------|
| 101 |	Meatlovers |	2 |
| 101 |	Vegetarian |	1 |
| 102 |	Meatlovers |	2 |
| 102 |	Vegetarian |	1 |
| 103 |	Meatlovers |	3 |
| 103 |	Vegetarian |	1 |
| 104 |	Meatlovers |	3 |
| 105 |	Vegetarian |	1 |

### 6. What was the maximum number of pizzas delivered in a single order?
#### Explanation
We'll need to filter out cancelled orders, so we'll first join the ```customer_orders``` and ```runner_orders``` tables. Then we'll filter, group by the order id, and select the highest count of pizza id's. 
#### Code
```sql
SELECT TOP 1 COUNT(*) AS pizzas
FROM runner_orders AS ro
JOIN customer_orders AS co
	ON ro.order_id = co.order_id
WHERE cancellation = ''
GROUP BY co.order_id
ORDER BY COUNT(co.pizza_id) DESC;
```
#### Results
| pizzas |
|--------|
| 3      |

### 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
#### Explanation
After joing the ```runner_orders``` and ```customer_orders``` tables, filtering out cancelled orders, and grouping by the customer id, we'll use COUNT CASE WHEN statements to calculate the changed and unchaged pizza totals.
#### Code
```sql
SELECT customer_id, 
	COUNT(CASE WHEN exclusions != '' OR extras !='' THEN 1 END) AS total_changes,
	COUNT(CASE WHEN extras = '' AND exclusions = '' THEN 1 END) AS total_plain
FROM runner_orders AS ro
JOIN customer_orders AS co
	ON ro.order_id = co.order_id
WHERE cancellation = ''
GROUP BY customer_id;
```
#### Results
| customer_id |	total_changes |	total_plain |
|-------------|---------------|-------------|
| 101         |	0 			  |	2 			|
| 102		  |	0             |	3 			|
| 103		  |	3 			  |	0 			|
| 104      	  |	2 			  |	1 			|
| 105 		  |	1 			  |	0 			|

### 8. How many pizzas were delivered that had both exclusions and extras?
#### Explanation
After joing the ```runner_orders``` and ```customer_orders``` tables,and filtering out cancelled orders, we'll use a COUNT CASE WHEN statement to calculate the total number of special pizzas.
#### Code
```sql
SELECT COUNT(CASE WHEN exclusions != '' AND extras != '' THEN 1 END) AS total_special
FROM runner_orders AS ro
JOIN customer_orders AS co
	ON ro.order_id = co.order_id
WHERE cancellation = '';
```
#### Results
| total_special |
|---------------|
| 1 			|

### 9. What was the total volume of pizzas ordered for each hour of the day?
#### Explanation
We need to use ```DATENAME``` in both the ```SELECT``` and ```GROUP BY``` statements to group the results by hour. 
#### Code
```sql
SELECT DATEPART(hh, order_time) AS hour,
	COUNT(*) AS pizza_volume
FROM customer_orders
GROUP BY DATEPART(hh, order_time)
ORDER BY DATEPART(hh, order_time);
```
#### Results
| hour | pizza_volume | 
|------|--------------|
| 11   | 	1 		  | 
| 13   | 	3 		  | 
| 18   | 	3 		  | 
| 19   | 	1 		  | 
| 21   | 	3 		  | 
| 23   | 	3 		  | 

### 10. What was the volume of orders for each day of the week?
#### Explanation
We need to use ```DATENAME``` in both the ```SELECT``` and ```GROUP BY``` statements. We will also used ```DATEPART``` in the ````GROUP BY``` and ```ORDER BY``` statements so that the results will be in consequtive order.
#### Code
```sql
SELECT DATENAME(DW, order_time) AS day, COUNT(*) AS pizzas
from customer_orders
GROUP BY DATENAME(DW, order_time), DATEPART(DW, order_time)
ORDER BY DATEPART(DW, order_time);
```
#### Results
| day       |	pizzas |
|-----------|----------|
| Wednesday	| 5        |
| Thursday	| 3 	   |
| Friday	| 1 	   |	
| Saturday	| 5  	   |

## B. Runner and Customer Experience
### 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
#### Explanation
The function ```DATEPART(wk, date)``` will return the week number, with the first week of the year beginning on January 1, so we'll use ```DATEPART(wk, regisration_date) to group runner registrations into weeks, then ```COUNT``` all rows.
#### Code
```sql
SELECT DATEPART(wk, registration_date) AS week, COUNT(*) AS signups
FROM runners
GROUP BY DATEPART(wk, registration_date)
ORDER BY DATEPART(wk, registration_date);
```
#### Results
| week | 	signups | 
|------|------------|
| 1    | 	2       | 
| 2    | 	1       | 
| 3    | 	1       | 

### 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
#### Explanation
We need to use a subquery to select the unique ```order_id``` and ```customer_id``` pairs, then calculate the average of the difference between the ```order_time``` and ```pickup_time```.
#### Code
```sql
SELECT ro.runner_id, AVG(DATEDIFF(MINUTE, co.order_time, ro.pickup_time)) AS leadtime
FROM (SELECT DISTINCT order_id, customer_id, order_time FROM customer_orders) AS co
JOIN runner_orders AS ro ON co.order_id = ro.order_id
GROUP BY ro.runner_id;
```
#### Results
| runner_id | avg_leadtime |
|-----------|--------------|
| 1	        | 14           |
| 2	        | 20           |
| 3	        | 10           |

### 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
#### Explanation
We need to copare the average prep time for each order quantity. To do so, we will create a CTE with ```order_id```, ```order_time```, and a ```COUNT``` of pizzas in each order from the ```customer_orders``` table. Once we have that CTE, we'll ```JOIN``` with the ```runner_orders``` table to bring in the ```pickup_time``` so that we can calculate the average preptime for orders of quantity 1, 2, and 3, as well as the average time per pizza.
#### Code
```sql
WWITH cte_count AS (
	SELECT order_id, order_time, COUNT(pizza_id) AS quantity
	FROM customer_orders
	GROUP BY order_id, order_time
    )
SELECT quantity,
	COUNT(*) AS no_of_orders,
	AVG(CAST(DATEDIFF(MINUTE, order_time, pickup_time) AS FLOAT)) AS avg_preptime,
	AVG(CAST(DATEDIFF(MINUTE, order_time, pickup_time) AS FLOAT))/quantity AS avg_per_pizza
FROM cte_count AS co
JOIN runner_orders AS ro ON co.order_id = ro.order_id
WHERE cancellation = ''
GROUP BY quantity
ORDER BY quantity;
```
#### Results
While the average time per pizza decreases somewhat for larger quantity orders, the average total prep time increases. To decrease the prep time for larger orders, we recommend investing in ovens with a larger capacity so that all pizzas in an order leave the oven at approximately the same time. However, it is important to note that the calculations may not reflect effeciency gains with larger numbers of multi-pizza orders.
| quantity | no_of_orders | avg_preptime | avg_per_pizza |
|----------|--------------|--------------|---------------|
| 1        | 5            | 12.2         | 12.2          |
| 2        | 2            | 18.5         | 9.25          |
| 3        | 1            | 30           | 10            |


### 4. What was the average distance travelled for each customer?
#### Explanation
We will use a subquery in the ```FROM``` statement to pull unique ```order_id``` and ```customer_id``` pairs from the ```customer_orders``` table. Then we'll ```JOIN``` with the ```runner_orders``` table to bring in the distance traveled to each customer. Finally, we'll take the average distance, grouped by ```customer_id```.
#### Code
```sql
SELECT co.customer_id, AVG(ro.distance ) AS avg_distance
FROM (SELECT DISTINCT order_id, customer_id FROM customer_orders) AS co
 JOIN runner_orders AS ro ON co.order_id = ro.order_id
GROUP BY customer_id;
```
#### Results
| customer_id |	avg_distance |
|-------------|--------------|
| 101		  |	20.000000	 |
| 102 		  |	18.400000	 |
| 103		  |	23.400000	 |
| 104		  |	10.000000	 |
| 105		  |	25.000000	 |

### 5. What was the difference between the longest and shortest delivery times for all orders?
#### Explanation
This query will find the shortest and longest ```duration```, and calculate the difference.
#### Code
```sql
SELECT min(duration) AS shortest, 
	max(duration) AS longest, 
	max(duration)-min(duration) AS difference
FROM runner_orders;
```
#### Results
| shortest | longest | difference |
|----------|---------|------------|
| 10.0     | 40.0    | 30.0       |

### 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
#### Explanation
This question just needs a speed calculation using the ```distance``` and ```duration``` from the ```runner_orders``` table.
#### Code
```sql
SELECT runner_id, order_id, ROUND(distance/(duration/60),2) AS avg_km_hr
FROM runner_orders
ORDER BY runner_id, order_id;
```
#### Results
runner_id	order_id	avg_km_hr
1	1	37.5000000000
1	2	44.4400000000
1	3	40.2000000000
1	10	60.0000000000
2	4	35.1000000000
2	7	60.0000000000
2	8	93.6000000000
2	9	NULL
3	5	40.0000000000
3	6	NULL

### 7. What is the successful delivery percentage for each runner?
#### Explanation
#### Code
#### Results

## C. Ingredient Optimisation
### 1. What are the standard ingredients for each pizza?
#### Explanation
#### Code
#### Results
### 2. What was the most commonly added extra?
#### Explanation
#### Code
#### Results
### 3. What was the most common exclusion?
#### Explanation
#### Code
#### Results
### 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
- Meat Lovers
- Meat Lovers - Exclude Beef
- Meat Lovers - Extra Bacon
- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
#### Explanation
#### Code
#### Results
### 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
- For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
#### Explanation
#### Code
#### Results
### 6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
#### Explanation
#### Code
#### Results

## D. Pricing and Ratings
### 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
#### Explanation
#### Code
#### Results
### 2. What if there was an additional $1 charge for any pizza extras?
- Add cheese is $1 extra
#### Explanation
#### Code
#### Results
### 3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
#### Explanation
#### Code
#### Results
### 4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
- customer_id
- order_id
- runner_id
- rating
- order_time
- pickup_time
- Time between order and pickup
- Delivery duration
- Average speed
- Total number of pizzas
#### Explanation
#### Code
#### Results
### 5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?
#### Explanation
#### Code
#### Results
## E. Menu Expansion
### 1. If Danny wants to expand his range of pizzas - how would this impact the existing data design? Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?
#### Explanation
#### Code
#### Results
