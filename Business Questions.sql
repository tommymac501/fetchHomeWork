



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

declare @maxMonth INT, @maxYear INT

select 
    @maxyear = datepart(year, cast(max(r.datescanned) as date)),
    @maxmonth = datepart(month, cast(max(r.datescanned) as date))
from Receipts r 

;with currentBrandsales as (
    select 
        b.name as brand,
        datepart(month, r.datescanned) as monthsold,
        count(*) as scan_count
    from  Receipts r 
    left join Brands b
    on 
        r.barcode = b.barcode
    where 
        isnull(r.barcode, '') <> ''
        and datepart(year, r.datescanned) = @maxyear
        and datepart(month, r.datescanned) = @maxmonth
    group by 
        b.name, datepart(month, r.datescanned)
)
select top (5) 
    brand,
    monthsold,
    scan_count
from currentBrandsales
order by scan_count desc

--*** Without proper brand data, this query only returns scans, not brands.



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


	
	






