SET NOCOUNT ON;
DBCC TRACEON (610) WITH NO_INFOMSGS		-- reduce write to log file


DECLARE @ddLastState NVARCHAR(48) = N''		-- save last state for Database
DECLARE @RowCount INT = 1
DECLARE @RowChunk INT = 10000			-- how many rows will be delete from table per batch
DECLARE @dbname NVARCHAR(256) = N''		-- name Database 
DECLARE @sql NVARCHAR(MAX) = N''
SELECT @ddLastState = delayed_durability_desc FROM sys.databases (NOLOCK) WHERE database_id > 4 AND @dbname = name

-- set DELAYED_DURABILITY = ALLOWED for our DB
IF @ddLastState != 'ALLOWED'
BEGIN 
	SELECT @sql = 'ALTER DATABASE ' + @dbname +' SET DELAYED_DURABILITY = ALLOWED'
	EXEC (@sql)
END 


-- delete rows from table StockLoanMarket
WHILE @Rowcount > 0
BEGIN
	BEGIN TRANSACTION del
		DELETE TOP (@RowChunk) FROM dbo.StockLoanMarket WITH (TABLOCK)
		SET @Rowcount = @@ROWCOUNT
	COMMIT TRAN del WITH(DELAYED_DURABILITY = ON)
	WAITFOR DELAY '00:00:03' -- pause 3 sec
END


-- return last state for DB
IF (SELECT delayed_durability_desc FROM sys.databases (NOLOCK) WHERE database_id > 4 AND @dbname = name) != @ddLastState
BEGIN 
	SELECT @sql = 'ALTER DATABASE ' + @dbname +' SET DELAYED_DURABILITY = ' + @ddLastState
	EXEC (@sql)
END 

