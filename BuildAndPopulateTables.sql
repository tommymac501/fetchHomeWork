use TestingDB
go


-- Create tables for the Brands
DROP TABLE IF EXISTS dbo.Brands 
CREATE TABLE Brands(
    brandID VARCHAR(24) PRIMARY KEY,
    barcode VARCHAR(12),
    brandCode VARCHAR(255),
    name VARCHAR(255),
    topBrand bit,
    category VARCHAR(50),
    categoryCode VARCHAR(50),
    receiptCode VARCHAR(50)
);

DROP TABLE IF EXISTS dbo.BrandCategories
CREATE TABLE BrandCategories (
	brandID varchar(24),
    categoryCode VARCHAR(50),
    barcode VARCHAR(12)
)

DROP TABLE IF EXISTS dbo.BrandCPGs
CREATE TABLE BrandCPGs (
	brandID varchar(24),
	cpgID varchar(24),
	barcode varchar(24),
	ref varchar(24)
)

-- Create User table
DROP TABLE IF EXISTS dbo.Users
CREATE TABLE Users (
    userID VARCHAR(24) PRIMARY KEY,
    active BIT,
    createdDate DATETIME,
    lastLogin DATETIME,
    role VARCHAR(50),
    signUpSource VARCHAR(50),
    state VARCHAR(2)
);

-- Create Receipts tables
DROP TABLE IF EXISTS dbo.Receipts
CREATE TABLE Receipts (
    ReceiptID VARCHAR(24),
    barcode VARCHAR(25),
    createDate DATETIME,
    dateScanned DATETIME,
    finishedDate DATETIME,
    modifyDate DATETIME,
    purchaseDate DATETIME,
    purchasedItemCount INT,
    rewardsReceiptStatus VARCHAR(50),
    totalSpent DECIMAL(10,2),
    userId VARCHAR(24)

);

DROP TABLE IF EXISTS dbo.PointsAwards
CREATE TABLE PointsAwards (
    ReceiptID VARCHAR(24) PRIMARY KEY,
    pointsAwardedDate DATETIME,
    pointsEarned DECIMAL(10,1),
    bonusPointsEarned INT,
    bonusPointsEarnedReason TEXT

);

DROP TABLE IF EXISTS dbo.RewardsReceiptItems
CREATE TABLE RewardsReceiptItems (
    itemID INT IDENTITY PRIMARY KEY,
    ReceiptID VARCHAR(24),
    barcode VARCHAR(25),
    description TEXT,
    finalPrice DECIMAL(10,2),
    itemPrice DECIMAL(10,2),
    partnerItemId VARCHAR(50),
    quantityPurchased INT

);

DROP TABLE IF EXISTS dbo.RewardsGroups
CREATE TABLE RewardsGroups (
    rewardGroupID VARCHAR(24),
    rewardName VARCHAR(255),
    rewardPartnerID varchar(40)
);

DROP TABLE IF EXISTS dbo.ItemRewards
CREATE TABLE ItemRewards (
    itemID INT,
    rewardGroupID VARCHAR(24),
    rewardProdPartnerID VARCHAR(24),
    pointsEarned DECIMAL(10,1),
    targetPrice DECIMAL(10,2)
);

DROP TABLE IF EXISTS dbo.fetchTransactions
CREATE TABLE fetchTransactions (
	ReceiptID varchar(40),
	userID varchar(40),
	barcode varchar(40),
	needsFetchReview bit,
	preventTargetGapPoints bit,
	userFlaggedNewItem bit
)


CREATE TABLE Transactions(
	userID varchar(40),
	receiptID varchar (40),
	brandID varchar(40),
	receiptCreatedDate datetime
)

-- Load a working table with the JSON Data
DROP TABLE IF EXISTS #RAWJSON
CREATE TABLE #RAWJSON (
	sourcefile varchar(15),
    recordkey int,
    jsoncolumn nvarchar(max),
    recordtype int
)

-- Declare a variable to hold the JSON data
DECLARE @json_u NVARCHAR(MAX)



-- Load the JSON data from the file using OPENROWSET (BULK)
SELECT @json_u = BulkColumn
FROM OPENROWSET (BULK 'C:\Job application tests\Fetch\users\users.json', SINGLE_CLOB) AS data;

-- Insert the data into a temp table to be able to convert the JSON data
insert into #RawJSON(sourceFile, recordKey, JSONColumn, recordType)
select 'Users', [key], value, type
from openjson(@json_u)

DECLARE @json_b NVARCHAR(MAX)
SELECT @json_b = BulkColumn
FROM OPENROWSET (BULK 'C:\Job application tests\Fetch\Brands\Brands.json', SINGLE_CLOB) AS data;

-- Insert the data into a temp table to be able to convert the JSON data
insert into #RawJSON(sourceFile, recordKey, JSONColumn, recordType)
select 'Brands', [key], value, type
from openjson(@json_b)

