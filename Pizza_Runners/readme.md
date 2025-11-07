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
#### Code
#### Results
### 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
#### Explanation
#### Code
#### Results
### 8. How many pizzas were delivered that had both exclusions and extras?
#### Explanation
#### Code
#### Results
### 9. What was the total volume of pizzas ordered for each hour of the day?
#### Explanation
#### Code
#### Results
### 10. What was the volume of orders for each day of the week?
#### Explanation
#### Code
#### Results


## B. Runner and Customer Experience
### 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
#### Explanation
#### Code
#### Results
### 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
#### Explanation
#### Code
#### Results
### 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
#### Explanation
#### Code
#### Results
### 4. What was the average distance travelled for each customer?
#### Explanation
#### Code
#### Results
### 5. What was the difference between the longest and shortest delivery times for all orders?
#### Explanation
#### Code
#### Results
### 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
#### Explanation
#### Code
#### Results
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
