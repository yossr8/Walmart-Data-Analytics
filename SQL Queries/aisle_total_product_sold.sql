with t as (select FACT_ORDER_PRODUCT.aisle_id as aisle_id,count(product_id) as total_product_sold
 from SYSTEM.FACT_ORDER_PRODUCT
 group by FACT_ORDER_PRODUCT.aisle_id )
 select aisle_Name,t.*
 from t 
 left join SYSTEM.DIM_AISLE on DIM_AISLE.aisle_ID=t.aisle_ID order by total_product_sold desc;