CREATE DATABASE E_Commerce;
---Import csv file and make Normalization
SELECT * 
FROM e_commerce_data

---Normalization is the process of organizing the data in a database efficiently. 
---It involves breaking down tables into smaller, less redundant tables and defining relationships between them. 
---1. First Normal Form (1NF):
---> Each table should have a primary key.
---> No repeating groups.
---Second Normal Form (2NF):
--->.No partial dependencies.
---Third Normal Form (3NF):
--->No transitive dependencies.
---Create Customers Table
CREATE TABLE  Customers (
    customer_id INT NOT NULL,
    first_name NVARCHAR(50),
    last_name NVARCHAR(50),
    province NVARCHAR(50),
    region NVARCHAR(50),
    customer_segment NVARCHAR(20)
);
---Create Orders Table
CREATE TABLE  Orders (
    order_id	int	NOT NULL,
	order_date	date,
	order_priority	nvarchar(20),
	ship_id	int NOT NULL,
	customer_id	int	NOT NULL
);

---Create Order_Items Table

CREATE TABLE Order_Items (
    order_id INT NOT NULL,
    item_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT,
    sales INT    
);

---Create Shippings Table
CREATE TABLE shippings (
    ship_id INT NOT NULL,
    ship_date DATE,
    day_taken_shipping INT
);


---Indert into Tables the values from E_Comerce imported table.

---Appending Customer Values into Customers table.
INSERT INTO Customers(customer_id, first_name, last_name, province, region, customer_segment) 
SELECT
    CAST(SUBSTRING(Cust_ID, PATINDEX('%[0-9]%', Cust_ID), LEN(Cust_ID)) AS INT) AS Customer_ID,
    LEFT(Customer_Name, CHARINDEX(' ', Customer_Name + ' ') - 1) AS first_name,
    RIGHT(Customer_Name, LEN(Customer_Name) - CHARINDEX(' ', Customer_Name + ' ')) AS last_name,
    Province,
    Region, 
    Customer_Segment
FROM (
    SELECT DISTINCT 
        Cust_ID, 
        Customer_Name,
        Province,
        Region,
        Customer_Segment        
    FROM 
        e_commerce_data
) AS unique_customers
ORDER BY CAST(SUBSTRING(Cust_ID, PATINDEX('%[0-9]%', Cust_ID), LEN(Cust_ID)) AS INT)

---


SELECT * 
FROM Customers


---Appending Orders Values into Orders table.

INSERT INTO Orders (order_id,order_date,order_priority,ship_id, customer_id) 
SELECT
CAST(SUBSTRING(Ord_ID, PATINDEX('%[0-9]%', Ord_ID), LEN(Ord_ID)) AS INT) AS Order_ID,
Order_Date, Order_Priority,
CAST(SUBSTRING( Ship_ID, PATINDEX('%[0-9]%',  Ship_ID), LEN( Ship_ID)) AS INT) As Shipping_ID,
CAST(SUBSTRING(Cust_ID, PATINDEX('%[0-9]%', Cust_ID), LEN(Cust_ID)) AS INT) As Customer_ID
FROM e_commerce_data

---Appending Order details into Order_Items table.

INSERT INTO Order_Items(order_id,item_id,product_id,quantity,sales) 
SELECT
CAST(SUBSTRING(Ord_ID, PATINDEX('%[0-9]%', Ord_ID), LEN(Ord_ID)) AS INT)AS Order_ID,
0 AS item_id,
CAST(SUBSTRING( Prod_ID, PATINDEX('%[0-9]%',  Prod_ID), LEN( Prod_ID)) AS INT)As Product_ID,
Order_Quantity,
Sales
FROM e_commerce_data

--- Insert unique sequential numbers into item_id 

WITH NumberedItems AS (
    SELECT 
        order_id,
        ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY order_id) AS item_id,
        product_id
    FROM 
        Order_Items
)
UPDATE t
SET t.item_id = n.item_id
FROM Order_Items t
JOIN NumberedItems n ON t.order_id = n.order_id AND t.product_id = n.product_id;

---Insert into Customers Table Values From Main Table

