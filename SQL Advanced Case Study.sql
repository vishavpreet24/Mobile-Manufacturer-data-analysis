--SQL Advance Case Study
USE master;

SELECT * FROM dbo.DIM_CUSTOMER;
SELECT * FROM dbo.DIM_DATE;
SELECT * FROM dbo.DIM_LOCATION;
SELECT * FROM dbo.DIM_MANUFACTURER;
SELECT * FROM dbo.DIM_MODEL;
SELECT * FROM dbo.FACT_TRANSACTIONS;



--Q1--BEGIN 

SELECT distinct l.[State]
FROM dbo.DIM_LOCATION AS l
JOIN dbo.FACT_TRANSACTIONS AS t 
    ON l.IDLocation = t.IDLocation
JOIN dbo.DIM_DATE AS d 
    ON d.[DATE] = t.[Date]
WHERE d.[YEAR] >= 2005;

--Q1--END

--Q2--BEGIN

SELECT TOP 1  
    l.[State], 
    sum(t.Quantity) AS Total
FROM dbo.DIM_LOCATION AS l
JOIN dbo.FACT_TRANSACTIONS AS t 
    ON l.IDLocation = t.IDLocation
JOIN dbo.DIM_MODEL m 
    ON t.IDModel = m.IDModel
JOIN dbo.DIM_MANUFACTURER mf 
    ON m.IDManufacturer = mf.IDManufacturer
WHERE  l.Country = 'US' AND mf.Manufacturer_Name = 'Samsung'
GROUP BY l.[State]
ORDER BY Total DESC;

--Q2--END

--Q3--BEGIN      

SELECT 
    m.Model_Name,
    l.ZipCode,
    l.[State],
    COUNT(*) AS total_transactions
FROM dbo.FACT_TRANSACTIONS AS t     
JOIN dbo.DIM_LOCATION AS l 
    ON l.IDLocation = t.IDLocation
JOIN dbo.DIM_MODEL m 
    ON t.IDModel = m.IDModel
GROUP BY 
    l.[State],
    l.ZipCode,
    m.Model_Name;
         
--Q3--END

--Q4--BEGIN

SELECT TOP 1
    Model_Name AS Cheapest_Cellphone,
    Unit_price AS Price
FROM dbo.DIM_MODEL
ORDER BY Unit_price ASC;

--Q4--END

--Q5--BEGIN

WITH Manufacturers AS (
    SELECT TOP 5
        m.IDManufacturer,
        SUM(Quantity) AS Sales_Quantity
    FROM dbo.FACT_TRANSACTIONS ft
    JOIN dbo.DIM_MODEL AS m 
        ON ft.IDModel = m.IDModel
    GROUP BY m.IDManufacturer
    ORDER BY SUM(Quantity) DESC
),
AvgPricePerModel AS (
    SELECT 
        m.IDManufacturer,
        m.Model_Name,
        AVG(m.Unit_price) AS Average_Price
    FROM dbo.DIM_MODEL m
    JOIN dbo.FACT_TRANSACTIONS ft 
        ON m.IDModel = ft.IDModel
    JOIN Manufacturers mf 
        ON m.IDManufacturer = mf.IDManufacturer
    GROUP BY 
        m.IDManufacturer,
        m.Model_Name
)
SELECT 
    Model_Name,
    Average_Price
FROM AvgPricePerModel
ORDER BY Average_Price;


--Q5--END

--Q6--BEGIN

SELECT 
    c.Customer_Name,
    AVG(ft.TotalPrice) AS Average_Amount_Spent
FROM dbo.FACT_TRANSACTIONS ft
JOIN dbo.DIM_CUSTOMER AS c 
    ON ft.IDCustomer = c.IDCustomer
JOIN dbo.DIM_DATE d 
    ON ft.Date = d.[DATE]
WHERE YEAR(d.[DATE]) = 2009
GROUP BY c.Customer_Name
HAVING AVG(ft.TotalPrice) > 500;



--Q6--END
	
--Q7--BEGIN  

