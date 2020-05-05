

CREATE PROCEDURE [dbo].[GetTableSizeForAllTablesInEachDb] (@DbName VARCHAR(250) = NULL)
AS
BEGIN 

SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#spaceused') IS NOT NULL
    DROP TABLE #spaceused;

CREATE TABLE #spaceused
([DbName]     SYSNAME DEFAULT('') NOT NULL,
 [tblName]    SYSNAME NOT NULL,
 [Row_count]  INT NOT NULL,
 [Reserved]   VARCHAR(50) NOT NULL,
 [data]       VARCHAR(50) NOT NULL,
 [index_size] VARCHAR(50) NOT NULL,
 [unused]     VARCHAR(50) NOT NULL,
 [Date_time]   DATETIME2 NOT NULL DEFAULT ('1900-01-01 00:00:00.000')
);
DECLARE @Cmd VARCHAR(8000);
SET @Cmd = 'USE ['+ CAST(ISNULL(@DbName,'?') AS VARCHAR(250))+']; 

IF ''?'' NOT IN (''tempdb'',''master'',''model'',''msdb'')
BEGIN

DECLARE @InnerCmd VARCHAR(8000)
SET @InnerCmd = ''
   EXEC sp_spaceused '''''' + CHAR(63) + ''''''''
   
   INSERT INTO #spaceused(tblName, Row_count,Reserved,data,index_size,unused) 
   EXEC sp_MSforeachtable @InnerCmd
   
   UPDATE #spaceused SET DbName = ''?'' WHERE DbName = ''''
END';

EXEC sp_MSforeachdb @Cmd;

SELECT DbName,
       tblName,
       Row_count,
       CONVERT(BIGINT, REPLACE(Reserved, ' KB', ''))/1024 AS MB_Reserved,
       CONVERT(BIGINT, REPLACE(data, ' KB', ''))/1024 AS MB_data,
       CONVERT(BIGINT, REPLACE(index_size, ' KB', ''))/1024 AS MB_index_size,
       CONVERT(BIGINT, REPLACE(unused, ' KB', ''))/1024 AS MB_unused,
	  CASE WHEN Date_time = '1900-01-01 00:00:00.000' THEN GETDATE() ELSE Date_time END AS Date_time
FROM #spaceused
WHERE Row_count > 0
AND DbName = ISNULL(@DbName,DbName)
ORDER BY DbName,
         MB_Reserved DESC,
         Row_count DESC;


END 