INSERT INTO Customers(customer_id, first_name, last_name, province, region, customer_segment) 
SELECT
    CAST(SUBSTRING(Cust_ID, PATINDEX('%[0-9]%', Cust_ID), LEN(Cust_ID)) AS INT) AS Customer_ID,
    LEFT(Customer_Name, CHARINDEX(' ', Customer_Name + ' ') - 1) AS first_name,
    RIGHT(Customer_Name, LEN(Customer_Name) - CHARINDEX(' ', Customer_Name + ' ')) AS last_name,
    Province,
    Region, 
    Customer_Segment
FROM (
    SELECT DISTINCT 
        Cust_ID, 
        Customer_Name,
        Province,
        Region,
        Customer_Segment        
    FROM 
        e_commerce_data
) AS unique_customers
ORDER BY CAST(SUBSTRING(Cust_ID, PATINDEX('%[0-9]%', Cust_ID), LEN(Cust_ID)) AS INT)

---Insert into Shippings Table Values From Main Table
INSERT INTO Shippings(ship_id,ship_date, day_taken_shipping) 
SELECT
SUBSTRING(Ship_ID, PATINDEX('%[0-9]%', Ship_ID), LEN(Ship_ID)) AS Ship_ID,
Ship_Date,
DaysTakenForShipping
FROM e_commerce_data

---Looking for Duplicates in Customer
SELECT customer_id,COUNT(customer_id)
FROM Customers
GROUP BY customer_id
HAVING COUNT(customer_id) >1
ORDER BY customer_id

---Remove Duplicates from Customers table
WITH CTE AS (
    SELECT customer_id,
           ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY customer_id) AS RowNumber
    FROM Customers
)
DELETE FROM CTE WHERE RowNumber > 1;

---

SELECT * 
FROM Customers
ORDER BY customer_id

---Looking for Duplicates in Order_Item
SELECT order_id, item_id, COUNT(*)
FROM Order_Items
GROUP BY order_id, item_id
HAVING COUNT(*) >1
ORDER BY order_id;
---There is no Duplicated Value in Order_Items table.

---Looking for Duplicates in Orders
SELECT order_id, COUNT(order_id)
FROM Orders
GROUP BY order_id
HAVING COUNT(order_id) >1
ORDER BY order_id;

---Removing DUPLICATED VALUES from Orders table.
WITH NumberedRows AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY order_id, order_date, order_priority, ship_id, customer_id
		   ORDER BY (SELECT NULL)) AS RowNum
    FROM Orders
)
DELETE FROM NumberedRows
WHERE RowNum > 1;

---

SELECT * 
FROM Orders
ORDER BY order_id;

---Looking for Duplicates in Shippings
SELECT ship_id, COUNT(ship_id)
FROM Shippings
GROUP BY ship_id
HAVING COUNT(*) >1
ORDER BY ship_id;

---CLEARING DUPLICATED VALUES FROM Shippings table.
WITH NumberedRows AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY ship_id, ship_date, day_taken_shipping
		   ORDER BY (SELECT NULL)) AS RowNum
    FROM Shippings
)
DELETE FROM NumberedRows
WHERE RowNum > 1;

---

SELECT * 
FROM shippings
ORDER BY ship_id;

--- Adding primary key and foreign key constraints
ALTER TABLE Customers
ADD CONSTRAINT PK_Customers PRIMARY KEY (customer_id);

ALTER TABLE Order_Items
ADD CONSTRAINT PK_Order_Items PRIMARY KEY (order_id, item_id);

ALTER TABLE Orders
ADD CONSTRAINT PK_Orders PRIMARY KEY (order_id);

ALTER TABLE Shippings
ADD CONSTRAINT PK_Shippings PRIMARY KEY (ship_id);

--- Adding Foreign Keys 

ALTER TABLE Orders
ADD CONSTRAINT FK_Orders_Customers FOREIGN KEY (customer_id) REFERENCES Customers(customer_id);

ALTER TABLE Orders
ADD CONSTRAINT FK_Orders_Ships FOREIGN KEY (ship_id) REFERENCES Shippings(ship_id);