DECLARE @json_r NVARCHAR(MAX)
SELECT @json_r = BulkColumn
FROM OPENROWSET (BULK 'C:\Job application tests\Fetch\Receipts\Receipts.json', SINGLE_CLOB) AS data;

-- Insert the data into a temp table to be able to convert the JSON data
insert into #RawJSON(sourceFile, recordKey, JSONColumn, recordType)
select 'Receipts', [key], value, type
from openjson(@json_r)



-- Populate Users
insert into dbo.Users(userID, active, createdDate, lastLogin, role, signUpSource, state)
select distinct
	JSON_VALUE(jsoncolumn,'$._id."$oid"') as userID,
	JSON_VALUE(jsoncolumn,'$.active') as isActive,
    DATEADD(SECOND,(convert(bigint,JSON_VALUE(jsoncolumn, '$.createdDate."$date"'))/1000) , DATEADD(MILLISECOND, 800, '1970-01-01')) AS createdDate,
    DATEADD(SECOND,(convert(bigint,JSON_VALUE(jsoncolumn, '$.lastLogin."$date"'))/1000) , DATEADD(MILLISECOND, 800, '1970-01-01')) AS createdDate,
	JSON_VALUE(jsoncolumn,'$.role') as role,
	JSON_VALUE(jsoncolumn,'$.signUpSource') as signUpSource,
	JSON_VALUE(jsoncolumn,'$.state') as state
from #RawJSON
where sourceFile = 'Users'
	

-- Populate Brands Tables
INSERT INTO Brands(brandID, barcode, brandCode, name, topBrand, category, categoryCode, receiptCode)
SELECT 
	JSON_VALUE(jsoncolumn,'$._id."$oid"') as brandID,
	JSON_VALUE(jsoncolumn,'$.barcode') as barcode,	
	JSON_VALUE(jsoncolumn,'$.brandCode') as brandCode,	
	JSON_VALUE(jsoncolumn,'$.name') as name,	
	JSON_VALUE(jsoncolumn,'$.topreceipt') as topBrand,
	JSON_VALUE(jsoncolumn,'$.category') as category,	
	JSON_VALUE(jsoncolumn,'$.categoryCode') as categoryCode,
	JSON_VALUE(jsoncolumn,'$.receiptCode') as receiptCode
from #RawJSON
where sourceFile = 'Brands'

INSERT INTO BrandCategories(brandID, barcode, categoryCode)
SELECT 
	JSON_VALUE(jsoncolumn,'$._id."$oid"') as brandID,
	JSON_VALUE(jsoncolumn,'$.barcode') as barcode,
	JSON_VALUE(jsoncolumn,'$.categoryCode') as categoryCode
from #RawJSON
where sourceFile = 'Brands'


INSERT INTO brandCPGs(brandID, cpgID, barcode, [ref])
SELECT 	
	JSON_VALUE(jsoncolumn,'$._id."$oid"') as brandID,
	JSON_VALUE(jsoncolumn,'$.cpg."$id"."$oid"') as cpgID,
	JSON_VALUE(jsoncolumn,'$.barcode') as barcode,	
	JSON_VALUE(jsoncolumn, '$.cpg."$ref"') as ref
from #RawJSON
where sourceFile = 'Brands'	

-- Populate Reciepts
INSERT INTO Receipts(ReceiptID,barcode,createDate,dateScanned,finishedDate,modifyDate,purchaseDate,purchasedItemCount,rewardsReceiptStatus,totalSpent,userId)
SELECT 
	JSON_VALUE(jsoncolumn,'$._id."$oid"') as ReceiptID,
	JSON_VALUE(item.value,'$.barcode') as barcode,
    DATEADD(SECOND,(convert(bigint,JSON_VALUE(jsoncolumn, '$.createDate."$date"'))/1000) , DATEADD(MILLISECOND, 800, '1970-01-01')) AS createdDate,	
    DATEADD(SECOND,(convert(bigint,JSON_VALUE(jsoncolumn, '$.dateScanned."$date"'))/1000) , DATEADD(MILLISECOND, 800, '1970-01-01')) AS dateScanned,	
    DATEADD(SECOND,(convert(bigint,JSON_VALUE(jsoncolumn, '$.finishedDate."$date"'))/1000) , DATEADD(MILLISECOND, 800, '1970-01-01')) AS finishedDate,	
    DATEADD(SECOND,(convert(bigint,JSON_VALUE(jsoncolumn, '$.modifyDate."$date"'))/1000) , DATEADD(MILLISECOND, 800, '1970-01-01')) AS modifyDate,	
    DATEADD(SECOND,(convert(bigint,JSON_VALUE(jsoncolumn, '$.purchaseDate."$date"'))/1000) , DATEADD(MILLISECOND, 800, '1970-01-01')) AS purchaseDate,	
	JSON_VALUE(jsoncolumn,'$.purchasedItemCount') as purchasedItemCount,
	JSON_VALUE(jsoncolumn,'$.rewardsReceiptStatus') as rewardsReceiptStatus,
	JSON_VALUE(jsoncolumn,'$.totalSpent') as totalSpent,	
	JSON_VALUE(jsoncolumn,'$.userId') as userId
