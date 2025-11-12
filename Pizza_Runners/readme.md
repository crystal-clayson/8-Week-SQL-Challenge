- [Case Study - Pizza Runners](#case-study---pizza-runners)
  * [Business Task](#business-task)
  * [Data Overview](#data-overview)
  * [Data Cleaning](#data-cleaning)
  * [A. Pizza Metrics](#a-pizza-metrics)
  * [B. Runner and Customer Experience](#b-runner-and-customer-experience)
  * [C. Ingredient Optimisation](#c-ingredient-optimisation)
  * [D. Pricing and Ratings](#d-pricing-and-ratings)
  * [E. Menu Expansion](#e-menu-expansion)

# Case Study - Pizza Runners

## Business Task
After the success of his Japanese eatery, Danny has now opened a pizza delivery business. He has recruited runners to deliver pizzas from Pizza Runner Headquarters. Danny has gathered data regarding orders and needs us to clean and analyze the data to optimise operations.

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

Finally, upon reviewing the list of questions given by the stakeholder, a request for "Meat Lovers" in the results stands out in question C4, while the ```pizza_names``` table lists the pizza as "Meatlovers". Hypothetically, I would ask the owner if the pizza was meant to be "Meat Lovers" from the beginning, in which case I would run an ```UPDATE``` statement to fix the error. 
```sql
UPDATE pizza_names
SET pizza_name = 'Meat Lovers'
WHERE pizza_name = 'Meatlovers';
```
![Clean pizza_names table](/images/p_r_0_5.png)

The remainder of the tables appear ready to use.
```sql
SELECT * FROM runners;
SELECT * FROM pizza_recipes;
SELECT * FROM pizza_toppings;
```
![runners, pizza_recipes, pizza_toppings tables](/images/p_r_0_6.png)

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
| runner_id | order_id | avg_km_hr |
|-----------|----------|-----------|
| 1         | 1        | 37.50     |
| 1	        | 2        | 44.44     |
| 1	        | 3        | 40.20     |
| 1	        | 10	   | 60.00     |
| 2         | 4        | 35.10     |
| 2         | 7        | 60.00     |
| 2	        | 8        | 93.60     |
| 2	        | 9        | NULL      |
| 3	        | 5        | 40.00     |
| 3	        | 6        | NULL      |

### 7. What is the successful delivery percentage for each runner?
#### Explanation
For each runner, this code calculates the percentage of completed orders out of the total orders assigned.
#### Code
```sql
SELECT runner_id, 
	COUNT(CASE WHEN cancellation = '' THEN 1 END)*1.00/COUNT(*)*100.00 AS success_rate
FROM runner_orders
GROUP BY runner_id
ORDER BY runner_id;
```
#### Results
| runner_id | success_rate |
|-----------|--------------|
| 1         | 100.00       |
| 2         | 75.00        |
| 3         | 50.00        |

## C. Ingredient Optimisation
### 1. What are the standard ingredients for each pizza?
#### Explanation
As a reminder, the ```pizza_recipes``` table lists the toppings in a string of the topping id's. 
| pizza_id | toppings                |
|----------|-------------------------|
| 1        | 1, 2, 3, 4, 5, 6, 8, 10 |
| 2        | 4, 6, 7, 9, 11, 12      |

The first task to answer this question is to expand these comma separated strings and ```CROSS APPLY``` them to the ```pizza_id``` column. Next, the result is joined with the ```pizza_toppings``` table to bring in the topping names, for clarity, grouped by ```topping_name```, and ordered by the count of each group. Finally, we add a ```TOP 1 WITH TIES``` clause to the ```SELECT``` statement to select only the top results. 

#### Code
```sql
SELECT TOP 1 WITH TIES pt.topping_name
FROM pizza_recipes
CROSS APPLY string_split(toppings, ',') AS ss
JOIN pizza_toppings AS pt ON ss.value = pt.topping_id
GROUP BY pt.topping_name
ORDER BY COUNT(*) DESC
```
#### Results
| topping_name  |
|---------------|
| Cheese	    |
| Mushrooms	    |

### 2. What was the most commonly added extra?
#### Explanation
Similarly to the previous question, the ```extras``` column in the ```customer_orders``` table is in a comma separated string with the topping id's. We need to use ```CROSS APPLY``` again to break those strings into useable values. After that, we'll ```JOIN``` to the ```pizza_toppings``` so we can use the topping name in the results, and group by ```topping_name```, order by the ```COUNT``` of each group, then select the topping name with the highest count.
#### Code
```sql
SELECT TOP 1 WITH TIES pt.topping_name , COUNT(*) AS excl_count
FROM customer_orders
CROSS APPLY string_split(exclusions, ',') AS ss
JOIN pizza_toppings AS pt ON pt.topping_id = ss.value
GROUP BY pt.topping_name
ORDER BY COUNT(*) DESC;

```
#### Results
| topping_name |
|--------------|
| Bacon        |

### 3. What was the most common exclusion?
#### Explanation
This question is answered in nearly the same way as the previous question, but looking at the ```exclustions``` column in the ```customer_orders``` table.
#### Code
```sql
SELECT TOP 1 WITH TIES pt.topping_name , COUNT(*) AS excl_count
FROM customer_orders
CROSS APPLY string_split(exclusions, ',') AS ss
JOIN pizza_toppings AS pt ON pt.topping_id = ss.value
GROUP BY pt.topping_name
ORDER BY COUNT(*) DESC;
```
#### Results
| topping_name |
|--------------|
| Cheese       |

### 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
- Meat Lovers
- Meat Lovers - Exclude Beef
- Meat Lovers - Extra Bacon
- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
#### Explanation
The solution needs to handle orders with multiple identical items, such as order 4. We'll accomplish this by assigning each pizza in the ```customer_orders``` table a unique identifier using ```ROW_NUMBER```, with results stored in a CTE. Next, we'll create a pair of CTE's (one each for exclusions and extras) that first expand the comma separated ```exclusions``` and ```extras``` lissts of topping id's, then aggregate them back into lists of topping names. With these CTE's created, we will join them all together on the newly created ```pizza_number```, and join the ```pizza_names``` table on the ```pizza_id```. Finally, we'll use a ```CASE WHEN``` statement to account for every combination of exclusions and/or/nor extras with a ```CONCAT``` clause to bring together the parts of the requested order items. 
#### Code
```sql
WITH cte_customer_orders AS (
	SELECT 
		order_id, 
		pizza_id, 
		ROW_NUMBER() OVER (ORDER BY order_id) AS pizza_number,
		exclusions,
		extras
	FROM customer_orders
),
cte_excl AS (
 	SELECT order_id, pizza_number,
		STRING_AGG(pt.topping_name, ', ') AS excl_csv
	FROM cte_customer_orders AS co
	CROSS APPLY string_split(exclusions, ',') AS ss
	JOIN pizza_toppings AS pt ON pt.topping_id = ss.value
	GROUP BY co.order_id, pizza_number
 ),
cte_extras AS (
	SELECT order_id, pizza_number,
		STRING_AGG(pt.topping_name, ', ') AS extra_csv
	FROM cte_customer_orders AS co
	CROSS APPLY string_split(extras, ',') AS ss
	JOIN pizza_toppings AS pt ON pt.topping_id = ss.value
	GROUP BY co.order_id, pizza_number
)
 SELECT co.order_id, co.pizza_id,
	CASE 
		WHEN co.exclusions = '' AND co.extras = '' THEN
			pn.pizza_name
		WHEN co.exclusions != '' AND co.extras = '' THEN
			CONCAT(pn.pizza_name, ' - Exclude ',  exc.excl_csv)
		WHEN co.exclusions = '' AND co.extras != '' THEN
			CONCAT(pn.pizza_name, ' - Extra ', ext.extra_csv)
		WHEN co.exclusions !='' AND co.extras != '' THEN
			CONCAT(pn.pizza_name, ' - Exclude ',  exc.excl_csv, ' - Extra ', ext.extra_csv)
	END AS order_item
 FROM cte_customer_orders AS co
 LEFT JOIN cte_excl AS exc ON co.pizza_number = exc.pizza_number
 LEFT JOIN cte_extras AS ext ON co.pizza_number = ext.pizza_number
 LEFT JOIN pizza_names AS pn ON co.pizza_id = pn.pizza_id
 ORDER BY co.order_id;
```
#### Results
| order_id | pizza_id |	order_item |
|----------|----------|------------|
| 1	| 1	| Meat Lovers |
| 2	| 1	| Meat Lovers |
| 3	| 1	| Meat Lovers |
| 3	| 2	| Vegetarian |
| 4	| 1	| Meat Lovers - Exclude Cheese |
| 4	| 1	| Meat Lovers - Exclude Cheese |
| 4	| 2	| Vegetarian - Exclude Cheese |
| 5	| 1	| Meat Lovers - Extra Bacon |
| 6	| 2	| Vegetarian |
| 7	| 2	| Vegetarian - Extra Bacon |
| 8	| 1	| Meat Lovers |
| 9	| 1	| Meat Lovers - Exclude Cheese - Extra Bacon, Chicken |
| 10 | 1 |	Meat Lovers |
| 10 | 1 |  Meat Lovers - Exclude BBQ Sauce, Mushrooms - Extra Bacon, Cheese |

### 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
- For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
#### Explanation
#### Code
```sql

WITH cte1 AS (
	SELECT co.pizza_id,
	ROW_NUMBER() OVER (ORDER BY order_id) AS pizza_number,
		CASE WHEN extras != ''
		THEN CONCAT(CASE WHEN exclusions != '' 
				THEN REPLACE(toppings, exclusions + ', ', '')
				ELSE toppings
			END, ', ', co.extras) 
		ELSE toppings
		END AS a
		FROM customer_orders co
		JOIN pizza_recipes pr ON co.pizza_id = pr.pizza_id 
),
cte2 AS (
	SELECT pizza_number, topping_name, COUNT(topping_name) AS N
	FROM cte1
	CROSS APPLY string_split(a, ',') as ss
	JOIN pizza_toppings AS pt ON ss.value = pt.topping_id
	GROUP BY pizza_number, topping_name, topping_id
)\
SELECT c1.pizza_number, 
	CONCAT(pn.pizza_name, ': ', string_agg(
		CASE
			WHEN N>1 THEN CONCAT(N,'x',topping_name)
			ELSE topping_name
		END,', ')) AS ingredient_list
FROM cte1 AS c1
JOIN cte2 AS c2 ON c1.pizza_number = c2.pizza_number
JOIN pizza_names AS pn ON c1.pizza_id = pn.pizza_id
GROUP BY c1.pizza_number, pn.pizza_name
ORDER BY c1.pizza_number;
```
#### Results
| pizza_number	| ingredient_list |
|---------------|-----------------|
| 1	| Meat Lovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
| 2	| Meat Lovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
| 3	| Meat Lovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
| 4	| Vegetarian: Cheese, Mushrooms, Onions, Peppers, Tomato Sauce, Tomatoes |
| 5	| Meat Lovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
| 6	| Meat Lovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
| 7	| Vegetarian: Cheese, Mushrooms, Onions, Peppers, Tomato Sauce, Tomatoes |
| 8	| Meat Lovers: 2xBacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
| 9	| Vegetarian: Cheese, Mushrooms, Onions, Peppers, Tomato Sauce, Tomatoes |
| 10 | Vegetarian: Bacon, Cheese, Mushrooms, Onions, Peppers, Tomato Sauce, Tomatoes |
| 11 | Meat Lovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
| 12 | Meat Lovers: 2xBacon, BBQ Sauce, Beef, 2xChicken, Mushrooms, Pepperoni, Salami |
| 13 | Meat Lovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
| 14 | Meat Lovers: 2xBacon, BBQ Sauce, Beef, 2xCheese, Chicken, Mushrooms, Pepperoni, Salami |

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
