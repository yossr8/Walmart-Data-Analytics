select DAYS_SINCE_LAST_ORDER,count(distinct DIM_order.order_id) as number_of_orders
from SYSTEM.FACT_ORDER_PRODUCT
join SYSTEM.DIM_order
on FACT_ORDER_PRODUCT.order_id=DIM_order.order_id
group by DAYS_SINCE_LAST_ORDER
order by days_since_last_order;