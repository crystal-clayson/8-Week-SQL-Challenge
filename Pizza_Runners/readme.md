# Case Study - Pizza Runners
- [Case Study - Pizza Runners](#case-study---pizza-runners)
  * [Business Task](#business-task)
  * [Data Overview](#data-overview)
  * [Data Cleaning](#data-cleaning)

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
