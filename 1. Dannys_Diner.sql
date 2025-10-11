/* --------------------
   Case Study Questions
   --------------------*/
   
/* --------------------
   Credit to https://8weeksqlchallenge.com/case-study-1/ for the case study scenario, data, and questions.
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
SELECT customer_id, 
	SUM(price) AS total_spent
FROM sales AS s
JOIN menu AS m on s.product_id = m.product_id
GROUP BY s.customer_id;

-- 2. How many days has each customer visited the restaurant?
SELECT customer_id, 
	COUNT(DISTINCT order_date) AS total_days
FROM sales 
GROUP BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?
WITH cte AS (
	SELECT customer_id, order_date, product_name,
		RANK () OVER (PARTITION BY customer_id ORDER BY order_date ASC) AS rnk,
		ROW_NUMBER () OVER(PARTITION BY customer_id ORDER BY order_date ASC) AS rnmb
	FROM sales AS s
	JOIN menu AS m ON s.product_id = m.product_id
    )
SELECT customer_id, product_name
FROM cte
WHERE rnmb = 1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT product_name, 
	COUNT(order_date) AS orders
FROM sales AS s
JOIN menu AS m ON s.product_id = m.product_id
GROUP BY product_name
ORDER BY orders DESC
LIMIT 1;

-- 5. Which item was the most popular for each customer?
WITH cte5 AS (
	SELECT customer_id, product_name,
		COUNT(order_date) AS orders,
		RANK () OVER (PARTITION BY customer_id ORDER BY COUNT(order_date) DESC) AS rnk
	FROM sales AS s
	JOIN menu AS m ON s.product_id = m.product_id
	GROUP BY product_name, customer_id
	)
SELECT *
FROM cte5
WHERE rnk = 1;

-- 6. Which item was purchased first by the customer after they became a member?
WITH cte6 AS (
    SELECT s.customer_id, order_date, m.product_name,
			RANK () OVER (PARTITION BY customer_id ORDER BY order_date ASC) AS rnk,
			ROW_NUMBER () OVER(PARTITION BY customer_id ORDER BY order_date ASC) AS rnmb
	FROM sales AS s
	JOIN members AS mem ON s.customer_id = mem.customer_id
	JOIN menu AS m ON s.product_id = m.product_id
	WHERE order_date >= join_date
    )
SELECT *
FROM cte6
WHERE rnk = 1;

-- 7. Which item was purchased just before the customer became a member?
WITH cte7 AS (
    SELECT s.customer_id, order_date, m.product_name,
			RANK () OVER (PARTITION BY customer_id ORDER BY order_date DESC) AS rnk,
			ROW_NUMBER () OVER(PARTITION BY customer_id ORDER BY order_date DESC) AS rnmb
	FROM sales AS s
	JOIN members AS mem ON s.customer_id = mem.customer_id
	JOIN menu AS m ON s.product_id = m.product_id
	WHERE order_date < join_date
    )
SELECT *
FROM cte7
WHERE rnk = 1;

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT s.customer_id AS Customer, 
	COUNT(order_date) AS Total_Items,
    SUM(price) AS Total_Spent
FROM sales AS s
JOIN members AS mem ON s.customer_id = mem.customer_id
JOIN menu AS m ON s.product_id = m.product_id
WHERE order_date < join_date
GROUP BY s.customer_id;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT s.customer_id AS Customer, 
	SUM(CASE WHEN s.product_id = 1 THEN price * 2*10 ELSE price*10 END) AS points
FROM sales AS s
JOIN members AS mem ON s.customer_id = mem.customer_id
JOIN menu AS m ON s.product_id = m.product_id
WHERE order_date < join_date
GROUP BY s.customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
WITH cte10 AS (
    SELECT s.customer_id, s.order_date, s.product_id, m.product_name, m.price, mem.join_date,
		CASE 
			WHEN order_date BETWEEN join_date AND join_date + 6 THEN price*10*2
            WHEN s.product_id = 1 THEN price*10*2
        ELSE price*10
	END AS points
	FROM sales AS s
	JOIN members AS mem ON s.customer_id = mem.customer_id
	JOIN menu AS m ON s.product_id = m.product_id
	WHERE order_date BETWEEN '2021-01-01' AND '2021-01-31'
    )
SELECT customer_id,
	SUM(points) AS jan_points
FROM cte10
GROUP BY customer_id
ORDER BY customer_id;

-- Bonus A Create a list of every item ordered, indicating whether the customer was a member at the time. 
SELECT s.customer_id, order_date, product_name, price,
	CASE WHEN order_date >= join_date THEN 'Y'
    ELSE 'N'
    END AS member
FROM sales AS s
LEFT JOIN members AS mem ON s.customer_id = mem.customer_id
LEFT JOIN menu AS m ON s.product_id = m.product_id
ORDER BY s.customer_id, s.order_date;

-- Bonus B Create a list ranking members' top products. Non-member purchases should return NULL
WITH cte_b AS (
SELECT s.customer_id, order_date, product_name, price,
	CASE WHEN order_date >= join_date THEN 'Y'
    ELSE 'N'
    END AS member
FROM sales AS s
LEFT JOIN members AS mem ON s.customer_id = mem.customer_id
LEFT JOIN menu AS m ON s.product_id = m.product_id
ORDER BY s.customer_id, s.order_date)
SELECT *,
	   CASE WHEN member = 'N' THEN NULL
	else DENSE_RANK () OVER (PARTITION BY s.customer_id, member ORDER BY order_date) 
    END AS ranking
FROM cte_b;

