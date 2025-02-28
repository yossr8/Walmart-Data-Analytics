with t as (select FACT_ORDER_PRODUCT.DEPARTMENT_ID as department_id,count(product_id) as total_product_sold
 from SYSTEM.FACT_ORDER_PRODUCT
 group by FACT_ORDER_PRODUCT.DEPARTMENT_ID )
 select DEPARTMENT_Name,t.*,  (total_product_sold/(select sum( total_product_sold) from t)) as percentage_from_total
 from t 
 left join SYSTEM.DIM_DEPARTMENT 
 on DIM_DEPARTMENT.DEPARTMENT_ID=t.DEPARTMENT_ID
  order by total_product_sold ;