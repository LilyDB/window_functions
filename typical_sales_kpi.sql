

drop table if exists #temp1
drop table if exists #temp2

select 
	p1.CalendarDate
    ,p1.Customer
    ,p1.Category
    ,p1.Amount
	,[PreviousPurchaseAmount] = lag(p1.Amount) over(
												partition by p1.Customer 
												order by p1.CalendarDate asc)
	,[NextPurchaseAmount] = lead(p1.Amount) over(
												partition by p1.Customer 
												order by p1.CalendarDate asc)
	,[FirstPurchaseAmount] = p2.Amount
	,[SumofCategoryAmount] 

into #temp1
from [dbo].[PurchaseAmount] p1

left join --first purchase
		(select 
		[Customer],
		[Amount],
		row_no = row_number() over (
											partition by Customer
											order by CalendarDate asc)
		from [dbo].[PurchaseAmount] 
		) p2
on p1.Customer = p2.Customer

left join (--sum of category amount by date
			select
					CalendarDate, 
					Customer,
					Category,
					[SumofCategoryAmount] = sum(Amount) over(
															partition by Category,CalendarDate
															order by CalendarDate asc)
			from [dbo].[PurchaseAmount] 
			)p3
on p3.Customer = p1.Customer 
and p3.CalendarDate = p1.CalendarDate
and p3.Category = p1.Category

where p2.row_no  = 1
order by p1.Customer,p1.CalendarDate

/* Create row number */
select *, row_number() over (order by Customer, CalendarDate) as row_no into #temp2 from #temp1

/* Create cumsum */
select	
	CalendarDate,
	Customer,
	Category,
	Amount,
	PreviousPurchaseAmount, 
	NextPurchaseAmount,
	FirstPurchaseAmount,
	SumofCategoryAmount,

	sum([SumofCategoryAmount]) over (
									partition by Customer 
									order by row_no asc 
									rows between unbounded preceding and current row) as CumulativeValueofCategoryAmount
from #temp2