WITH Models AS (
    SELECT 
        IDModel,
        YEAR(Date) AS Transaction_Year,
        ROW_NUMBER() OVER (PARTITION BY YEAR(Date) ORDER BY SUM(Quantity) DESC) AS Row_Num
    FROM dbo.FACT_TRANSACTIONS
    WHERE YEAR(Date) IN (2008, 2009, 2010)
    GROUP BY IDModel, YEAR(Date)
)
SELECT IDModel
FROM  Models
WHERE Row_Num <= 5
GROUP BY IDModel
HAVING COUNT(DISTINCT Transaction_Year) = 3;
	
	
--Q7--END	

--Q8--BEGIN
WITH Sales AS (
    SELECT 
        mf.Manufacturer_Name,
        YEAR(ft.Date) AS Transaction_Year,
        SUM(ft.Quantity) AS Total_Sales,
        ROW_NUMBER() OVER (PARTITION BY YEAR(ft.Date) ORDER BY SUM(ft.Quantity) DESC) AS RowNum
    FROM dbo.FACT_TRANSACTIONS ft
    JOIN dbo.DIM_MODEL m 
        ON ft.IDModel = m.IDModel
    JOIN dbo.DIM_MANUFACTURER mf
        ON m.IDManufacturer = mf.IDManufacturer
    GROUP BY mf.Manufacturer_Name, YEAR(ft.Date)
)
SELECT  
    MAX(CASE WHEN Transaction_Year = 2009 AND RowNum = 2 THEN Manufacturer_Name END) AS Manufacturer_Name_2009,
    MAX(CASE WHEN Transaction_Year = 2010 AND RowNum = 2 THEN Manufacturer_Name END) AS Manufacturer_Name_2010
FROM Sales



--Q8--END

--Q9--BEGIN
SELECT DISTINCT
    mf.IDManufacturer,
    mf.Manufacturer_Name
FROM dbo.DIM_MANUFACTURER mf
JOIN dbo.DIM_MODEL m 
    ON m.IDManufacturer = mf.IDManufacturer
JOIN FACT_TRANSACTIONS ft 
    ON m.IDModel = ft.IDModel
JOIN DIM_DATE dd
    ON ft.Date = dd.[DATE]
WHERE YEAR(dd.[DATE]) = 2010 AND mf.IDManufacturer NOT IN (
    SELECT DISTINCT
        mf2.IDManufacturer
    FROM DIM_MANUFACTURER mf2
    JOIN DIM_MODEL m2 
        ON mf2.IDManufacturer = m2.IDManufacturer
    JOIN FACT_TRANSACTIONS ft2 
        ON m2.IDModel = ft2.IDModel
    JOIN DIM_DATE dd2 
        ON ft2.Date = dd2.[DATE]
    WHERE YEAR(dd2.[DATE]) = 2009
    );
	

--Q9--END

--Q10--BEGIN
WITH Customers AS (
    SELECT TOP 100
        ft.IDCustomer,
        YEAR(ft.Date) AS Transaction_Year,
        AVG(ft.TotalPrice) AS Avg_Spend,
        AVG(ft.Quantity) AS Avg_Quantity
    FROM FACT_TRANSACTIONS ft
    GROUP BY ft.IDCustomer, YEAR(ft.Date)
    ORDER BY SUM(ft.TotalPrice) DESC
),
YearlySpend AS (
    SELECT 
        IDCustomer,
        Transaction_Year,
        Avg_Spend,
        LAG(Avg_Spend) OVER (PARTITION BY IDCustomer ORDER BY Transaction_Year) AS Prev_Avg_Spend
    FROM Customers
)
SELECT 
    c.IDCustomer,
    c.Transaction_Year,
    c.Avg_Spend,
    c.Avg_Quantity,
    CASE 
        WHEN ys.Prev_Avg_Spend IS NOT NULL THEN ((c.Avg_Spend - ys.Prev_Avg_Spend) / ys.Prev_Avg_Spend) * 100
        ELSE NULL
    END AS Spend_Percentage_Change
FROM Customers c
LEFT JOIN  YearlySpend ys 
    ON c.IDCustomer = ys.IDCustomer AND c.Transaction_Year = ys.Transaction_Year;
	

--Q10--END
	