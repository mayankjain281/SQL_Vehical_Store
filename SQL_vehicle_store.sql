/* 
         ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
         + Data Analysis Project: Customers and Products Analysis Using SQL +
         ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
															  By- Mayank Jain

 Introduction:

 As part of this project we will be analysing the scale care model datbase using SQL to answer following questions

 Question 1: Which products should we order more of or less of?
 Question 2: How should we tailor marketing and communication strategies to customer behaviors?
 Question 3: How much can we spend on acquiring new customers?

 Database Summary:

 The database contains 8 tables as follows.
   
 1) Customers:    Contains customer data; 'customerNumber' is the 'primary key'; 'salesRepEmployeeNumber' is the 'foreign key';
       		      Relationship with 'orders' and 'payments' tables on 'customerNumber'; 
				  Relationship with 'employees' table on 'salesRepEmployeeNumber'
					
 2) Employees:    Contains all employee information; 'employeeNumber' is the 'primary key'; 'officeCode' is the 'foreign key';
				  Relationship with 'offices' table on 'officeCode'; Relationship with 'customers' table on 'employeeNumber';
				  Self-relationship between 'employeeNumber' and 'reportsTo'
   
 3) Offices:      Contains sales office information; 'officeCode' is the 'primary key'; 
				  Relationship with 'employees' table on 'officeCode'
   
 4) Orders:       Contains customers' sales orders; 'orderNumber' is the 'primary key'; 'customerNumber' is the 'foreign key';
				  Relationship with 'customers' table on 'customerNumber'; 
				  Relationship with 'orderdetails' table on 'orderNumber'
   
 5) OrderDetails: Contains sales order line for each sales order; 'orderNumber' and 'productCode' are 'primary key';
                  'orderNumber' is also foreign key; Relationship with 'orders' table on 'orderNumber';
				  Relationship with 'products' table on 'productCode'
   
 6) Payments:     Contains customers' payment records; 'customerNumber' and 'checkNumber' are 'primary key';
                  'customerNumber' is also foreign key; Relationship with 'customers' table on 'customerNumber'
   
 7) Products:     Contains a list of scale model cars; 'productCode' is the 'primary key'; 'productLine' is the 'foreign key';
  				  Relationship 'orderdetails' table on 'productCode'; Relationship with 'productlines' table on 'productLine'
   
 8) ProductLines: Contains a list of product line categories; 'productLine' is the 'primary key';
				  Relationship with 'products' table on 'productLine' 

 */				 


 -- Name of Tables and descriptions

SHOW TABLES;
SELECT  * FROM (Select 'customers' as table_name, Count(*) as number_of_attributes FROM information_schema.columns WHERE table_name ='customers') a, (select count(*) as number_of_rows from customers) b
union all
SELECT  * FROM (Select 'employees' as table_name, Count(*) as number_of_attributes FROM information_schema.columns WHERE table_name ='employees') a, (select count(*) as number_of_rows from employees) b
union all
SELECT  * FROM (Select 'offices' as table_name, Count(*) as number_of_attributes FROM information_schema.columns WHERE table_name ='offices') a, (select count(*) as number_of_rows from offices) b
union all
SELECT  * FROM (Select 'orderdetails' as table_name, Count(*) as number_of_attributes FROM information_schema.columns WHERE table_name ='orderdetails') a, (select count(*) as number_of_rows from orderdetails) b
union all
SELECT  * FROM (Select 'orders' as table_name, Count(*) as number_of_attributes FROM information_schema.columns WHERE table_name ='orders') a, (select count(*) as number_of_rows from orders) b
union all
SELECT  * FROM (Select 'payments' as table_name, Count(*) as number_of_attributes FROM information_schema.columns WHERE table_name ='payments') a, (select count(*) as number_of_rows from payments) b
union all
SELECT  * FROM (Select 'productlines' as table_name, Count(*) as number_of_attributes FROM information_schema.columns WHERE table_name ='productlines') a, (select count(*) as number_of_rows from productlines) b
union all
SELECT  * FROM (Select 'products' as table_name, Count(*) as number_of_attributes FROM information_schema.columns WHERE table_name ='products') a, (select count(*) as number_of_rows from products) b;

  
-- Low stock using a correlated subquery.
 
SELECT productCode, 
       ROUND(SUM(quantityOrdered) / (SELECT quantityInStock
                                             FROM products p
                                            WHERE od.productCode = p.productCode), 2) AS low_stock
  FROM orderdetails od
 GROUP BY productCode
 ORDER BY low_stock DESC
 LIMIT 10;
  
  
