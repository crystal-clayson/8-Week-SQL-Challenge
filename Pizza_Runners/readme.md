# Case Study - Pizza Runners
## Business Task
## Data Overview
The data comprises six tables.
![Data Relationship Diagram](/images/pizza_runners_database_diagram.png)
## Data Cleaning
We need to do some data cleaning to standardize the data before doing any analysis. We'll start with the ```customer_orders``` table. 

![Uncleaned data](/images/p_r_0_1.png)

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
![Result](/images/p_r_0_2.png)
