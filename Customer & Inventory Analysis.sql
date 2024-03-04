/* The scale model cars database schema includes 8 tables: productLine, products, orderdetails, orders, payments, customers, employees and offices. 
Customers: customer data
Employees: all employee information
Offices: sales office information
Orders: customers' sales orders
OrderDetails: sales order line for each sales order
Payments: customers' payment records
Products: a list of scale model cars
ProductLines: a list of product line categories

Based on the database, let's find out some answers for this business to develop strategies. Those questions are: 
Question 1: Which products should we order more of or less of?
Question 2: How should we tailor marketing and communication strategies to customer behaviors?
Question 3: How much can we spend on acquiring new customers?


*/ 
-- First, let's take a look at the number of attributes and also the number of rows in each table.
SELECT 'Customers' AS table_name, 
       13 AS number_of_attribute,
       COUNT(*) AS number_of_row
  FROM Customers
  
UNION ALL

SELECT 'Products' AS table_name, 
       9 AS number_of_attribute,
       COUNT(*) AS number_of_row
  FROM Products

UNION ALL

SELECT 'ProductLines' AS table_name, 
       4 AS number_of_attribute,
       COUNT(*) AS number_of_row
  FROM ProductLines

UNION ALL

SELECT 'Orders' AS table_name, 
       7 AS number_of_attribute,
       COUNT(*) AS number_of_row
  FROM Orders

UNION ALL

SELECT 'OrderDetails' AS table_name, 
       5 AS number_of_attribute,
       COUNT(*) AS number_of_row
  FROM OrderDetails

UNION ALL

SELECT 'Payments' AS table_name, 
       4 AS number_of_attribute,
       COUNT(*) AS number_of_row
  FROM Payments

UNION ALL

SELECT 'Employees' AS table_name, 
       8 AS number_of_attribute,
       COUNT(*) AS number_of_row
  FROM Employees

UNION ALL

SELECT 'Offices' AS table_name, 
       9 AS number_of_attribute,
       COUNT(*) AS number_of_row
  FROM Offices;
  
-- Question 1: Which products should we order more of or less of? 
-- Products that are low in stock (product in demand) 

SELECT p.productName, 
                 p.productCode, 
				 ROUND(SUM(od.quantityOrdered)/p.quantityInStock,2) AS low_stock_products
  FROM products p
  JOIN orderdetails od
    ON p.productCode = od.productCode
 GROUP BY p.productCode 
 ORDER BY low_stock_products
LIMIT 10;

-- Performance of each product 

SELECT productCode,
                 ROUND(SUM(quantityOrdered * priceEach),2) AS product_performance 
  FROM orderdetails
 GROUP BY productCode 
 ORDER BY product_performance DESC
 LIMIT 10;

-- Priority products for restocking by low stock and product performance

  WITH low_stock AS (
    SELECT p.productName, 
                 p.productCode, 
				 ROUND(SUM(od.quantityOrdered)/p.quantityInStock,2) AS low_stock_products
	FROM products p
    JOIN orderdetails od
      ON p.productCode = od.productCode
   GROUP BY p.productCode 
   LIMIT 10
)

SELECT p.productCode, 
                 p.productName,
				 p.productLine,
				 ROUND(SUM(od.quantityOrdered * od.priceEach),2) AS product_performance 
  FROM products p
  JOIN orderdetails od 
    ON p.productCode = od.productCode
 WHERE od.productCode IN (   SELECT productCode FROM low_stock)
GROUP BY od.productCode
ORDER BY product_performance DESC
LIMIT 10; 



-- Question 2: How should we tailor marketing and communication strategies to customer behaviors?
/* In order to address the second question regarding customer information, our focus will be on
categorizing customers into two distinct groups: VIP (Very Important Person) customers and those
who display lower levels of engagement. This categorization allows us to develop targeted strategies
to meet the unique needs of each group.*/

