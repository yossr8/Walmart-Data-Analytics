select DAY_NAME,count(PRODUCT_ID) as total_product_sold ,count( distinct ORDER_ID) as total_orders
from SYSTEM.FACT_ORDER_PRODUCT join SYSTEM.DIM_DATE
on ORDER_DATE_ID=ORDER_ID group by DAY_NAME ;
