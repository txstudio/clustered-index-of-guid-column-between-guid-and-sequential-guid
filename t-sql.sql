/*
DROP TABLE [Sales].[SalesOrderDetail_Guid]
GO
DROP TABLE [Sales].[SalesOrderDetail_SequentialGuid]
GO
*/

--建立 GUID 與 NEWSEQUENTIALID 資料型態做 CLUSTERED INDEX 的範例資料表
--	使用 Sales.SalesOrderDetail 資料表的內容
CREATE TABLE [Sales].[SalesOrderDetail_Guid]
(
	[Id] [uniqueidentifier] NOT NULL DEFAULT NEWID(),
	[SalesOrderID] [int] NOT NULL,
	[SalesOrderDetailID] [int] NOT NULL,
	[CarrierTrackingNumber] [nvarchar](25) NULL,
	[OrderQty] [smallint] NOT NULL,
	[ProductID] [int] NOT NULL,
	[SpecialOfferID] [int] NOT NULL,
	[UnitPrice] [money] NOT NULL,
	[UnitPriceDiscount] [money] NOT NULL,
	[LineTotal]  AS (isnull(([UnitPrice]*((1.0)-[UnitPriceDiscount]))*[OrderQty],(0.0))),
	[rowguid] [uniqueidentifier] ROWGUIDCOL NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,

	CONSTRAINT [PK_SalesOrderDetail_Guid] PRIMARY KEY CLUSTERED 
	(
		[Id] ASC
	)
)
GO

CREATE NONCLUSTERED INDEX [IX_SalesOrderDetail_Guid_rowguid]
	ON [Sales].[SalesOrderDetail_Guid]([rowguid])
GO

CREATE TABLE [Sales].[SalesOrderDetail_SequentialGuid]
(
	[Id] [uniqueidentifier] NOT NULL DEFAULT NEWSEQUENTIALID(),
	[SalesOrderID] [int] NOT NULL,
	[SalesOrderDetailID] [int] NOT NULL,
	[CarrierTrackingNumber] [nvarchar](25) NULL,
	[OrderQty] [smallint] NOT NULL,
	[ProductID] [int] NOT NULL,
	[SpecialOfferID] [int] NOT NULL,
	[UnitPrice] [money] NOT NULL,
	[UnitPriceDiscount] [money] NOT NULL,
	[LineTotal]  AS (isnull(([UnitPrice]*((1.0)-[UnitPriceDiscount]))*[OrderQty],(0.0))),
	[rowguid] [uniqueidentifier] ROWGUIDCOL NOT NULL,
	[ModifiedDate] [datetime] NOT NULL,

	CONSTRAINT [PK_SalesOrderDetail_SequentialGuid] PRIMARY KEY CLUSTERED 
	(
		[Id] ASC
	)
)
GO

CREATE NONCLUSTERED INDEX [IX_SalesOrderDetail_SequentialGuid_rowguid]
	ON [Sales].[SalesOrderDetail_SequentialGuid]([rowguid])
GO

--匯入 Sales.SalesOrderDetail 資料型態
--	第一次匯入索引片段情況可能不明顯，可再多匯幾次

--Cost: 55%
INSERT INTO [Sales].[SalesOrderDetail_Guid] (
	[SalesOrderID]
	,[SalesOrderDetailID]
	,[CarrierTrackingNumber]
	,[OrderQty]
	,[ProductID]
	,[SpecialOfferID]
	,[UnitPrice]
	,[UnitPriceDiscount]
	,[rowguid]
	,[ModifiedDate]
)
SELECT [SalesOrderID]
	,[SalesOrderDetailID]
	,[CarrierTrackingNumber]
	,[OrderQty]
	,[ProductID]
	,[SpecialOfferID]
	,[UnitPrice]
	,[UnitPriceDiscount]
	,[rowguid]
	,[ModifiedDate]
FROM [Sales].[SalesOrderDetail] with (nolock)
GO

--Cost: 45%
INSERT INTO [Sales].[SalesOrderDetail_SequentialGuid] (
	[SalesOrderID]
	,[SalesOrderDetailID]
	,[CarrierTrackingNumber]
	,[OrderQty]
	,[ProductID]
	,[SpecialOfferID]
	,[UnitPrice]
	,[UnitPriceDiscount]
	,[rowguid]
	,[ModifiedDate]
)
SELECT [SalesOrderID]
	,[SalesOrderDetailID]
	,[CarrierTrackingNumber]
	,[OrderQty]
	,[ProductID]
	,[SpecialOfferID]
	,[UnitPrice]
	,[UnitPriceDiscount]
	,[rowguid]
	,[ModifiedDate]
FROM [Sales].[SalesOrderDetail] with (nolock)
GO

--檢視索引的片段狀態
SELECT [object_id]
	, [TableName]
	, [index_id]
	, [IndedxName]
	, [avg_fragmentation_in_percent]
FROM
(
	SELECT a.object_id, object_name(a.object_id) AS TableName,
		a.index_id, name AS IndedxName, avg_fragmentation_in_percent
	FROM sys.dm_db_index_physical_stats
		(DB_ID (N'AdventureWorks2019')
			, OBJECT_ID(N'Sales.SalesOrderDetail_Guid')
			, NULL
			, NULL
			, NULL) AS a
	INNER JOIN sys.indexes AS b
		ON a.object_id = b.object_id
		AND a.index_id = b.index_id
	UNION
	SELECT a.object_id, object_name(a.object_id) AS TableName,
		a.index_id, name AS IndedxName, avg_fragmentation_in_percent
	FROM sys.dm_db_index_physical_stats
		(DB_ID (N'AdventureWorks2019')
			, OBJECT_ID(N'Sales.SalesOrderDetail_SequentialGuid')
			, NULL
			, NULL
			, NULL) AS a
	INNER JOIN sys.indexes AS b
		ON a.object_id = b.object_id
		AND a.index_id = b.index_id
) [index_status]
GO

--確認要做修改的內容
SELECT TOP (100) * FROM [Sales].[SalesOrderDetail_Guid] with (nolock)
WHERE [rowguid] = 'D7D80842-DC4C-4204-A133-C44A28A575FB'

SELECT TOP (100) * FROM [Sales].[SalesOrderDetail_SequentialGuid] with (nolock)
WHERE [rowguid] = 'D7D80842-DC4C-4204-A133-C44A28A575FB'

--UPDATE TEST
--	Execution Plan
--Cost 30 %
UPDATE [Sales].[SalesOrderDetail_Guid]
	SET [UnitPrice] = [UnitPrice] + 100
GO

--Cost 30 %
UPDATE [Sales].[SalesOrderDetail_Guid]
	SET [UnitPrice] = [UnitPrice] - 100
GO

--Cost 20 %
UPDATE [Sales].[SalesOrderDetail_SequentialGuid]
	SET [UnitPrice] = [UnitPrice] + 100
GO

--Cost 20 %
UPDATE [Sales].[SalesOrderDetail_SequentialGuid]
	SET [UnitPrice] = [UnitPrice] - 100
GO