ALTER TABLE Order_Items
ADD CONSTRAINT FK_Orders_Items_ORders FOREIGN KEY (order_id) REFERENCES Orders(order_id);

---QUESTIONS
---1. Find the top 3 customers who have the maximum count of orders.

SELECT TOP 3 customer_id,
			 count(*)AS Order_Count
FROM		 Order_Items I
INNER JOIN   Orders O ON I.order_id=O.order_id
GROUP BY	 customer_id
ORDER BY 2 DESC;


---2. Find the customer whose order took the maximum time to get shipping. 

SELECT TOP 1 C.customer_id, 
			 C.first_name, 
			 C.last_name, 
			 day_taken_shipping
FROM		 Customers AS C
INNER JOIN Orders  AS O 
			 ON O.customer_id=C.customer_id
INNER JOIN shippings AS S 
			 ON O.ship_id = S.ship_id
ORDER BY	 day_taken_shipping DESC;


---3. Count the total number of unique customers in January and how many of them 
---   came back again in the each one months of 2011. 

---Count of Customers whose order date is in January/2011 -- 94 Distinct Customer ordered in January 
SELECT	COUNT( DISTINCT C.customer_id) As Num_Customers_In_January
FROM	Customers AS C
INNER JOIN Orders As O 
	ON O.customer_id=C.customer_id
WHERE	 DATENAME(MONTH,O.order_date) = 'January' AND YEAR(O.order_date) = 2011
GROUP BY DATENAME(MONTH,O.order_date);

---Create a view consists of All orders of customers who placed orders in January/2011
CREATE VIEW Customers_In_January AS
SELECT  DISTINCT C.customer_id, O.order_date 
FROM	Customers AS C
RIGHT JOIN (
			SELECT  Cu.customer_id As customer_id
			FROM Customers AS Cu
			INNER JOIN Orders As O ON O.customer_id=Cu.customer_id
			WHERE  DATENAME(MONTH,O.order_date) = 'January' AND YEAR(O.order_date) = 2011
			) AS Cus_Jan 
			ON Cus_Jan.customer_id = C.customer_id 
INNER JOIN Orders AS O ON O.customer_id=C.customer_id
WHERE YEAR(O.order_date)=2011

---Pivot table
SELECT [January],[February], [March], [April], [May], [June], [July], [August], [September], [October], [November], [December]
FROM (
    SELECT  DISTINCT customer_id, DATENAME(MONTH,order_date) As Order_Month
    FROM Customers_In_January
) AS SourceTable
PIVOT (
    COUNT(customer_id)
    FOR Order_Month IN ([January],[February], [March], [April], [May], [June], [July], [August], [September], [October], [November], [December])
) AS Pvt;

---4. Write a query to return for each user the time elapsed between the first 
---purchasing and the third purchasing, in ascending order by Customer ID. 


---Order Dates of customers who made more than 3 purchases
SELECT	C.customer_id,O.order_date 
FROM	Customers As C
INNER JOIN (
			SELECT	 Cu.customer_id,COUNT(*) AS Count_Of_Purcheses
			FROM	 Customers AS Cu
			INNER JOIN Orders  AS O 
				ON Cu.customer_id=O.customer_id
			GROUP BY	Cu.customer_id
			HAVING	COUNT(*)>=3
		) AS More_Purches ON More_Purches.customer_id=C.customer_id
INNER JOIN Orders AS O ON O.customer_id=C.customer_id
ORDER BY C.customer_id ASC

---Ordered Orders and differences between first and third order.
WITH OrderedOrders AS (
    SELECT 
        C.customer_id,
        O.order_date,
        DENSE_RANK() OVER (PARTITION BY C.customer_id ORDER BY O.order_date) AS OrderRank
    FROM 
        Customers AS C
    INNER JOIN 
        Orders AS O ON C.customer_id = O.customer_id
    INNER JOIN (
        SELECT 
            customer_id,
            COUNT(*) AS Count_Of_Purchases
        FROM 
            Orders
        GROUP BY 
            customer_id
        HAVING 
            COUNT(*) >= 3
    ) AS More_Purchases ON More_Purchases.customer_id = C.customer_id
)

