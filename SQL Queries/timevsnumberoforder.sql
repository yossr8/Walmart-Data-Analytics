with s as (select day_name,order_time,count(distinct order_id) as total_number_of_orders
from SYSTEM.FACT_ORDER_PRODUCT
join SYSTEM.DIM_DATE
on DIM_DATE. order_DATE_ID=FACT_ORDER_PRODUCT.DATE_ID
group by day_name,order_time)
select * from s;