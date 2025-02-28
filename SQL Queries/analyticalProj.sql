/*select * from FACT_ORDER_PRODUCT;
select * from DIM_AISLE;
select * from DIM_CUSTOMER;
select * from DIM_DATE;
select * from DIM_DEPARTMENT;
select * from DIM_ORDER;
select * from DIM_PRODUCT;
select * from DIM_DATE;*/
--select * from DIM_DATE;
--select * from FACT_ORDER_PRODUCT
/*Specifiy the highest selling Quarter and rank the highest and lowest one*/
WITH OrdersInQuarters AS (
    SELECT 
        CASE 
            WHEN EXTRACT(MONTH FROM ORDER_DATE) BETWEEN 1 AND 3 THEN 'Quarter 1'
            WHEN EXTRACT(MONTH FROM ORDER_DATE) BETWEEN 4 AND 6 THEN 'Quarter 2'
            WHEN EXTRACT(MONTH FROM ORDER_DATE) BETWEEN 7 AND 9 THEN 'Quarter 3'
            WHEN EXTRACT(MONTH FROM ORDER_DATE) BETWEEN 10 AND 12 THEN 'Quarter 4'
        END AS QUARTER, 
        EXTRACT(YEAR FROM ORDER_DATE) AS ORDER_YEAR
    FROM SYSTEM.DIM_DATE
),
QuarterOrderCounts AS (
    SELECT 
        QUARTER,
        ORDER_YEAR,
        COUNT(*) AS ORDER_COUNT
    FROM OrdersInQuarters
    GROUP BY QUARTER, ORDER_YEAR
),
RankedQuaret AS (
    SELECT 
        QUARTER,
        ORDER_YEAR,
        ORDER_COUNT,
        RANK() OVER (PARTITION BY ORDER_YEAR ORDER BY ORDER_COUNT DESC) AS RANKED_QUARTER
    FROM QuarterOrderCounts
)
SELECT 
    QUARTER,
    ORDER_YEAR,
    ORDER_COUNT,
    RANKED_QUARTER
FROM RankedQuaret
ORDER BY ORDER_YEAR,
    CASE 
        WHEN TRIM(QUARTER) = 'Quarter 1' THEN 1
        WHEN TRIM(QUARTER) = 'Quarter 2' THEN 2
        WHEN TRIM(QUARTER) = 'Quarter 3' THEN 3
        WHEN TRIM(QUARTER) = 'Quarter 4' THEN 4
    END;
    --------------------------------------------------------------------------------------------------------------------------------------------------------
  /* To see the most frequent time for purchases */

WITH OrderTimeCount AS (
    SELECT 
        DAY_NAME, 
        MONTH_NAME, 
        ORDER_TIME, 
        COUNT(*) AS OrderCount,
        ROW_NUMBER() OVER (PARTITION BY DAY_NAME ORDER BY COUNT(*) ASC, ORDER_TIME ASC) AS rn_min,
        ROW_NUMBER() OVER (PARTITION BY DAY_NAME ORDER BY COUNT(*) DESC, ORDER_TIME DESC) AS rn_max
    FROM system.DIM_DATE
    GROUP BY DAY_NAME, MONTH_NAME, ORDER_TIME
)
SELECT 
    DAY_NAME, 
    -- Min Order Time and Count
    MAX(CASE WHEN rn_min = 1 THEN ORDER_TIME END) AS MinOrderTime,
    MAX(CASE WHEN rn_min = 1 THEN OrderCount END) AS MinOrderCount,
    -- Max Order Time and Count
    MAX(CASE WHEN rn_max = 1 THEN ORDER_TIME END) AS MaxOrderTime,
    MAX(CASE WHEN rn_max = 1 THEN OrderCount END) AS MaxOrderCount
FROM OrderTimeCount
GROUP BY DAY_NAME, MONTH_NAME
HAVING 
    (MAX(CASE WHEN rn_min = 1 THEN ORDER_TIME END) IS NOT NULL
    OR MAX(CASE WHEN rn_max = 1 THEN ORDER_TIME END) IS NOT NULL)
