/* ------------
   Case Study
   ------------*/

CREATE SCHEMA dannys_diner;

SET GLOBAL SQL_SAFE_UPDATES = 0;
USE dannys_diner;

CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
);


INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  
select * from menu;
CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
  -- 1. What is the total amount each customer spent at the restaurant?
  SELECT customer_id, sum(price) AS total_spent from sales s join menu M ON s.product_id = m.product_id 
  GROUP BY customer_id;
  
-- 2. How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(order_date) AS Times_visited FROM sales GROUP BY customer_id ;

-- 3. What was the first item from the menu purchased by each customer?
WITH ranked AS 
(SELECT customer_id, order_date, product_name, row_number() 
	OVER (PARTITION BY customer_id ORDER BY order_date) AS rn 
    FROM sales s JOIN menu m ON S.product_id = m.product_id )
SELECT customer_id, product_name 
FROM ranked WHERE rn = 1 ;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT product_name, COUNT(m.product_id) AS most_purchased FROM 
menu m JOIN sales s ON m.product_id = s.product_id 
group by product_name order by most_purchased DESC
LIMIT 1; 

-- 5. Which item was the most popular for each customer?

WITH items AS
(SELECT s.customer_id, m.product_name, COUNT(s.product_id) AS most_popular,  ROW_NUMBER()
	OVER (PARTITION BY s.customer_id ORDER BY COUNT(s.product_id) DESC) 
    AS rn
	FROM menu m JOIN sales s ON m.product_id = s.product_id 
    GROUP BY s.customer_id, m.product_name )
SELECT customer_id, product_name, most_popular FROM items WHERE rn = 1;

-- 6. Which item was purchased first by the customer after they became a member?
WITH after_purchase AS (
SELECT  V.customer_id, S.product_id, ROW_NUMBER() OVER( PARTITION BY V.customer_id ) AS rn
FROM sales S JOIN members V ON S.customer_id = V.customer_id 
WHERE S.order_date > V.join_date )
SELECT customer_id, product_id FROM purchase WHERE rn = 1;

-- 7. Which item was purchased just before the customer became a member?
WITH before_purchase AS (
SELECT  V.customer_id, S.product_id, V.join_date, S.order_date, ROW_NUMBER() OVER( PARTITION BY V.customer_id ORDER BY S.order_date DESC) AS rn
FROM sales S JOIN members V ON S.customer_id = V.customer_id 
WHERE S.order_date < V.join_date )
SELECT customer_id, product_id, join_date, order_date FROM before_purchase WHERE rn =1;

-- 8. What is the total items and amount spent for each member before they became a member?
WITH mem AS
(SELECT v.customer_id, COUNT(s.product_id) AS total_items, sum(m.price) AS amt_spend, ROW_NUMBER()
	OVER (PARTITION BY V.customer_id ORDER BY max(s.order_date) DESC) 
    AS rn
    FROM sales s JOIN members v ON s.customer_id = v.customer_id 
    join menu m on s.product_id = m.product_id
WHERE S.order_date < V.join_date GROUP BY customer_id)
SELECT customer_id, total_items, amt_spend FROM mem WHERE rn =1;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT S.customer_id , (sum(M.price)*20) AS points FROM sales S JOIN menu M ON S.product_id = M.product_id GROUP BY customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi 
-- - how many points do customer A and B have at the end of January?

WITH pts AS (
  SELECT 
    s.customer_id,
    CASE 
      WHEN s.order_date BETWEEN v.join_date AND DATE_ADD(v.join_date, INTERVAL 6 DAY) THEN SUM(m.price) * 2
      ELSE SUM(m.price)
    END AS earned_points
  FROM sales s
  JOIN members v ON s.customer_id = v.customer_id
  JOIN menu m ON s.product_id = m.product_id
  WHERE s.customer_id IN ('A', 'B')
    AND s.order_date <= '2021-01-31'
  GROUP BY s.customer_id, 
           CASE WHEN s.order_date BETWEEN v.join_date AND DATE_ADD(v.join_date, INTERVAL 6 DAY) THEN 1 ELSE 0 END
)
SELECT customer_id, SUM(earned_points) AS total_points
FROM pts
GROUP BY customer

