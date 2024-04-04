USE [YourDatabase]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[IncrementalDbShrink] (@DbName sysname, @WithInfo BIT = 0, @FreeSizeMB BIGINT = 1000, @ShrinkStepMB BIGINT = 100, @FileType VARCHAR(16) = 'ROWS')
AS
BEGIN
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @Sql NVARCHAR(MAX);
DECLARE @LogicalFileName sysname;
DECLARE @FileSizeMB BIGINT;
DECLARE @UsedMB BIGINT;

    DECLARE file_cursor CURSOR FAST_FORWARD LOCAL FORWARD_ONLY FOR 
        SELECT name FROM sys.master_files WHERE type_desc = @FileType AND database_id = DB_ID(@DbName);

    OPEN file_cursor;
    FETCH NEXT FROM file_cursor INTO @LogicalFileName;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @Sql = 'USE ' + QUOTENAME(@DbName) + '; SELECT @FileSizeMB = size/128., @UsedMB = FILEPROPERTY(@LogicalFileName, ''SpaceUsed'')/128. FROM sys.master_files WHERE name = @LogicalFileName';
		EXEC sp_executesql @Sql, N'@FileSizeMB BIGINT OUTPUT, @UsedMB BIGINT OUTPUT, @LogicalFileName sysname', @FileSizeMB OUTPUT, @UsedMB OUTPUT, @LogicalFileName;

        WHILE @FileSizeMB > @UsedMB + @FreeSizeMB + @ShrinkStepMB
        BEGIN
            SET @Sql = 'USE ' + QUOTENAME(@DbName) + '; DBCC SHRINKFILE (' + QUOTENAME(@LogicalFileName) + ', ' + CONVERT(VARCHAR(20), @FileSizeMB - @ShrinkStepMB) + ') WITH NO_INFOMSGS';
            IF @WithInfo = 1 RAISERROR (N'Start %s', 0, 1, @Sql) WITH NOWAIT;
            EXEC (@Sql);
            IF @WithInfo = 1 RAISERROR('Done %s', 0, 1, @Sql) WITH NOWAIT;
            SET @Sql = 'USE ' + QUOTENAME(@DbName) + '; SELECT @FileSizeMB = size/128., @UsedMB = FILEPROPERTY(@LogicalFileName, ''SpaceUsed'')/128. FROM sys.master_files WHERE name = @LogicalFileName';
			EXEC sp_executesql @Sql, N'@FileSizeMB BIGINT OUTPUT, @UsedMB BIGINT OUTPUT, @LogicalFileName sysname', @FileSizeMB OUTPUT, @UsedMB OUTPUT, @LogicalFileName;
        END;
        FETCH NEXT FROM file_cursor INTO @LogicalFileName;
    END;

    CLOSE file_cursor;
    DEALLOCATE file_cursor;
END