ORDER BY 
    CASE 
        WHEN DAY_NAME = 'Saturday' THEN 1
        WHEN DAY_NAME = 'Sunday' THEN 2
        WHEN DAY_NAME = 'Monday' THEN 3
        WHEN DAY_NAME = 'Tuesday' THEN 4
        WHEN DAY_NAME = 'Wednesday' THEN 5
        WHEN DAY_NAME = 'Thursday' THEN 6
        WHEN DAY_NAME = 'Friday' THEN 7
    END;

----------------------------------------------------------------------------------------------------------------------------
--to know customer segmentation , Type of customers 
  
WITH RankedOrders AS (
    SELECT
        O.CUSTOMER_ID,
        O.DAYS_SINCE_LAST_ORDER,
        C.NAME,
        MAX(O.DAYS_SINCE_LAST_ORDER) OVER (PARTITION BY O.CUSTOMER_ID) AS max_day,
        MIN(O.DAYS_SINCE_LAST_ORDER) OVER (PARTITION BY O.CUSTOMER_ID) AS min_day,
        (MAX(O.DAYS_SINCE_LAST_ORDER) OVER (PARTITION BY O.CUSTOMER_ID) - 
         MIN(O.DAYS_SINCE_LAST_ORDER) OVER (PARTITION BY O.CUSTOMER_ID)) AS purchase_gap,
        ROW_NUMBER() OVER (PARTITION BY O.CUSTOMER_ID ORDER BY O.DAYS_SINCE_LAST_ORDER DESC) AS rn
    FROM system.DIM_ORDER O
    JOIN system.DIM_CUSTOMER C ON O.CUSTOMER_ID = C.CUSTOMER_ID
)
SELECT 
    CUSTOMER_ID, 
    NAME,
    purchase_gap,
    CASE
        WHEN purchase_gap BETWEEN 1 AND 15 THEN 'Loyal'  -- Loyal customers (less than or equal to 10 days gap)
        WHEN purchase_gap BETWEEN 15 AND 29 THEN 'Mid loyal'  -- Mid loyal customers (between 20 and 29 days gap)
        WHEN purchase_gap >= 30 THEN 'Churned'  -- Churned customers (more than 30 days gap) -- This can be a fallback for any value that doesn't match the other conditions
    END AS CustomerStatus
FROM RankedOrders
WHERE rn = 1 
  AND ROWNUM <= 40 -- This ensures that only the first row for each customer is returned
ORDER BY purchase_gap;

--------------------------------------------------------------------------------------------------------------------
--to know the number of females and their maritual status 
SELECT 
    DISTINCT GENDER, MARITAL_STATUS,
    COUNT(GENDER) OVER (PARTITION BY GENDER) AS NumberOfCustomers,
    COUNT(*) OVER (PARTITION BY MARITAL_STATUS) AS COUNTCUST
FROM 
    system.DIM_CUSTOMER
    WHERE GENDER = 'Female';
    
---to know the number of males and their maritual status 
SELECT 
    DISTINCT GENDER, MARITAL_STATUS,
    COUNT(GENDER) OVER (PARTITION BY GENDER) AS NumberOfCustomers,
    COUNT(MARITAL_STATUS) OVER (PARTITION BY MARITAL_STATUS) AS COUNTCUST
FROM 
    system.DIM_CUSTOMER
    WHERE GENDER = 'Male';
   
--select count(gender) from DIM_CUSTOMER;
-----------------------------------------------------------------------------------------------------------
-- to know top selling product 

WITH TOPSELLING AS(
    SELECT 
        F.PRODUCT_ID, 
        P.PRODUCT_NAME AS TOP_SELLING_PRODUCT, 
        COUNT(P.PRODUCT_ID) AS TotalSales,
        ROW_NUMBER() OVER (ORDER BY COUNT(F.ORDER_ID) DESC) AS NUM,
        RANK() OVER(ORDER BY COUNT(F.ORDER_ID) DESC) AS RANKED 
    FROM 
        system.FACT_ORDER_PRODUCT F
    JOIN 
        system.DIM_PRODUCT P ON F.PRODUCT_ID = P.PRODUCT_ID
    GROUP BY 
        F.PRODUCT_ID, P.PRODUCT_NAME
)