SELECT 
    customer_id,
    MIN(CASE WHEN OrderRank = 1 THEN order_date END) AS first_order_date,
    MAX(CASE WHEN OrderRank = 3 THEN order_date END) AS third_order_date,
    DATEDIFF(DAY, MAX(CASE WHEN OrderRank = 1 THEN order_date END), 
	MAX(CASE WHEN OrderRank = 3 THEN order_date END)) AS difference_days
FROM 
    OrderedOrders
WHERE 
    OrderRank IN (1, 3)
GROUP BY 
    customer_id
ORDER BY customer_id

---5. Write a query that returns customers who purchased both product 11 and 
---product 14, as well as the ratio of these products to the total number of 
---products purchased by the customer. 

---customers who purchased both product 11 and product 14 and amounts and creating a temporary table from this
SELECT 
    C.customer_id, 
    SUM(CASE WHEN I.product_id = 11 THEN I.quantity ELSE 0 END) AS Total_Product_11,
	SUM(CASE WHEN I.product_id = 14 THEN I.quantity ELSE 0 END) AS Total_Product_14
INTO 
    #Amount_Products_11_14
FROM 
    Customers AS C
INNER JOIN 
    Orders AS O ON C.customer_id = O.customer_id
INNER JOIN 
    Order_Items AS I ON I.order_id = O.order_id
WHERE 
    C.customer_id IN (
        SELECT 
            O.customer_id
        FROM 
            Orders AS O
        INNER JOIN 
            Order_Items AS I ON O.order_id = I.order_id
        WHERE 
            I.product_id IN (11, 14)
        GROUP BY 
            O.customer_id
        HAVING 
            COUNT(DISTINCT I.product_id) = 2
    )
    AND I.product_id IN (11, 14)
GROUP BY 
    C.customer_id;
	

---Calculate the ratio of these products to the total number of products purchased by the customer. 

WITH Total_Amount_AllProducts AS(
SELECT	Cu.customer_id,
		SUM(It.quantity) AS Total_Amount_Products
FROM Customers AS Cu
INNER JOIN #Amount_Products_11_14 X
		ON  Cu.customer_id=X.customer_id
INNER JOIN Orders AS O 
		ON Cu.customer_id = O.customer_id
INNER JOIN Order_Items AS It 
		ON It.order_id = O.order_id
 GROUP BY Cu.customer_id
)
SELECT 
    A.customer_id,
	A.Total_Product_11,
	A.Total_Product_14,
    B.Total_Amount_Products,
    CAST((A.Total_Product_11 * 1.0) / B.Total_Amount_Products AS DECIMAL(10, 2)) AS Ratio_11_To_Total,
	CAST((A.Total_Product_14 * 1.0) / B.Total_Amount_Products AS DECIMAL(10, 2)) AS Ratio_14_To_Total
FROM 
    #Amount_Products_11_14 AS A
INNER JOIN 
    Total_Amount_AllProducts  As B ON A.customer_id = B.customer_id;


/*Customer Segmentation 

Categorize customers based on their frequency of visits. The following steps 
will guide you. If you want, you can track your own way. 
1. Create a “view” that keeps visit logs of customers on a monthly basis. (For 
each log, three field is kept: Cust_id, Year, Month)*/

CREATE VIEW V_visit_logs AS 
SELECT  
		customer_id,
		YEAR(order_date) AS Year,
		MONTH(order_date) AS Month
FROM	Orders;

