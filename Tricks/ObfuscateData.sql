IF EXISTS (SELECT TOP (1) 1 FROM sys.sysobjects (NOLOCK) WHERE name = 'GetHash' AND xtype IN ('FN'))
   DROP FUNCTION GetHash
GO

CREATE FUNCTION GetHash(@Value NVARCHAR(MAX) = NULL)
RETURNS BIGINT 
AS
BEGIN
        RETURN (CAST(HASHBYTES('SHA2_256',CAST(@Value AS NVARCHAR(256))) AS BIGINT))
END
GO


IF EXISTS (SELECT TOP (1) 1 FROM sys.sysobjects (NOLOCK) WHERE name = 'ObfuscateData' AND xtype IN ('P'))
   DROP PROC ObfuscateData
GO

CREATE PROCEDURE ObfuscateData 
(
	@SchemaName NVARCHAR(128) = NULL
	,@TblName NVARCHAR(256) = NULL
	,@MessageOutput BIT = 0
)
AS 
BEGIN

SET NOCOUNT ON;
SET XACT_ABORT ON;

IF @SchemaName IS NULL OR @TblName IS NULL RETURN;

DECLARE @i INT =
        (
            SELECT COUNT(c.column_id)
            FROM sys.objects o
                JOIN sys.columns c
                    ON c.object_id = o.object_id
            WHERE o.[type] IN ( N'U' )
                  AND o.name = @TblName
                  AND SCHEMA_NAME(o.schema_id) = @SchemaName
        );
DECLARE @sql NVARCHAR(MAX) = 'SELECT ';

WITH gdpr
AS (SELECT IT.major_id,
           IT.minor_id,
           IT.information_type,
           L.sensitivity_label
    FROM
    (
        SELECT major_id,
               minor_id,
               value AS information_type
        FROM sys.extended_properties
        WHERE name = 'sys_information_type_name'
    ) IT
        FULL OUTER JOIN
        (
            SELECT major_id,
                   minor_id,
                   value AS sensitivity_label
            FROM sys.extended_properties
            WHERE name = 'sys_sensitivity_label_name'
        ) L
            ON IT.major_id = L.major_id
               AND IT.minor_id = L.minor_id)
SELECT @sql
    = @sql
      + CASE
            WHEN gdpr.sensitivity_label IS NULL THEN
                i.COLUMN_NAME
            ELSE
                'dbo.GetHash(' + i.COLUMN_NAME + ') AS ['
                + i.COLUMN_NAME + ']'
        END + IIF(c.column_id < @i, ',', ' FROM [' + i.TABLE_SCHEMA + '].[' + i.TABLE_NAME + '] WITH (NOLOCK)')
FROM INFORMATION_SCHEMA.COLUMNS AS i
    JOIN sys.objects AS o
        ON o.[name] = i.TABLE_NAME
           AND SCHEMA_NAME(o.schema_id) = i.TABLE_SCHEMA
    JOIN sys.columns c
        ON c.object_id = o.object_id
           AND i.ORDINAL_POSITION = c.column_id
    LEFT JOIN gdpr
        ON gdpr.major_id = o.object_id
           AND gdpr.major_id = c.object_id
           AND gdpr.minor_id = c.column_id
WHERE o.[type] IN ( N'U' )
      AND i.TABLE_NAME = @TblName
      AND i.TABLE_SCHEMA = @SchemaName;

IF @MessageOutput = 1 PRINT @sql;


END;

GO


EXEC sys.sp_MSforeachtable @command1 = 
'
DECLARE @SchemaName NVARCHAR(128) = NULL
	   ,@TblName NVARCHAR(256) = NULL
SELECT 
 @SchemaName = s.name
,@TblName= o.name 
from sys.objects as o (NOLOCK)
JOIN sys.schemas as s (NOLOCK)
ON o.schema_id = s.schema_id
WHERE o.name NOT IN (''sysdiagrams'')
AND o.type = ''U''
AND o.object_id =  object_id(''?'')

EXEC [dbo].[ObfuscateData] @SchemaName = @SchemaName, @TblName = @TblName, @MessageOutput =1
';