-- Product performance
	 
SELECT productCode, 
       SUM(quantityOrdered * priceEach) AS prod_perf
  FROM orderdetails od
 GROUP BY productCode 
 ORDER BY prod_perf DESC;


-- Priority Products for restocking
   
WITH 
low_stock_table AS (
SELECT productCode, 
       ROUND(SUM(quantityOrdered)/(SELECT quantityInStock
                                           FROM products p
                                          WHERE od.productCode = p.productCode), 2) AS low_stock
  FROM orderdetails od
 GROUP BY productCode
 ORDER BY low_stock DESC
 LIMIT 10
)
SELECT productCode, 
       SUM(quantityOrdered * priceEach) AS prod_perf
  FROM orderdetails od
 WHERE productCode IN (SELECT productCode
                         FROM low_stock_table)
 GROUP BY productCode 
 ORDER BY prod_perf DESC
 LIMIT 10;


-- revenue by customer
  
  SELECT os.customerNumber, SUM(quantityOrdered * (priceEach - buyPrice)) AS profit_gen  
    FROM products pr
	JOIN orderdetails od
	  ON pr.productCode = od.productCode
	JOIN orders os
	  ON od.orderNumber = os.orderNumber
   GROUP BY os.customerNumber;
      
      
-- Top 5 VIP customers
  
  WITH
  profit_gen_table AS (
    SELECT os.customerNumber, SUM(quantityOrdered * (priceEach - buyPrice)) AS prof_gen  
      FROM products pr
	  JOIN orderdetails od
	    ON pr.productCode = od.productCode
	  JOIN orders os
	    ON od.orderNumber = os.orderNumber
     GROUP BY os.customerNumber
  )
	SELECT contactLastName, contactFirstName, city, country, pg.prof_gen
	  FROM customers cust
	  JOIN profit_gen_table pg
	    ON pg.customerNumber = cust.customerNumber
	 ORDER BY pg.prof_gen DESC
	 LIMIT 5;
	 
     
  -- bottom 5 customers less engaged
	  
  WITH
  profit_gen_table AS (
	SELECT os.customerNumber, SUM(quantityOrdered * (priceEach - buyPrice)) AS prof_gen  
      FROM products pr
	  JOIN orderdetails od
	    ON pr.productCode = od.productCode
	  JOIN orders os
	    ON od.orderNumber = os.orderNumber
     GROUP BY os.customerNumber
  )
	SELECT contactLastName, contactFirstName, city, country, pg.prof_gen
	  FROM customers cust
	  JOIN profit_gen_table pg
	    ON pg.customerNumber = cust.customerNumber
	 ORDER BY pg.prof_gen
	 LIMIT 5;
	 
     
  -- Average of customer lifetime value (LTV)
  
  WITH
  profit_gen_table AS (
	SELECT os.customerNumber, SUM(quantityOrdered * (priceEach - buyPrice)) AS prof_gen  
      FROM products pr
	  JOIN orderdetails od
	    ON pr.productCode = od.productCode
	  JOIN orders os
	    ON od.orderNumber = os.orderNumber
     GROUP BY os.customerNumber
  )
   SELECT AVG(pg.prof_gen) AS lyf_tym_val
     FROM profit_gen_table pg;
	 
  /* 
  
  Conclusion:
 
  Question 1: Which products should we order more of or less of?
  
    Answer 1: Analysing the query results of product performance we can see that,  
              6 out of 10 high-selling cars belong to 'Classic Cars' product line. 
              They sell frequently with high sale value. As such we should be re-stocked these frequently.
              
 
  Question 2: How should we tailor marketing and communication strategies to customer behaviors?
  
    Answer 2: Analysing the query results of top and bottom customers in terms of profit generation,
              we need to offer loyalty rewards and priority services for our top customers to retain them.
			  Also for bottom customers we need to solicit feedback to better understand their preferences, 
			  expected pricing, discount and offers to increase our sales.
 
  Question 3: How much can we spend on acquiring new customers?
  
    Answer 3: The average customer liftime value of our store is $ 39,040. This means for every new customer we make profit of 39,040 dollars. 
	          We can use this to predict how much we can spend on new customer acquisition, 
			  at the same time maintain or increase our profit levels.
	          
  PROJECT END */