--select  order_id from  SYSTEM.FACT_ORDER_PRODUCT;
--------------------------------------
WITH dist AS (
  SELECT order_id, product_id
  FROM SYSTEM.FACT_ORDER_PRODUCT
  GROUP BY order_id, product_id
),
sam AS (
  SELECT product_id, 
         -- Calculate the support percentage for each product
         (COUNT(order_id) / (SELECT COUNT(DISTINCT order_id) FROM dist)) AS product_support
  FROM dist
  GROUP BY product_id),
supportgth as (
SELECT product_id,product_support
FROM sam
where product_support >= 0.00020
GROUP BY product_id, product_support)
--before_last as(select * from supportgth t cross join (select product_id as pd ,product_support as ps from supportgth t2) where product_id <> pd) 
--select  *from supportgth ;

-----------------------------------------------support calc 
,beforelastt as
(SELECT t1.order_id as order_id_A,t1.product_id as product_a,  t2.od,t2.pd ,count(*) over (partition by product_id,PD) as countA_B,
count(*) over (partition by product_id,PD)/(SELECT COUNT(DISTINCT order_id) FROM dist) as supportA_B
from (
    SELECT order_id AS od, product_id AS pd
    FROM SYSTEM.FACT_ORDER_PRODUCT
)t2
join SYSTEM.FACT_ORDER_PRODUCT t1
ON  t2.od=t1.order_id
WHERE t1.product_id <> t2.pd and product_id in(select  product_id from supportgth) and  pd in (select  product_id from supportgth) and  t1.product_id < t2.pd
order by order_id,product_id,PD),
 lastt as(
select    SYSTEM.FACT_ORDER_PRODUCT.*, 
        beforelastt.*,
        sg1.product_support AS support_value_1,  -- Alias for the first product_support
        sg2.product_support AS support_value_2 ,supportA_B/(  sg1.product_support *  sg2.product_support) as lift  
from SYSTEM.FACT_ORDER_PRODUCT
left join beforelastt 
on product_id=product_a and SYSTEM.FACT_ORDER_PRODUCT.order_id=order_id_A
 left join  supportgth  sg1 
 on product_a=sg1.product_id
 left join supportgth  sg2 
 on pd=sg2.product_id where supportA_B>=0.00020),
 assosiation as (select distinct product_A,pd,lift 
 from lastt order by lift desc)
 select  t1.PRODUCT_Name , assosiation.*,t2.PRODUCT_Name
 from assosiation
  join SYSTEM.DIM_PRODUCT t1
 on product_A=t1.PRODUCT_ID 
 join SYSTEM.DIM_PRODUCT t2
  on pd=t2.PRODUCT_ID ;
 
 
--select lastt.*,lastt.supportA_B/( support_value_1* support_value_2) as lift from lastt;


------------------------------way to choose support ----------------------------------------------------------------
SELECT 
    product_id, 
    COUNT(DISTINCT order_id)/(select count(order_id) from SYSTEM.FACT_ORDER_PRODUCT) AS support
FROM SYSTEM.FACT_ORDER_PRODUCT
GROUP BY product_id
HAVING COUNT(DISTINCT order_id) > 
    (SELECT PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY COUNT(DISTINCT order_id)) 
     FROM SYSTEM.FACT_ORDER_PRODUCT GROUP BY product_id) order by support ;



