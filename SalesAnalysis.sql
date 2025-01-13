-- Drop and Create Products Table
DROP TABLE if EXISTS products;
CREATE TABLE products (PRODUCTCODE TEXT PRIMARY KEY,PRODUCTLINE TEXT, MSRP INTEGER);
-- Populate Products Table
INSERT INTO products(PRODUCTCODE,PRODUCTLINE,MSRP) SELECT DISTINCT PRODUCTCODE,PRODUCTLINE,MSRP FROM sales_data_sample;
SELECT * FROM products LIMIT 10;
-- Drop and Create Customers Table--create new primary key as customerID--does not exist in raw data 
DROP TABLE if EXISTS customers;
CREATE TABLE Customers (customerID INTEGER PRIMARY KEY AUTOINCREMENT,CUSTOMERNAME TEXT, PHONE TEXT,ADDRESSLINE1 TEXT,ADDRESSLINE2 TEXT,CITY TEXT,STATE TEXT,POSTALCODE TEXT,COUNTRY TEXT,TERRITORY TEXT,CONTACTFIRSTNAME TEXT,CONTACTLASTNAME TEXT);
-- Populate Customers Table
INSERT INTO Customers (CUSTOMERNAME,PHONE,ADDRESSLINE1,ADDRESSLINE2,CITY,STATE,POSTALCODE,COUNTRY,TERRITORY,CONTACTFIRSTNAME,CONTACTLASTNAME) SELECT DISTINCT CUSTOMERNAME,PHONE,ADDRESSLINE1,ADDRESSLINE2,CITY,STATE,POSTALCODE,COUNTRY,TERRITORY,CONTACTFIRSTNAME,CONTACTLASTNAME FROM sales_data_sample;
SELECT * FROM Customers LIMIT 10;
-- Drop and Create Orders Table--specific to the order--add a FOREIGN KEY customerID with customers 
DROP TABLE if EXISTS orders;
CREATE TABLE Orders (ORDERNUMBER INTEGER,ORDERLINENUMBER INTEGER,STATUS TEXT,ORDERDATE TEXT,QTR_ID INTEGER,MONTH_ID INTEGER,YEAR_ID INTEGER,CUSTOMERNAME TEXT,customerID INTEGER,PRIMARY KEY(ORDERNUMBER,ORDERLINENUMBER),FOREIGN KEY (customerID) REFERENCES Customers(customerID));
-- Populate Orders Table
INSERT INTO Orders (ORDERNUMBER,ORDERLINENUMBER,STATUS,ORDERDATE,QTR_ID,MONTH_ID,YEAR_ID,CUSTOMERNAME)SELECT DISTINCT ORDERNUMBER,ORDERLINENUMBER,STATUS,ORDERDATE,QTR_ID,MONTH_ID,YEAR_ID,CUSTOMERNAME FROM sales_data_sample;
-- Update CustomerID in Orders Table
UPDATE Orders set customerID=(SELECT customerID FROM Customers where customers.CUSTOMERNAME=orders.CUSTOMERNAME)WHERE Orders.CUSTOMERNAME is not NULL;
SELECT * FROM orders LIMIT 10;
-- Drop and Create Ordersdetails Table--specific to the product--add a FOREIGN KEY PRODUCTCODE from products and ordernumber and linenumber from orders
drop table if EXISTS orderdetails;
CREATE TABLE orderdetails (ORDERNUMBER INTEGER,ORDERLINENUMBER INTEGER,PRODUCTCODE TEXT,QUANTITYORDERED INTEGER,PRICEEACH REAL,SALES INTEGER,ORDERDATE TEXT,DEALSIZE TEXT,FOREIGN KEY(ORDERNUMBER,ORDERLINENUMBER)REFERENCES Orders (ORDERNUMBER,ORDERLINENUMBER),FOREIGN KEY (PRODUCTCODE) REFERENCES products(PRODUCTCODE) );
-- Populate Ordersdetails Table
INSERT INTO orderdetails (ORDERNUMBER,ORDERLINENUMBER,PRODUCTCODE,QUANTITYORDERED,PRICEEACH,SALES,ORDERDATE,DEALSIZE) SELECT DISTINCT ORDERNUMBER,ORDERLINENUMBER,PRODUCTCODE,QUANTITYORDERED,PRICEEACH,SALES,ORDERDATE,DEALSIZE from sales_data_sample ;
SELECT*FROM orderdetails LIMIT 10;
--Data quality and integrity check 
---Forein keys validation 
PRAGMA FOREIGN_KEY=on;
PRAGMA FOREIGN_key_list ('orderdetails');
SELECT ORDERNUMBER FROM orderdetails WHERE ORDERNUMBER not in (SELECT ORDERNUMBER FROM Orders);
SELECT PRODUCTCODE FROM orderdetails WHERE PRODUCTCODE NOT in (SELECT PRODUCTCODE FROM products);
SELECT ORDERLINENUMBER FROM orderdetails where ORDERLINENUMBER not in (SELECT ORDERLINENUMBER FROM Orders);
---Duplicate and Null Value Checks
SELECT COUNT (*) FROM orderdetails WHERE ORDERNUMBER is NULL or ORDERLINENUMBER is NULL or PRODUCTCODE is NULL;
SELECT ORDERNUMBER,ORDERLINENUMBER, count (*) FROM Orders GROUP by ORDERNUMBER,ORDERLINENUMBER HAVING count (*)>1;
SELECT COUNt (*) FROM orderdetails where SALES is NULL;
--Revenue sales analysis
---products
CREATE TABLE Revenue_product as SELECT p.PRODUCTLINE,p.PRODUCTCODE,sum(od.SALES) as total_revenue FROM products p JOIN orderdetails od on p.PRODUCTCODE=od.PRODUCTCODE GROUP by p.PRODUCTLINE,p.PRODUCTCODE ORDER by total_revenue DESC;
---Customers 
CREATE TABLE Revenue_customer as SELECT c.CUSTOMERNAME,sum(od.SALES)as total_revenue FROM customers c JOIN Orders o on c.customerID=o.customerID JOIN orderdetails od on o.ORDERNUMBER=od.ORDERNUMBER and o.ORDERLINENUMBER=od.ORDERLINENUMBER GROUP by c.CUSTOMERNAME ORDER by total_revenue DESC;
---COUNTRY
CREATE TABLE Revenue_country as SELECT c.COUNTRY,sum(od.SALES)as total_revenue FROM customers c JOIN Orders o on c.customerID=o.customerID JOIN orderdetails od on o.ORDERNUMBER=od.ORDERNUMBER and o.ORDERLINENUMBER=od.ORDERLINENUMBER GROUP by c.COUNTRY ORDER by total_revenue DESC;
--- ORDER NUMBER
CREATE TABLE Revenue_ordernumber as SELECT ORDERNUMBER,sum(SALES) as total_revenue FROM orderdetails GROUP by ORDERNUMBER ORDER by total_revenue DESC;
--- Deal size 
CREATE TABLE Revenue_dealsize as SELECT DEALSIZE,sum(SALES) as total_revenue FROM orderdetails GROUP by DEALSIZE ORDER by total_revenue DESC;
--Yearly revenue
CREATE TABLE Revenue_yearly as SELECT o.YEAR_ID, sum(od.SALES)as total_revenue FROM Orders o JOIN orderdetails od on o.ORDERNUMBER=od.ORDERNUMBER and o.ORDERLINENUMBER=od.ORDERLINENUMBER GROUP by o.YEAR_ID ORDER by o.YEAR_ID,total_revenue DESC;
-- Quaterly revenue
CREATE TABLE Revenue_QTR as SELECT o.YEAR_ID,o.QTR_ID, sum(od.SALES)as total_revenue FROM Orders o JOIN orderdetails od on o.ORDERNUMBER=od.ORDERNUMBER and o.ORDERLINENUMBER=od.ORDERLINENUMBER GROUP by o.YEAR_ID,o.QTR_ID ORDER by o.YEAR_ID,total_revenue DESC;
--Monthly revenue 
CREATE TABLE Revenue_monthly as SELECT o.YEAR_ID,o.MONTH_ID, sum(od.SALES)as total_revenue FROM Orders o JOIN orderdetails od on o.ORDERNUMBER=od.ORDERNUMBER and o.ORDERLINENUMBER=od.ORDERLINENUMBER GROUP by o.YEAR_ID,o.month_ID ORDER by o.YEAR_ID,o.MONTH_ID,total_revenue DESC;
-- Monthly revenue for each product line 
CREATE TABLE Revenue_monthly_productline as SELECT o.YEAR_ID,p.PRODUCTLINE, o.MONTH_ID, sum(od.SALES) as total_revenue FROM orders o JOIN orderdetails od on o.ORDERNUMBER=od.ORDERNUMBER and o.ORDERLINENUMBER=od.ORDERLINENUMBER JOIN products p on od.PRODUCTCODE=p.PRODUCTCODE GROUP by o.YEAR_ID,o.MONTH_ID,p.PRODUCTLINE ORDER by o.YEAR_ID,o.MONTH_ID,total_revenue DESC;
-- Yearly revenue by product line 
CREATE TABLE Revenue_yearly_productline as SELECT o.YEAR_ID,p.PRODUCTLINE,sum(od.SALES) as total_revenue FROM orders o JOIN orderdetails od on o.ORDERNUMBER=od.ORDERNUMBER and o.ORDERLINENUMBER=od.ORDERLINENUMBER JOIN products p on od.PRODUCTCODE=p.PRODUCTCODE GROUP by o.YEAR_ID,p.PRODUCTLINE ORDER by o.YEAR_ID,total_revenue DESC;
--Top 10 customers by revenue
CREATE TABLE Revenue_top10customers as SELECT o.CUSTOMERNAME,sum(od.SALES) as total_revenue FROM Orders o JOIN orderdetails od on o.ORDERNUMBER=od.ORDERNUMBER and o.ORDERLINENUMBER=od.ORDERLINENUMBER GROUP by o.CUSTOMERNAME ORDER by total_revenue DESC LIMIT 10;
-- Renevue by COUNTRY over the years 
CREATE TABLE Revenue_yearly_country as SELECT c.COUNTRY,o.YEAR_ID,sum(od.SALES) as total_revenue FROM customers c JOIN orders o on c.customerID=o.customerID JOIN orderdetails od on o.ORDERNUMBER=od.ORDERNUMBER and o.ORDERLINENUMBER=od.ORDERLINENUMBER GROUP by c.COUNTRY,o.YEAR_ID ORDER by c.COUNTRY,o.YEAR_ID,total_revenue DESC ;
--year-over-year growth rate in revenue
CREATE TABLE Revenue_yearly_growth as WITH yearly_revenue as (SELECT o.YEAR_ID,sum(od.SALES) as total_revenue FROM orders o join orderdetails od on o.ORDERNUMBER=od.ORDERNUMBER and o.ORDERLINENUMBER=od.ORDERLINENUMBER GROUP by o.YEAR_ID ORDER by total_revenue DESC) SELECT a.YEAR_ID,a.total_revenue as current_year_revenue, b.YEAR_ID,b.total_revenue as previous_year_revenue,round((a.total_revenue-b.total_revenue)*100/b.total_revenue,2) as growth_rate FROM yearly_revenue a left JOIN yearly_revenue b on a.YEAR_ID=b.YEAR_ID+1  ; 
--Customer Retention and Revenue how many repeat customers contributed to revenue
CREATE TABLE Revenue_customer_retention as SELECT o.CUSTOMERNAME, COUNT(DISTINCT o.ORDERNUMBER) as order_number,sum(od.SALES)as total_revenue FROM Orders o join orderdetails od on o.ORDERNUMBER=od.ORDERNUMBER and o.ORDERLINENUMBER=od.ORDERLINENUMBER GROUP by o.CUSTOMERNAME HAVING order_number>1 ORDER by order_number,total_revenue DESC;
--ProductLine Revenue Distribution percentage each product line contributes to the total revenue
CREATE TABLE Revenue_distributio_productline as WITH PRODUCT_revenue as (SELECT p.PRODUCTLINE,sum(od.SALES)as total_revenue FROM products p JOIN orderdetails od on p.PRODUCTCODE=od.PRODUCTCODE GROUP by PRODUCTLINE) SELECT PRODUCTLINE,total_revenue, round((total_revenue*100/(SELECT sum(total_revenue)FROM PRODUCT_revenue)),2) as Percentage_contribution FROM PRODUCT_revenue ORDER by Percentage_contribution DESC;
--Top Products lines by country by revenue
CREATE TABLE Revenue_top10product_country as SELECT c.COUNTRY, p.PRODUCTLINE, sum(od.SALES) as total_revenue FROM Customers c JOIN Orders o on c.customerID=o.customerID JOIN orderdetails od on o.ORDERNUMBER=od.ORDERNUMBER and o.ORDERLINENUMBER=od.ORDERLINENUMBER JOIN products p on od.PRODUCTCODE=p.PRODUCTCODE GROUP by c.COUNTRY,p.PRODUCTLINE ORDER by c.COUNTRY,total_revenue DESC;
--Filter Revenue for 2004
CREATE TABLE Revenue_2004 as SELECT o.YEAR_ID,sum(od.SALES) as total_revenue FROM Orders o JOIN orderdetails od on o.ORDERNUMBER=od.ORDERNUMBER and o.ORDERLINENUMBER=od.ORDERLINENUMBER WHERE (o.YEAR_ID=2004) GROUP by o.YEAR_ID;
--Revenue for High-Value Orders above 10000
CREATE TABLE highvalue_Revenue as SELECT ORDERNUMBER,sum(SALES) as total_revenue FROM orderdetails  GROUP by ORDERNUMBER HAVING total_revenue>10000 ORDER by total_revenue DESC;
--Revenue for Product Lines  "Classic Cars" and "Motorcycles"
SELECT p.PRODUCTLINE,sum(od.SALES) as total_revenue FROM products p join orderdetails od on p.PRODUCTCODE=od.PRODUCTCODE WHERE PRODUCTLINE in ('Classic Cars','Motorcycles')GROUP by PRODUCTLINE ;
--Revenue Growth for USA per year 
WITH yearly_revenue as (SELECT  o.YEAR_ID,c.COUNTRY,sum(od.SALES) as revenue FROM Customers c JOIN orders o on c.customerID=o.customerID JOIN orderdetails od on o.ORDERNUMBER=od.ORDERNUMBER and o.ORDERLINENUMBER=od.ORDERLINENUMBER WHERE c.COUNTRY in ('USA') GROUP by c.COUNTRY,o.YEAR_ID) SELECT a.YEAR_ID,a.revenue as current_year_revenue,b.YEAR_ID,b.revenue as previous_year_revenue,round((a.revenue-b.revenue)*100/b.revenue,2) as growth FROM yearly_revenue a LEFT JOIN yearly_revenue b on a.YEAR_ID=b.YEAR_ID+1;
--Revenue by Quarter and Deal Size
SELECT o.YEAR_ID,o.QTR_ID, od.DEALSIZE,sum(od.SALES) as revenue FROM Orders o JOIN orderdetails od on o.ORDERNUMBER=od.ORDERNUMBER and o.ORDERLINENUMBER=od.ORDERLINENUMBER GROUP by o.YEAR_ID,o.QTR_ID, od.DEALSIZE ORDER by o.YEAR_ID,o.QTR_ID ASC;
--Revenue per Orderline average revenue per product in each order.
SELECT ORDERNUMBER,PRODUCTCODE,avg(SALES) as average_revenue FROM orderdetails GROUP by ORDERNUMBER,PRODUCTCODE ORDER by ORDERLINENUMBER,average_revenue DESC;
--Revenue by City for Specific Deal Sizes city-level revenue for large and medium deals
SELECT c.COUNTRY,c.CITY,od.DEALSIZE,sum(od.SALES)as revenue FROM Customers c JOIN Orders o on c.customerID=o.customerID JOIN orderdetails od on o.ORDERNUMBER=od.ORDERNUMBER and o.ORDERLINENUMBER=od.ORDERLINENUMBER WHERE od.DEALSIZE in ('Large','Medium') GROUP by c.COUNTRY,c.CITY,od.DEALSIZE ORDER by c.COUNTRY,c.CITY,od.DEALSIZE,revenue DESC;
--Product Performance by Sales
SELECT p.PRODUCTLINE,od.PRODUCTCODE,sum(od.SALES) as revenue FROM products p JOIN orderdetails od on p.PRODUCTCODE=od.PRODUCTCODE GROUP by p.PRODUCTLINE,od.PRODUCTCODE ORDER by revenue DESC;
--Top 5 Selling Products by QUANTITY
SELECT p.PRODUCTLINE,od.PRODUCTCODE,sum(od.QUANTITYORDERED) as quantiy FROM products p JOIN orderdetails od on p.PRODUCTCODE=od.PRODUCTCODE GROUP by p.PRODUCTLINE,od.PRODUCTCODE ORDER by quantiy DESC LIMIT 5;
--Product Sales by Deal Size
SELECT p.PRODUCTLINE,od.PRODUCTCODE,od.DEALSIZE,sum(od.SALES) as revenue FROM products p JOIN orderdetails od on p.PRODUCTCODE=od.PRODUCTCODE GROUP by p.PRODUCTLINE,od.PRODUCTCODE,od.DEALSIZE ORDER by revenue DESC;
--Quantity Ordered per Product Line
SELECT p.PRODUCTLINE,sum(od.QUANTITYORDERED) as quantiy FROM products p JOIN orderdetails od on p.PRODUCTCODE=od.PRODUCTCODE GROUP by p.PRODUCTLINE,od.PRODUCTCODE ORDER by quantiy DESC;
-- Average Quantity Ordered per Product
SELECT p.PRODUCTLINE,od.PRODUCTCODE,avg(od.QUANTITYORDERED) as quantiy FROM products p JOIN orderdetails od on p.PRODUCTCODE=od.PRODUCTCODE GROUP by p.PRODUCTLINE,od.PRODUCTCODE ORDER by quantiy DESC;
--Slow-Moving Products (Low Quantity Ordered)<1000
SELECT p.PRODUCTLINE,od.PRODUCTCODE,sum(od.QUANTITYORDERED) as quantiy FROM products p JOIN orderdetails od on p.PRODUCTCODE=od.PRODUCTCODE GROUP by p.PRODUCTLINE,od.PRODUCTCODE HAVING (quantiy<1000) ORDER by quantiy DESC;
--Sales Growth per Product yearly :
WITH yearly_revenue as (SELECT o.YEAR_ID,p.PRODUCTLINE,od.PRODUCTCODE,sum(od.SALES) as revenue FROM products p JOIN orderdetails od on p.PRODUCTCODE=od.PRODUCTCODE JOIN Orders o on od.ORDERNUMBER=o.ORDERNUMBER and od.ORDERLINENUMBER=o.ORDERLINENUMBER GROUP by o.YEAR_ID,p.PRODUCTLINE,od.PRODUCTCODE ORDER by o.YEAR_ID)SELECT a.PRODUCTLINE,a.PRODUCTCODE,a.YEAR_ID,a.revenue as current_year,b.YEAR_ID,b.revenue as previous_year,round((a.revenue-b.revenue)*100/b.revenue,2) as growth FROM yearly_revenue a LEFT JOIN  yearly_revenue b on a.PRODUCTLINE =b.PRODUCTLINE and a.PRODUCTCODE=b.PRODUCTCODE and a.YEAR_ID=b.YEAR_ID+1 ORDER BY a.PRODUCTCODE, a.YEAR_ID;
--Seasonal Product Performance
SELECT p.PRODUCTLINE,od.PRODUCTCODE,o.YEAR_ID,o.QTR_ID,sum(od.SALES)as revenue FROM products p JOIN orderdetails od on p.PRODUCTCODE=od.PRODUCTCODE JOIN Orders o on od.ORDERNUMBER=o.ORDERNUMBER and od.ORDERLINENUMBER=o.ORDERLINENUMBER GROUP by p.PRODUCTLINE,od.PRODUCTCODE,o.YEAR_ID,o.QTR_ID ORDER by od.PRODUCTCODE,o.YEAR_ID,o.QTR_ID ASC;
--Top 10 Customers by Revenue and COUNTRY
SELECT c.CUSTOMERNAME,c.COUNTRY,SUM(od.SALES) AS total_revenue FROM Customers c JOIN Orders o ON c.customerID = o.customerID JOIN orderdetails od ON o.ORDERNUMBER = od.ORDERNUMBER GROUP BY c.CUSTOMERNAME, c.COUNTRY ORDER BY total_revenue DESC LIMIT 10;
--Monthly Revenue Trend
SELECT o.YEAR_ID,o.MONTH_ID,SUM(od.SALES) AS monthly_revenue FROM Orders o JOIN orderdetails od ON o.ORDERNUMBER = od.ORDERNUMBER GROUP BY o.YEAR_ID, o.MONTH_ID ORDER BY o.YEAR_ID, o.MONTH_ID;
--Yearly Growth Analysis
WITH yearly_revenue AS (SELECT o.YEAR_ID,SUM(od.SALES) AS total_revenue FROM Orders o JOIN orderdetails od ON o.ORDERNUMBER = od.ORDERNUMBER GROUP BY o.YEAR_ID)SELECT a.YEAR_ID AS current_year,a.total_revenue AS current_revenue,b.YEAR_ID AS previous_year,b.total_revenue AS previous_revenue,ROUND((a.total_revenue - b.total_revenue) * 100.0 / b.total_revenue, 2) AS growth_percentage FROM yearly_revenue a LEFT JOIN yearly_revenue b ON a.YEAR_ID = b.YEAR_ID + 1 ORDER BY a.YEAR_ID;