SELECT  
     PRODUCT_ID, 
    TOP_SELLING_PRODUCT, 
    TotalSales, RANKED 
FROM TOPSELLING
WHERE NUM <= 20;

-------------------------------------------------------------------------------------------------------------------
-- To know least selling products
WITH LEAST_SELLING AS (
    SELECT 
        F.PRODUCT_ID, 
        P.PRODUCT_NAME AS MIN_SELLING_PRODUCT, 
        COUNT(P.PRODUCT_ID) AS TotalSales,
        ROW_NUMBER() OVER (ORDER BY COUNT(F.ORDER_ID)) AS NUM,
        DENSE_RANK() OVER(ORDER BY COUNT(F.ORDER_ID)) AS RANKED 
    FROM 
        system.FACT_ORDER_PRODUCT F
    JOIN 
        system.DIM_PRODUCT P ON F.PRODUCT_ID = P.PRODUCT_ID
    GROUP BY 
        F.PRODUCT_ID, P.PRODUCT_NAME
)
SELECT  
    TotalSales,count(product_id)
FROM LEAST_SELLING
group by TotalSales-- Fetch top 10 least selling products based on their rank
ORDER BY TotalSales;    -- Order by rank to get them in ascending order of sales
-----------------------------------------------------------------------------------
-- TO KNOW TOP SELLING DEPARTMENT
WITH DepartmentTopSelling AS (
    SELECT 
        F.PRODUCT_ID, 
        P.PRODUCT_NAME AS TOP_SELLING_PRODUCT, 
        D.DEPARTMENT_NAME, 
        COUNT(F.PRODUCT_ID) AS TotalSales,
        ROW_NUMBER() OVER (PARTITION BY D.DEPARTMENT_NAME ORDER BY COUNT(F.PRODUCT_ID) DESC) AS RANK_IN_DEPARTMENT
    FROM 
        system.FACT_ORDER_PRODUCT F
    JOIN 
        DIM_PRODUCT P ON F.PRODUCT_ID = P.PRODUCT_ID
    JOIN 
        DIM_DEPARTMENT D ON D.DEPARTMENT_ID = F.DEPARTMENT_ID
    GROUP BY 
        F.PRODUCT_ID, P.PRODUCT_NAME, D.DEPARTMENT_NAME
)
SELECT  
    PRODUCT_ID, 
    TOP_SELLING_PRODUCT, 
    TotalSales, 
    DEPARTMENT_NAME
FROM DepartmentTopSelling
WHERE RANK_IN_DEPARTMENT = 1;
---------------------------------------------------
-- TO KNOW TOP SELLING PRODUCT IN EACH AISLE
WITH ProductSales AS (
    SELECT 
        P.PRODUCT_ID, 
        P.PRODUCT_NAME, 
        A.AISLE_NAME, 
        COUNT(F.PRODUCT_ID) AS TotalSales,
        ROW_NUMBER() OVER (PARTITION BY A.AISLE_NAME ORDER BY COUNT(F.PRODUCT_ID) DESC) AS RANK_IN_AISLE
    FROM 
        DIM_AISLE A
    JOIN 
        FACT_ORDER_PRODUCT F ON A.AISLE_ID = F.AISLE_ID
    JOIN 
        DIM_PRODUCT P ON P.PRODUCT_ID = F.PRODUCT_ID
    GROUP BY 
        P.PRODUCT_ID, P.PRODUCT_NAME, A.AISLE_NAME
)
SELECT 
    PRODUCT_ID, 
    PRODUCT_NAME, 
    AISLE_NAME, 
    TotalSales
FROM 
    ProductSales
