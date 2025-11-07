# Case Study - Pizza Runners
## Business Task
## Data Overview
The data comprises six tables.
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
