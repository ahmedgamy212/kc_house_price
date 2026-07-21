
with levles as(select 
	zipcode,
	grade,
	AVG(price) as [avereage price]
from housing_data
group by zipcode,grade
),houses as(select 
	a.id,a.zipcode,
	a.price as [Current Price],a.grade ,
	a.condition,a.sqft_living,
	a.bathrooms , b.[avereage price] ,
	(a.bathrooms*5000+a.sqft_living*40)as [Renovation Cost],
	c.[avereage price]as[Expected Price]
from housing_data a left join levles b
on a.zipcode =b.zipcode and a.grade=b.grade
left join levles c on a.zipcode=c.zipcode
and a.grade+1=c.grade),
ROI as(
	select 
	id,zipcode,bathrooms,
	[avereage price],grade,condition,sqft_living,
	([Expected Price]-[Renovation Cost]-[Current Price]) as ROI
from houses),Ranking as(select * ,	DENSE_RANK()over( order by ROI desc) as RK

from ROI
)
select 
	RK,id,zipcode,
	grade,condition,
	bathrooms,sqft_living,[avereage price],
	ROI
from Ranking
order by RK asc
----------------------------------------
-----------------------------------------------
with CTE as (
select
	zipcode,AVG(price*1/sqft_living) as [avg_Sqft_price]
from housing_data
group by zipcode
),CTE2 as(
select
	a.id,a.zipcode, a.price,
	(b.avg_Sqft_price*a.sqft_living) as[Expected Price ]
from housing_data a left join CTE b
on a.zipcode=b.zipcode
),CTE3 as(
select*,
	[Expected Price ]-price as Diff
	from CTE2
), CTE4 as (
select *, case 
when Diff> 50000 THEN 'Underpriced'
WHEN Diff < -50000 THEN 'Overpriced'
ELSE 'Fair' END as [Classification]
from CTE3
)
select * 
from CTE4
order by [Classification] desc
---------------------------------------------------
with cte as (SELECT id,price,(price*1.0/sqft_living) as [avg_sqft],
    [date],
    CONVERT(date, LEFT([date], 8), 112) AS SaleDate
FROM housing_data
),cte2 as(select *, MONTH(SaleDate) as [Sale_Month],
YEAR(SaleDate) as [Sale_Year]
from cte
),cte3 as (
select Sale_Month,
		sale_year,
	avg(price) as [AVG_Per_month] ,
	count(id) as [soled_per_month],
	min(price) as[min_price_per_mo] ,
	max(price)as[max_price_per_mo],
	AVG(avg_sqft) as[avg_sqft_month]
from cte2
group by Sale_Year,Sale_Month
),cte4 as(
select*,
	DENSE_RANK()over(order by [AVG_Per_month] desc)RK
	,DENSE_RANK()over(order by [AVG_Per_month])RK2,
	case when [AVG_Per_month]<520000 then 'Weak Market'
	when [AVG_Per_month] < 545000 then 'Average'
	else 'Excellent Market' end as [Levels]
from cte3
)select Sale_Year,
Sale_Month,AVG_Per_month,
soled_per_month,max_price_per_mo,min_price_per_mo
,avg_sqft_month,RK,RK2,Levels
from cte4
where RK<4 or RK2<4
-------------------------------------------
with CTE as(
select 
	zipcode,
	COUNT(*) as houses,
	avg(price) as[avg_price],
	AVG(grade) as [avg_grade],
	AVG(condition) as[avg_condition]
from housing_data
group by zipcode
),CTE2 as (
select
	a.id,b.avg_grade,a.price,
	b.avg_condition,b.avg_price,
	(b.avg_price-a.price)as [GPA]
from housing_data a left join CTE b
on a.zipcode=b.zipcode
),CTE3 as (
select*,
	(GPA+(avg_condition*265)+(avg_grade*265)) as [Investment Score]
from CTE2
),CTE4 as(
select *,
		DENSE_RANK()over(order by [Investment Score] desc) as RK
from CTE3
)
select *
from CTE4
where RK<11
-----------------------------------------------------
with CTE as(
select 
	zipcode,
	avg(price) as[avg_price],
	AVG(condition) as[avg_condition]
from housing_data
group by zipcode
),CTE2 as(
select b.avg_condition,b.avg_price,b.zipcode,a.price,
(b.avg_condition-a.condition) as[Condition Gpa],
case when a.condition <4 then (a.bathrooms*5000+a.sqft_living*40)
	when a.condition<7 then  (a.bathrooms*4000+a.sqft_living*30)
	else (a.bathrooms*3000+a.sqft_living*20) END as [Renovation Cost]
from CTE b right join housing_data a
on a.zipcode = b.zipcode
),CTE3 as(select* ,
(avg_price-price-[Renovation Cost])as[Potential Profit]
from CTE2
),CTE4 as (
select *,DENSE_RANK()over(order by [Potential Profit] DESC) as RK from CTE3
)select * from CTE4
where RK<16
-------------------------------------------
With CTE as (
	select zipcode,grade
	,COUNT(*) as Total_Houses
	,AVG(price) as AVG_Price
	from housing_data
	group by zipcode,grade
),CTE2 as(
select 
	a.id,a.price,
	b.AVG_Price,b.Total_Houses,(b.AVG_Price-a.price) as [Luxury Discount]
from housing_data a left join CTE b
on a.zipcode = b.zipcode AND a.grade=b.grade
where a.grade>9 and a.condition>4
),CTE3 as(
select*,
	DENSE_RANK() over(order by [Luxury Discount] desc ) as RK
from CTE2
)
select * from CTE3
where RK<21