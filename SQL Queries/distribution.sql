WITH t AS (
    SELECT department_id, product_id, COUNT(product_id) AS total_product_sold
    FROM SYSTEM.FACT_ORDER_PRODUCT
    GROUP BY department_id, product_id
),
s as (SELECT 
    t.*, 
    AVG(total_product_sold) OVER (PARTITION BY department_id) AS average_sold_in_each_dep, 
            PERCENTILE_CONT(0) WITHIN GROUP (ORDER BY total_product_sold) 
        OVER (PARTITION BY department_id) AS percentile0th_sale_amount ,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY total_product_sold) 
        OVER (PARTITION BY department_id) AS percentile25th_sale_amount ,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY total_product_sold) 
        OVER (PARTITION BY department_id) AS median_sale_amount,
                PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY total_product_sold) 
        OVER (PARTITION BY department_id) AS percentile75th_sale_amount ,
                PERCENTILE_CONT(1) WITHIN GROUP (ORDER BY total_product_sold) 
        OVER (PARTITION BY department_id) AS percentile100th_sale_amount 
FROM t order by department_id,total_product_sold desc)
select department_name,  average_sold_in_each_dep,median_sale_amount ,percentile0th_sale_amount,percentile25th_sale_amount,percentile75th_sale_amount ,percentile100th_sale_amount 
from s
join SYSTEM.DIM_DEPARTMENT
on s.department_id=DIM_DEPARTMENT.department_id
group by  department_name,  average_sold_in_each_dep,median_sale_amount,percentile0th_sale_amount,percentile25th_sale_amount,percentile75th_sale_amount ,percentile100th_sale_amount 
;
