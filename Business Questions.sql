



/* Create some views to make answering the questions easier  */

create view userReciepts (
userID,
ReceiptID,
barcode,
createDate,
dateScanned,
finishedDate,
modifyDate,
purchaseDate,
purchasedItemCount,
rewardsReceiptStatus,
totalSpent
)
as
select
	u.userID,
	r.ReceiptID,
	r.barcode,
	r.createDate,
	r.dateScanned,
	r.finishedDate,
	r.modifyDate,
	r.purchaseDate,
	r.purchasedItemCount,
	r.rewardsReceiptStatus,
	r.totalSpent
from
	Users u
left join Receipts r 
on
	u.userID = r.userId
	-- All user reciepts

SELECT * FROM  userReciepts


create view recieptBrands (
ReceiptID ,
brandID,
barcode,
brandCode,
name,
topBrand,
category,
categoryCode,
receiptCode 
)
as
SELECT
	r.ReceiptID ,
	b.brandID,
	b.barcode,
	b.brandCode,
	b.name,
	b.topBrand,
	b.category,
	b.categoryCode,
	b.receiptCode
from
	Receipts r
left join Brands b 
on
	r.barcode = b.barcode





/*  What are the top 5 brands by receipts scanned for most recent month?  */
declare @maxMonth int, @previousMonth int -- THis is not a current data set, so the "past 6 months" wont produce any data. We need to go back in time to get that

select @maxMonth = (select datepart(month,cast(max(datescanned) as date)) from receipts) -- get the most recent month
select @previousMonth = @maxMonth - 1

;with currentBrandSales (Brand, monthSold)
as (
	select b.name as Brand, datepart(month,r.dateScanned) as monthSold
	from receipts r
	left join Brands b
		on r.barcode = b.barcode
	where isnull(r.barcode,'') <> '' 
	and datepart(month,r.dateScanned) = @maxMonth
)
select top (5) Brand, monthSold
from currentBrandSales
order by Brand



/*   How does the ranking of the top 5 brands by receipts scanned for the recent month compare to the ranking for the previous month?   */
declare @maxMonth int, @previousMonth int -- THis is not a current data set, so the "past 6 months" wont produce any data. We need to go back in time to get that

select @maxMonth = (select datepart(month,cast(max(datescanned) as date)) from receipts) -- get the most recent month
select @previousMonth = @maxMonth - 1

;with currentBrandSales (Brand, monthSold, RecordCount)
as (
	select b.name as Brand, datepart(month,r.dateScanned) as monthSold, count(*) as RecordCount
	from receipts r
	left join Brands b
		on r.barcode = b.barcode
	where isnull(name,'') <> '' 
	and datepart(month,r.dateScanned) = @maxMonth
	group by b.name, datepart(month,r.dateScanned)
),
previousBrandSales (Brand, monthSold, RecordCount)
as(
	select b.name as Brand, datepart(month,r.dateScanned) as monthSold, count(*) as RecordCount
	from receipts r
	left join Brands b
		on r.barcode = b.barcode
	where isnull(name,'') <> '' 
	and datepart(month,r.dateScanned) = @maxMonth
	group by b.name, datepart(month,r.dateScanned)
)
select Brand, monthSold, RecordCount
from currentBrandSales



/*   When considering average spend from receipts with 'rewardsReceiptStatus’ of ‘Accepted’ or ‘Rejected’, which is greater?   */
with avgAcceptedSpend (program, average, records)
as
(	
select
	rewardsReceiptStatus,
	avg(r.totalSpent) as avgSpent,
	count(*) as records
from
	Receipts r
group by
	rewardsReceiptStatus
	)
select top(1) 
	case program
		when 'FINISHED' then 'Accepted'
		when 'REJECTED' then 'Rejected'
		end as program,
		format(average,'C') as amount
from avgAcceptedSpend
where program in ('FINISHED','REJECTED')
order by average DESC 


/*   When considering total number of items purchased from receipts with 'rewardsReceiptStatus’ of ‘Accepted’ or ‘Rejected’, which is greater?   */
with totalItems (program, purchasedItemCount, records)
as
(	
select
	rewardsReceiptStatus,
	sum(purchasedItemCount) as purchasedItemCount,
	count(*) as recordspurchasedItemCount
from
	Receipts r
group by
	rewardsReceiptStatus
	)
select top(1) 
	case program
		when 'FINISHED' then 'Accepted'
		when 'REJECTED' then 'Rejected'
		end as program,
		purchasedItemCount
from totalItems
where program in ('FINISHED','REJECTED')
order by purchasedItemCount DESC 

/*   Which brand has the most spend among users who were created within the past 6 months?  */

declare @maxCeatedDate date 
select @maxCeatedDate = (select max(createdDate) from users) 


;with userList (userID, createddate)
as (
	select u.userID, u.createdDate
	from users u
	where createddate > dateadd(month,-6, @maxCeatedDate) and role = 'consumer' and u.active = 1
)
SELECT top (1) b.name, format(sum(r.totalSpent),'C') as spend
FROM userList ul
left join receipts r
	on ul.userID = r.userID
left join Brands b
	on r.barcode = b.barcode
	where isnull(name,'') <> ''
group by ul.userID, b.name
order by sum(r.totalSpent) DESC 

/*   Which brand has the most transactions among users who were created within the past 6 months?   */
declare @maxCeatedDate date 

select @maxCeatedDate = (select max(createdDate) from users) 


;with userList (userID, createddate)
as (
	select u.userID, u.createdDate
	from users u
	where createddate > dateadd(month,-6, @maxCeatedDate) and role = 'consumer' and u.active = 1
)
SELECT top (1) b.name, count(cast(r.purchaseDate as date))
FROM userList ul
left join receipts r
	on ul.userID = r.userID
left join Brands b
	on r.barcode = b.barcode
	where isnull(name,'') <> ''
group by ul.userID, b.name
order by count(cast(r.purchaseDate as date)) DESC 


	
	