-- TOP 5  VIP Customer
WITH cus_profit AS (
SELECT o.customerNumber,
		ROUND(SUM(quantityOrdered * 1.0 * (priceEach - buyPrice)), 2) profit
  FROM products p
  JOIN orderdetails od 
    ON p.productCode = od.productCode 
  JOIN orders o
    ON od.orderNumber = o.orderNumber 
 GROUP BY customerNumber 
) 
SELECT contactLastName, contactFirstName, city, country , profit
  FROM customers c 
  JOIN cus_profit cp
    ON c.customerNumber = cp.customerNumber
 ORDER BY profit DESC 
 LIMIT 5
 
-- 4. Top 5 less engaging customers
WITH cus_profit AS (
SELECT o.customerNumber,
		ROUND(SUM(quantityOrdered * 1.0 * (priceEach - buyPrice)), 2) profit
  FROM products p
  JOIN orderdetails od 
    ON p.productCode = od.productCode 
  JOIN orders o
    ON od.orderNumber = o.orderNumber 
 GROUP BY customerNumber 
) 
SELECT contactLastName, contactFirstName, city, country , profit
  FROM customers c 
  JOIN cus_profit cp
    ON c.customerNumber = cp.customerNumber
 ORDER BY profit  
 LIMIT 5

/* We can implement a two-pronged strategy to cater to both groups of customers. For VIP customers,
we can organize exclusive events and initiatives aimed at fostering loyalty and further enhancing their
satisfaction. For less engaged customers, we can launch specific campaigns and initiatives to re-engage
them, boosting their interest and involvement with our brand. By tailoring our efforts based on customer
categorization, we can effectively drive loyalty among our VIP customers and revitalize the engagement of
those who are less engaged. */ 


-- Question 3: How much can we spend on acquiring new customers?
--  Calculating new customers arriving each month

WITH 

payment_with_year_month_table AS (
SELECT *, 
       CAST(SUBSTR(paymentDate, 1,4) AS INTEGER)*100 + CAST(SUBSTR(paymentDate, 6,7) AS INTEGER) AS year_month
  FROM payments p
),

customers_by_month_table AS (
SELECT p1.year_month, COUNT(*) AS number_of_customers, SUM(p1.amount) AS total
  FROM payment_with_year_month_table p1
 GROUP BY p1.year_month
),

new_customers_by_month_table AS (
SELECT p1.year_month, 
       COUNT(*) AS number_of_new_customers,
       SUM(p1.amount) AS new_customer_total,
       (SELECT number_of_customers
          FROM customers_by_month_table c
        WHERE c.year_month = p1.year_month) AS number_of_customers,
       (SELECT total
          FROM customers_by_month_table c
         WHERE c.year_month = p1.year_month) AS total
  FROM payment_with_year_month_table p1
 WHERE p1.customerNumber NOT IN (SELECT customerNumber
                                   FROM payment_with_year_month_table p2
                                  WHERE p2.year_month < p1.year_month)
 GROUP BY p1.year_month
)

SELECT year_month, 
       ROUND(number_of_new_customers*100/number_of_customers,1) AS number_of_new_customers_props,
       ROUND(new_customer_total*100/total,1) AS new_customers_total_props
  FROM new_customers_by_month_table;

/* In order to establish an appropriate budget for acquiring new customers, it is essential to calculate
the Customer Lifetime Value (LTV), which indicates the average monetary value generated by a customer over
their entire relationship with a business. This calculation allows us to determine the optimal amount that
can be allocated towards marketing efforts. */  
--  Customer Lifetime Value (LTV)

WITH cus_profit AS (
SELECT o.customerNumber,
		ROUND(SUM(quantityOrdered * 1.0 * (priceEach - buyPrice)), 2) profit
  FROM products p
  JOIN orderdetails od 
    ON p.productCode = od.productCode 
  JOIN orders o
    ON od.orderNumber = o.orderNumber 
 GROUP BY customerNumber 
) 
SELECT ROUND(AVG(profit), 2) as customer_lifetime_value 
  FROM customers c 
  JOIN cus_profit cp
    ON c.customerNumber = cp.customerNumber
