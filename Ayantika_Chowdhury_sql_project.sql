create database mavenRESTAURANTorders;
use mavenRESTAURANTorders;
select * from menu_items;
select * from order_details;

select orderdate_new from order_details order by 1 desc;

ALTER TABLE  order_details
CHANGE ï»¿order_details_id order_details_id int;

ALTER TABLE  menu_items
CHANGE ï»¿menu_item_id menu_item_id int;

alter table order_details
add column OrderDate_new date;

update order_details
set OrderDate_new= case 
				     when order_date like '%-%-%' then str_to_date(order_date,'%m-%d-%Y')
                     else str_to_date(order_date,'%m/%d/%Y')
                     end;
                     
set sql_safe_updates =0;

alter table order_details
add column Day_Name varchar(20);

update order_details 
set Day_Name=dayname(orderDate_new) ;

alter table order_details
add column TimeOfTheDay varchar(20);

    
    
alter table  order_details
drop  column timeoftheday ;

update order_details
set TimeOfTheDay =  case when left(order_time,locate(":",order_time)-1) <12 and 
right(order_time,2) in ("pm") then left(order_time,locate(":",order_time)-1)+12
else left(order_time,locate(":",order_time)-1)
end
;



/* Q1.What were the top 5 most ordered items? What categories were they in?*/

select item_id,item_name,category, count(item_id) as numberOForders
from order_details o inner join menu_items m on o.item_id=m.menu_item_id
group by item_id,item_name,category
order by 4 desc
limit 5;

select item_name,category, count(item_id) as numberOForders
from order_details o inner join menu_items m on o.item_id=m.menu_item_id
group by item_name,category
order by 3 desc
limit 5;

/*Q2.What were the least ordered items? What categories were they in?*/

select item_id,item_name,category, count(item_id) 
from order_details o inner join menu_items m on o.item_id=m.menu_item_id
group by item_id,item_name,category
order by 4
limit 5;

/*Q3. Which items in the menu are most and least expensive ?*/

select item_name,category,price
from menu_items 
order by price desc;

/*Q4. Which is the peak order time ? */

select timeoftheday,count(distinct order_id) as numberoforders
from order_details
group by timeoftheday
order by 1;

select order_time, order_id,timeoftheday from order_details where timeoftheday in('12');

select count(distinct order_id) from order_details where timeoftheday in('12');

/*Q5. Top 10 items ordered  during the peak time period ( 12 pm)  ?*/

with peaktime as (select timeoftheday,count(distinct order_id) as numberoforders
from order_details
group by timeoftheday
order by 2 desc
limit 1)

select m.item_name, m.category, count(distinct order_id) NumberOfOrders
from order_details o inner join menu_items m on o.item_id = m.menu_item_id inner join PeakTime p on o.TimeOfTheDay = p.TimeOfTheDay
group by m.item_name, m.category
order by NumberOfOrders Desc
limit 10;

/*Q6. Which day of week has highest number of orders ? */

select day_name, count(distinct order_id) as numberoforders
from order_details
group by day_name 
order by 2 desc;

/*Q7. What are the top 5 highest value orders(order ids) ? */

select order_id,sum(price) as totalorderPRICE
from order_details o inner join menu_items m on o.item_id = m.menu_item_id
group by order_id
order by 2 desc 
limit 5;

/* Q7.1. What do the top 5 highest spend orders look like? Which items did they buy and how much did they spend?*/

with highestvalue as (select order_id,sum(price) as totalorderPRICE
from order_details o inner join menu_items m on o.item_id = m.menu_item_id
group by order_id
order by 2 desc 
limit 5)

select h.order_id , item_name, sum(price) over (partition by h.order_id,item_name order by sum(price) desc) as totalprice
from order_details o inner join menu_items m on o.item_id = m.menu_item_id inner join highestvalue h on o.order_id = h.order_id
group by order_id , item_name;

/*7.2 Top 10 bestselling items (based on  top 5 orders' revenue) */

with top5 as (with highestvalue as (select order_id,sum(price) as totalorderPRICE
from order_details o inner join menu_items m on o.item_id = m.menu_item_id
group by order_id
order by 2 desc 
limit 5)

select h.order_id , item_name, sum(price) over (partition by h.order_id,item_name order by sum(price) desc) as totalprice
from order_details o inner join menu_items m on o.item_id = m.menu_item_id inner join highestvalue h on o.order_id = h.order_id
group by order_id , item_name)

select item_name, sum(totalprice) total_price
from top5
group by item_name
order by 2 desc limit 10;

/* 7.3 same q . Which cuisines should we focus on developing more menu items for based on top 5 highest value orders ?*/

select category, count(item_id) as total_items_ordered
from order_details o inner join menu_items m on o.item_id=m.menu_item_id
where order_id in(440,2075,1957,330,2675
)
group by category
order by 2 desc;

/*Q 7.3.(same question) What are the count of items in each category in top 5 orders ?  */

with highestvalue as (select order_id,sum(price) as totalorderPRICE
from order_details o inner join menu_items m on o.item_id = m.menu_item_id
group by order_id
order by 2 desc 
limit 5)

select  category, count(item_id) as number_of_items
from order_details o inner join menu_items m on o.item_id = m.menu_item_id inner join highestvalue h on o.order_id = h.order_id
group by  category
order by 2 desc;

/*Q8. List of items that are expensive but underperforming.*/
Select   m.item_name,  m.price, o.total_orders
from     menu_items m inner join 
	     ((select item_id, COUNT(*) as total_orders
          from order_details
          group by item_id)) o
	      on m.menu_item_id = o.item_id
where o.total_orders < (
      select AVG(total_orders)
      from (
        select item_id,COUNT(*) as total_orders
        from order_details
        group by item_id
           ) as avg_total_order
                      )
AND    m.price > (
       select AVG(price) from menu_items
             as avg_price  ) 
order by o.total_orders;



/*Q9. Category wise number of orders*/

select category , count(  order_id) total_number_of_orders
from order_details o inner join menu_items m on o.item_id = m.menu_item_id
group by category
order by 2 desc;

/*Q10. Category wise menu items*/

select category , count( menu_item_id) as total_menu_items 
from  menu_items 
group by category
order by 2 desc;

/*Q11. Category wise revenue*/

select category , sum( price) as total_revenue 
from  order_details o inner join menu_items m on o.item_id = m.menu_item_id
group by category
order by 2 desc;

/* Q12. Show Top 3 items in each category based on the number of orders */

with cte as (select category, item_name, count(order_id) as numberOForders, 
rank () over (partition by category order by count(order_id) desc) as rnk
from order_details o inner join menu_items m on o.item_id=m.menu_item_id
group by category,item_name )

select * 
from cte 
where rnk<=3;

/* 13 Show total monthly orders  */

select monthname(orderdate_new) as monthname, count( distinct order_id) as total_orders
from order_details
group by monthname(orderdate_new);


/*total orders*/

select count(distinct order_id)
from order_details;

SET SESSION sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));

select timeoftheday,count(distinct order_id) as numberoforders
from order_details
group by timeoftheday
order by 2 desc
limit 1;