from #RawJSON
CROSS APPLY OPENJSON(JSON_QUERY(jsoncolumn, '$.rewardsReceiptItemList')) AS item
where sourceFile = 'Receipts'


SELECT 
	JSON_VALUE(jsoncolumn,'$._id."$oid"') as ReceiptID
from #RawJSON

INSERT INTO PointsAwards(ReceiptID,pointsAwardedDate,pointsEarned,bonusPointsEarned,bonusPointsEarnedReason)
SELECT
	JSON_VALUE(jsoncolumn,'$._id."$oid"') as ReceiptID,
    DATEADD(SECOND,(convert(bigint,JSON_VALUE(jsoncolumn, '$.pointsAwardedDate."$date"'))/1000) , DATEADD(MILLISECOND, 800, '1970-01-01')) AS pointsAwardedDate,		
	JSON_VALUE(jsoncolumn,'$.pointsEarned') as pointsEarned,	
	JSON_VALUE(jsoncolumn,'$.bonusPointsEarned') as bonusPointsEarned,	
	JSON_VALUE(jsoncolumn,'$.bonusPointsEarnedReason') as bonusPointsEarnedReason
from #RawJSON
where sourceFile = 'Receipts'		
	
INSERT INTO RewardsReceiptItems(ReceiptID,barcode,description,finalPrice,itemPrice,partnerItemId,quantityPurchased)
SELECT 
	JSON_VALUE(jsoncolumn,'$._id."$oid"') as ReceiptID,
	JSON_VALUE(item.value, '$.barcode') as barcode,	
	JSON_VALUE(item.value, '$.description') as description,	
	JSON_VALUE(item.value, '$.finalPrice') as finalPrice,	
	JSON_VALUE(item.value, '$.itemPrice') as itemPrice,	
	JSON_VALUE(item.value, '$.partnerItemId') as partnerItemId,	
	JSON_VALUE(item.value, '$.quantityPurchased') as quantityPurchased
from #RawJSON
CROSS APPLY OPENJSON(JSON_QUERY(jsoncolumn, '$.rewardsReceiptItemList')) AS item
where sourceFile = 'Receipts'		

-- a Barcode for a product is uniuqe at it relates to the reward
INSERT INTO RewardsGroups(rewardGroupID,rewardName, rewardPartnerID )
SELECT 
	JSON_VALUE(item.value, '$.barcode') as rewardGroupID,	
	JSON_VALUE(item.value, '$.rewardsGroup') as rewardName,
	JSON_VALUE(item.value, '$.rewardsProductPartnerId') as rewardPartnerID
from #RawJSON
CROSS APPLY OPENJSON(JSON_QUERY(jsoncolumn, '$.rewardsReceiptItemList')) AS item
where sourceFile = 'Receipts'	

INSERT INTO ItemRewards (rewardGroupID, rewardProdPartnerID, pointsEarned, targetPrice)
SELECT 
	JSON_VALUE(item.value, '$.barcode') as rewardGroupID,
	JSON_VALUE(item.value, '$.rewardsProductPartnerId') as rewardPartnerID,
	JSON_VALUE(item.value, '$.pointsEarned') as pointsEarned,
	JSON_VALUE(item.value, '$.targetPrice') as targetPrice
from #RawJSON
CROSS APPLY OPENJSON(JSON_QUERY(jsoncolumn, '$.rewardsReceiptItemList')) AS item
where sourceFile = 'Receipts'	

INSERT INTO fetchTransactions(ReceiptID, userID, barcode,needsFetchReview, preventTargetGapPoints, userFlaggedNewItem)
SELECT
	JSON_VALUE(jsoncolumn,'$._id."$oid"') as ReceiptID,
	JSON_VALUE(jsoncolumn,'$.userId') as userId,
	JSON_VALUE(item.value,'$.barcode') as barcode,	
	JSON_VALUE(item.value,'$.needsFetchReview') as needsFetchReview,	
	JSON_VALUE(item.value,'$.preventTargetGapPoints') as preventTargetGapPoints,	
	JSON_VALUE(item.value,'$.userFlaggedNewItem') as userFlaggedNewItem
from #RawJSON
CROSS APPLY OPENJSON(JSON_QUERY(jsoncolumn, '$.rewardsReceiptItemList')) AS item
where sourceFile = 'Receipts'	


SELECT *
FROM Users u 
left join Receipts r 
on u.userID = r.userId 
join Brands b 
on b.brandID = u


CREATE TABLE Transactions(
	userID varchar(40),
	receiptID varchar (40),
	brandID varchar(40),
	receiptCreatedDate datetime
)

--select * from #rawjson where sourcefile = 'Receipts'

/*



select * from #rawjson where sourcefile = 'Receipts'
select * from #rawjson where jsoncolumn like '%5887a372e4b02187f85cdad9%'
select count(distinct barcode)  from brands where brandid = '5887a372e4b02187f85cdad9'*/






