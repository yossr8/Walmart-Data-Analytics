with table1 as (select DEPARTMENT_ID,product_id,count(product_id) as total_product_sold
 from SYSTEM.FACT_ORDER_PRODUCT
 group by DEPARTMENT_ID,product_id)
 ,finals as (select DEPARTMENT_ID,product_id ,total_product_sold as qantity_of_least_10,
 row_number() over (partition by DEPARTMENT_ID order by total_product_sold asc ) as ranking
 from table1)
 select DEPARTMENT_NAME, finals.*, product_name
 from finals 
 join SYSTEM.DIM_PRODUCT on dim_product.product_id=finals.product_id
 join SYSTEM.DIM_DEPARTMENT on DIM_DEPARTMENT.DEPARTMENT_ID=finals.DEPARTMENT_ID
 where ranking<=10  ;