WHERE 
    RANK_IN_AISLE = 1;
------------------------------------------------------------------- 
-- TO KNOW MIN SELLING PRODUCT IN AISLE
WITH ProductSales AS (
    SELECT 
        P.PRODUCT_ID, 
        P.PRODUCT_NAME, 
        A.AISLE_NAME, 
        COUNT(F.PRODUCT_ID) AS TotalSales,
        ROW_NUMBER() OVER (PARTITION BY A.AISLE_NAME ORDER BY COUNT(F.PRODUCT_ID) ASC) AS RANK_IN_AISLE
    FROM 
        DIM_AISLE A
    JOIN 
        FACT_ORDER_PRODUCT F ON A.AISLE_ID = F.AISLE_ID
    JOIN 
        DIM_PRODUCT P ON P.PRODUCT_ID = F.PRODUCT_ID
    GROUP BY 
        P.PRODUCT_ID, P.PRODUCT_NAME, A.AISLE_NAME
)
SELECT 
    PRODUCT_ID, 
    PRODUCT_NAME, 
    AISLE_NAME, 
    TotalSales
FROM 
    ProductSales
WHERE 
    RANK_IN_AISLE = 1;
----------------------------------------------------------------------------------
WITH CTE_ReorderCounts AS (
    SELECT 
        C.CUSTOMER_ID, 
        C.NAME AS CUSTOMER_NAME, 
        P.PRODUCT_NAME, 
        COUNT(F.ORDER_ID) AS ReorderCount
    FROM 
        DIM_PRODUCT P
    JOIN 
        FACT_ORDER_PRODUCT F ON F.PRODUCT_ID = P.PRODUCT_ID
    JOIN 
        DIM_CUSTOMER C ON C.CUSTOMER_ID = F.CUSTOMER_ID
    WHERE 
        C.CUSTOMER_ID <= 20 -- Filter for specific customers
    GROUP BY 
        C.CUSTOMER_ID, C.NAME, P.PRODUCT_NAME
),
CTE_Ranked AS (
    SELECT 
        CUSTOMER_ID,
        CUSTOMER_NAME,
        PRODUCT_NAME,
        ReorderCount,
        ROW_NUMBER() OVER (PARTITION BY CUSTOMER_ID ORDER BY ReorderCount DESC) AS FAVORABLE_ITEM_RANK
    FROM 
        CTE_ReorderCounts
)
SELECT 
    CUSTOMER_ID,
    CUSTOMER_NAME,
    PRODUCT_NAME,
    ReorderCount,
    FAVORABLE_ITEM_RANK
FROM 
    CTE_Ranked
WHERE 
    ReorderCount > 1 -- Only include reordered products
ORDER BY 
    CUSTOMER_ID, FAVORABLE_ITEM_RANK, PRODUCT_NAME;

--------------------------------------------------------------------------------
WITH DepartmentTopReordered AS (
    SELECT 
        F.PRODUCT_ID, 
        P.PRODUCT_NAME AS TOP_REORDERED_PRODUCT, 
        D.DEPARTMENT_NAME, 
        COUNT(F.REORDERED) AS TotalReorders, 
        ROW_NUMBER() OVER (PARTITION BY D.DEPARTMENT_NAME ORDER BY COUNT(F.REORDERED) DESC) AS RANK_IN_DEPARTMENT
    FROM 
        FACT_ORDER_PRODUCT F
    JOIN 
        DIM_PRODUCT P ON F.PRODUCT_ID = P.PRODUCT_ID
    JOIN 
        DIM_DEPARTMENT D ON D.DEPARTMENT_ID = F.DEPARTMENT_ID
    GROUP BY 
        F.PRODUCT_ID, P.PRODUCT_NAME, D.DEPARTMENT_NAME
)
SELECT  
    PRODUCT_ID, 
    TOP_REORDERED_PRODUCT, 
    TotalReorders, 
    DEPARTMENT_NAME
FROM DepartmentTopReordered
WHERE RANK_IN_DEPARTMENT = 1;



