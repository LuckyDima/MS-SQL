
USE [BLT_Logging]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

SET XACT_ABORT ON;
BEGIN TRAN 

DECLARE @OldTblName NVARCHAR(256) = N'CyclicRequestLog'
DECLARE @NewTblName NVARCHAR(256) = @OldTblName + N'_old'
DECLARE @OldName NVARCHAR(256)
DECLARE @NewName NVARCHAR(256)
DECLARE @object_name SYSNAME
DECLARE @object_id INT
DECLARE @SetIdentity BIGINT = (SELECT IDENT_CURRENT( @OldTblName ))

IF OBJECT_ID('tempdb..#indexes') IS NOT NULL
	DROP TABLE #indexes;
IF OBJECT_ID('tempdb..#CreateIndexes') IS NOT NULL
	DROP TABLE #CreateIndexes;
IF OBJECT_ID('tempdb..#Changes') IS NOT NULL
	DROP TABLE #Changes;

CREATE TABLE #Changes 
(
ColumnName NVARCHAR(256),
ColumnType NVARCHAR(64)
);


CREATE TABLE #indexes
(
    index_name NVARCHAR(256),
    index_description NVARCHAR(256),
    index_keys NVARCHAR(256),
    id INT IDENTITY
);

CREATE TABLE #CreateIndexes
(
    index_script NVARCHAR(MAX),
    id INT IDENTITY
);

/*Insert change for column start*/

INSERT INTO #Changes
(
    ColumnName,
    ColumnType
)
VALUES
(   N'CyclicRequestLogID', 
    N'BIGINT'  
)

/*Insert change for column end*/

SELECT 
      @object_name = '[' + s.name + '].[' + o.name + ']'
    , @object_id = o.[object_id]
FROM sys.objects o WITH (NOWAIT)
JOIN sys.schemas s WITH (NOWAIT) ON o.[schema_id] = s.[schema_id]
WHERE s.name + '.' + o.name = s.name + '.' + @OldTblName
    AND o.[type] = 'U'
    AND o.is_ms_shipped = 0

DECLARE @SQL NVARCHAR(MAX) = ''