----
---2. Create a “view” that keeps the number of monthly visits by users. (Show 
---separately all months from the beginning  business

CREATE VIEW V_Visit_Counts AS
SELECT	COUNT(*)  AS Visit_Counts,
		Month,
		Year
		
FROM	V_visit_logs
GROUP BY		
		Month,
		Year;
		
---	
---3. For each visit of customers, create the previous or next month of the visit as a 
---separate column. 

CREATE VIEW V_Next_Month AS
SELECT 
    B.customer_id,
    B.Month,
	B.Year,
    LEAD(B.Month) OVER (PARTITION BY  B.customer_id ORDER BY B.Year, B.Month) AS NextMonth

FROM
    V_visit_logs B;

---
---4. Calculate the monthly time gap between two consecutive visits by each customer. 

CREATE VIEW V_Next_Month_Year AS
SELECT 
    C.customer_id,
    C.Month,
    C.Year,
    C.NextMonth,
    LEAD(C.Year) OVER (PARTITION BY C.customer_id ORDER BY C.customer_id) AS NextYear
FROM
    V_Next_Month C;


---


CREATE VIEW  CalculatedDifferenceMonths AS(
SELECT 
		V.customer_id,
		V.Month,
		V.Year,
		V.NextMonth,
		V.NextYear,
		 CASE 
        WHEN V.NextMonth IS NOT NULL THEN 
            (V.NextYear-V.Year) * 12 
            + ( V.NextMonth - V.Month ) 
        ELSE 
            NULL 
    END AS TotalMonthDifference
FROM	V_Next_Month_Year V
)
----
---5. Categorise customers using average time gaps. Choose the most fitted labeling model for you. 
	/*For example:  
	-> Labeled as churn: if the customer hasn't made another purchase in the 
	months since they made their first purchase. 
	-> Labeled as regular: if the customer has made at least 1 purchase in 3 months. 	
	-> Labeled as Irregular: Orders with varying intervals.
	Etc.*/

	WITH CustomerBehavior AS (
    SELECT 
        customer_id,		
		AVG(TotalMonthDifference) AS AvgTimeGap,
        COUNT(*) AS TotalOrders,
        CASE 
            WHEN COUNT(*) = 1 THEN 'Churn'           
            WHEN COUNT(*) >= 2 AND AVG(TotalMonthDifference) <= 3 THEN 'Regular'            
            WHEN AVG(TotalMonthDifference) > 3 THEN 'Irregular'
            ELSE 'Unknown'
        END AS CustomerType
    FROM CalculatedDifferenceMonths
    GROUP BY customer_id
)
SELECT 
    customer_id,	
    AvgTimeGap,
    TotalOrders,
    CustomerType
FROM CustomerBehavior
ORDER BY customer_id;
	---
/* 3. PART
Month-Wise Retention Rate

Find month-by-month customer retention rate since the start of the business.
There are many different variations in the calculation of Retention Rate. But we will 
try to calculate the month-wise retention rate in this project.
So, we will be interested in how many of the customers in the previous month could 
be retained in the next month.
Proceed step by step by creating “views”. You can use the view you got at the end of 
the Customer Segmentation section as a source.*/


--1. Find the number of customers retained month-wise. (You can use time gaps)

WITH Cust_Month AS (
    SELECT 
        customer_id,   
        CONCAT(Year, '-', 
              CASE WHEN LEN(Month) = 1 THEN CONCAT('0', Month) ELSE CAST(Month AS VARCHAR(2)) END
             ) AS month,
        TotalMonthDifference
      
    FROM 
        CalculatedDifferenceMonths        
)

SELECT  
    month,
    COUNT(DISTINCT customer_id) AS RetentionCounts
FROM    
    Cust_Month
WHERE
   TotalMonthDifference = 1
GROUP BY 
    month
ORDER BY 
    month;

--2. Calculate the month-wise retention rate.

WITH Cust_Month AS (
    SELECT 
        customer_id,  
		    CONCAT(Year, '-', 
              CASE WHEN LEN(Month) = 1 THEN CONCAT('0', Month) ELSE CAST(Month AS VARCHAR(2)) END
             ) AS month,
        TotalMonthDifference
      
    FROM 
        CalculatedDifferenceMonths      
), T2 AS(

SELECT  
    month,
    COUNT(CASE WHEN TotalMonthDifference = 1 THEN customer_id END) AS RetainedCustomers,
    COUNT( DISTINCT customer_id)  AS TotalCustomers    
FROM    
    Cust_Month 

GROUP BY 
    month
)
SELECT 
	month,
	TotalCustomers,
	RetainedCustomers,
	LAG(RetainedCustomers) OVER (ORDER BY month) AS PreviousRetained,
	CAST(1.0 * LAG(RetainedCustomers) OVER (ORDER BY month) / TotalCustomers AS DECIMAL (3,2))  AS RetentionRate

FROM T2