;WITH index_column AS 
(
    SELECT 
          ic.[object_id]
        , ic.index_id
        , ic.is_descending_key
        , ic.is_included_column
        , c.name
    FROM sys.index_columns ic WITH (NOWAIT)
    JOIN sys.columns c WITH (NOWAIT) ON ic.[object_id] = c.[object_id] AND ic.column_id = c.column_id
    WHERE ic.[object_id] = @object_id
)
SELECT @SQL = 'CREATE TABLE ' + @object_name + CHAR(13) + '(' + CHAR(13) + STUFF((
    SELECT CHAR(9) + ', [' + c.name + '] ' + 
        CASE WHEN c.is_computed = 1
            THEN 'AS ' + cc.[definition] 
            ELSE UPPER(
			CASE WHEN c.name = (SELECT TOP 1 ColumnName FROM #Changes WHERE c.name = ColumnName) 
			THEN (SELECT TOP 1 ColumnType  FROM #Changes WHERE c.name = ColumnName) 
			ELSE tp.name END) + 
                CASE WHEN tp.name IN ('varchar', 'char', 'varbinary', 'binary', 'text')
                       THEN '(' + CASE WHEN c.max_length = -1 THEN 'MAX' ELSE CAST(c.max_length AS VARCHAR(5)) END + ')'
                     WHEN tp.name IN ('nvarchar', 'nchar', 'ntext')
                       THEN '(' + CASE WHEN c.max_length = -1 THEN 'MAX' ELSE CAST(c.max_length / 2 AS VARCHAR(5)) END + ')'
                     WHEN tp.name IN ('datetime2', 'time2', 'datetimeoffset') 
                       THEN '(' + CAST(c.scale AS VARCHAR(5)) + ')'
                     WHEN tp.name = 'decimal' 
                       THEN '(' + CAST(c.[precision] AS VARCHAR(5)) + ',' + CAST(c.scale AS VARCHAR(5)) + ')'
                    ELSE ''
                END +
                CASE WHEN c.collation_name IS NOT NULL THEN ' COLLATE ' + c.collation_name ELSE '' END +
                CASE WHEN c.is_nullable = 1 THEN ' NULL' ELSE ' NOT NULL' END +
                CASE WHEN dc.[definition] IS NOT NULL THEN ' DEFAULT' + dc.[definition] ELSE '' END + 
                CASE WHEN ic.is_identity = 1 THEN ' IDENTITY(' + LTRIM(RTRIM(CAST(COALESCE(@SetIdentity+1,ic.seed_value, '0') AS CHAR(48)))) + ',' + CAST(ISNULL(ic.increment_value, '1') AS CHAR(1)) + ')' ELSE '' END 
        END + CHAR(13)
    FROM sys.columns c WITH (NOWAIT)
    JOIN sys.types tp WITH (NOWAIT) ON c.user_type_id = tp.user_type_id
    LEFT JOIN sys.computed_columns cc WITH (NOWAIT) ON c.[object_id] = cc.[object_id] AND c.column_id = cc.column_id
    LEFT JOIN sys.default_constraints dc WITH (NOWAIT) ON c.default_object_id != 0 AND c.[object_id] = dc.parent_object_id AND c.column_id = dc.parent_column_id
    LEFT JOIN sys.identity_columns ic WITH (NOWAIT) ON c.is_identity = 1 AND c.[object_id] = ic.[object_id] AND c.column_id = ic.column_id
    WHERE c.[object_id] = @object_id
    ORDER BY c.column_id
    FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, CHAR(9) + ' ')
    + ISNULL((SELECT CHAR(9) + ', CONSTRAINT [' + k.name + '] PRIMARY KEY (' + 
                    (SELECT STUFF((
                         SELECT ', [' + c.name + '] ' + CASE WHEN ic.is_descending_key = 1 THEN 'DESC' ELSE 'ASC' END
                         FROM sys.index_columns ic WITH (NOWAIT)
                         JOIN sys.columns c WITH (NOWAIT) ON c.[object_id] = ic.[object_id] AND c.column_id = ic.column_id
                         WHERE ic.is_included_column = 0
                             AND ic.[object_id] = k.parent_object_id 
                             AND ic.index_id = k.unique_index_id     
                         FOR XML PATH(N''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 2, ''))
            + ')' + CHAR(13)
            FROM sys.key_constraints k WITH (NOWAIT)
            WHERE k.parent_object_id = @object_id 
                AND k.[type] = 'PK'), '') + ')'  + CHAR(13)

;WITH IndexInfo AS (
SELECT ix.object_id
    , ix.NAME AS IndexName
    , ix.type_desc
    , ix.filter_definition
    , ix.is_unique
    , ix.is_primary_key
    , ix.allow_row_locks
    , ix.allow_page_locks
    , ds.NAME AS DataSpaceName
    , ds.type AS DataSpaceType
    , ix.is_padded
    , object_schema_name(ix.object_id) AS SchemaName
    , object_name(ix.object_id) AS TableName
    , IIF(ix.type <= 2, is_included_column, 0) AS HasIncludedColumn
    , IIF(ix.type in (5, 6), 1, 0) AS IsColumnStore
    , (
        SELECT KeyColumns
        FROM (
            SELECT IC2.object_id
                , IC2.index_id
                , STUFF((
                        SELECT ' , ' + C.NAME + IIF(MAX(CONVERT(INT, IC1.is_descending_key)) = 1 AND ix.type <= 2, ' DESC ', ' ')
                        FROM sys.index_columns IC1
                        JOIN sys.columns C ON C.object_id = IC1.object_id
                            AND C.column_id = IC1.column_id
                            --AND IC1.is_included_column = 0   
                            AND IIF(ix.type <= 2, IC1.is_included_column, 0) = 0
                            AND IIF(ix.type <= 2, IC1.key_ordinal, ic.index_column_id) > 0
                        WHERE IC1.object_id = IC2.object_id
                            AND IC1.index_id = IC2.index_id
                        GROUP BY IC1.object_id
                            , C.NAME
                            , index_id
                            , IC1.key_ordinal
                            , IC1.index_column_id
                        ORDER BY IIF(ix.type <= 2, IC1.key_ordinal, IC1.index_column_id)
                        FOR XML PATH('')
                        ), 1, 2, '') KeyColumns
            FROM sys.index_columns IC2
            GROUP BY IC2.object_id
                , IC2.index_id
            ) tmp
        WHERE tmp.object_id = ix.object_id
            AND tmp.index_id = ix.index_id
        ) AS KeyColumnsStr
    , (
        SELECT IncludedColumns
        FROM (
            SELECT IC2.object_id, IC2.index_id
                , STUFF((
                        SELECT ' , ' + C.NAME
                        FROM sys.index_columns IC1
                        JOIN sys.columns C ON C.object_id = IC1.object_id
                            AND C.column_id = IC1.column_id
                            --AND IC1.is_included_column = 1   
                            AND IIF(ix.type <= 2, IC1.is_included_column, 0) <> 0
                        WHERE IC1.object_id = IC2.object_id
                            AND IC1.index_id = IC2.index_id
                        --and IIF(ix.type <= 2, IC1.key_ordinal, ic.index_column_id) > 0
                        GROUP BY IC1.object_id, C.NAME, index_id, IC1.key_ordinal, IC1.index_column_id
                        ORDER BY IIF(ix.type <= 2, IC1.key_ordinal, IC1.index_column_id)
                        FOR XML PATH('')
                        ), 1, 2, '') IncludedColumns
            FROM sys.index_columns IC2
            GROUP BY IC2.object_id, IC2.index_id
            ) tmp
        WHERE tmp.object_id = ix.object_id
            AND tmp.index_id = ix.index_id
            AND IncludedColumns IS NOT NULL
        ) AS IncludedColumnsStr
FROM sys.indexes ix
INNER JOIN sys.index_columns ic ON ic.index_id = ix.index_id AND ic.object_id = ix.object_id
INNER JOIN sys.columns col ON col.column_id = ic.column_id AND col.object_id = ix.object_id
INNER JOIN sys.data_spaces ds ON ix.data_space_id = ds.data_space_id
WHERE ix.NAME IS NOT NULL AND IIF(ix.type <= 2, ic.key_ordinal, ic.index_column_id) > 0
AND is_primary_key = 0
)
, Scrpt AS (
SELECT *
    , 'CREATE ' 
    + CASE WHEN is_unique = 1 THEN ' UNIQUE ' ELSE '' END 
    + type_desc COLLATE DATABASE_DEFAULT + ' INDEX [' + IndexName + '] ON ' 
        + SchemaName + '.' + TableName + '(' + KeyColumnsStr + ')' 
    + ISNULL(IIF(HasIncludedColumn > 0, ' ', ' INCLUDE (' + IncludedColumnsStr + ')'), '') 
    + IIF(filter_definition IS NULL, ' ', ' WHERE ' + filter_definition) 
    + ' WITH (' 
        + CASE WHEN IsColumnStore = 1 THEN ' DROP_EXISTING = OFF '
          ELSE
                IIF(is_padded = 1, ' PAD_INDEX = ON ', ' PAD_INDEX = OFF ') + ',' 
                + ' DROP_EXISTING = OFF ' + ',' 
                + ' ONLINE = OFF ' + ',' 
                + IIF(allow_row_locks = 1, ' ALLOW_ROW_LOCKS = ON ', ' ALLOW_ROW_LOCKS = OFF ') + ',' 
                + IIF(allow_page_locks = 1, ' ALLOW_PAGE_LOCKS = ON ', ' ALLOW_PAGE_LOCKS = OFF ') 
          END
        + ' ) ' 
    + IIF(DataSpaceType = 'FG','ON [' + DataSpaceName + ']', '') AS CreateIndexScript
FROM IndexInfo
)
INSERT INTO #CreateIndexes
(
    index_script
)
SELECT DISTINCT CreateIndexScript
FROM Scrpt
WHERE OBJECT_ID = OBJECT_ID('dbo.'+ @OldTblName) 


INSERT INTO #indexes
(
	index_name,
	index_description,
	index_keys
)

EXEC sp_helpindex @OldTblName -- get all indexes name

DECLARE @curid INT = 1
DECLARE @maxid INT = (SELECT MAX(id) FROM #indexes)


/*rename indexes name start*/
	WHILE @curid <= @maxid
		BEGIN 
			SELECT 
				@OldName = @OldTblName + N'.' + index_name ,
				@NewName = index_name + '_old'
			FROM #indexes WHERE id = @curid

			EXEC sys.sp_rename @objname =  @OldName, @newname = @NewName
			SET @curid = @curid + 1
		END 
/*rename indexes name end*/

/*rename table name start*/
EXEC sys.sp_rename @objname =  @OldTblName, @newname = @NewTblName
/*rename table name end*/

/*create new table start*/
IF NOT EXISTS 
	(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = @OldTblName)
BEGIN 
	EXEC (@SQL)
END 
ELSE 
BEGIN 
	ROLLBACK 
	RETURN 
END 
/*create new table end*/

SET @curid = 1
SET @maxid = (SELECT MAX(id) FROM #CreateIndexes)

/*create indexes on new table start*/
WHILE @curid <= @maxid
	BEGIN
	 SELECT @SQL = index_script FROM #CreateIndexes WHERE id = @curid
	 EXEC (@SQL)
	 SET @curid = @curid + 1
    END 
/*create indexes on new table end*/

COMMIT 


