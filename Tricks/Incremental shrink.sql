DECLARE @DbName sysname;
DECLARE @Sql NVARCHAR(8000);
DECLARE @LogicalFileName sysname;
DECLARE @FileSizeMB BIGINT;
DECLARE @UsedMB BIGINT;
DECLARE @FreeSizeMB BIGINT = 1000;
DECLARE @ShrinkStepMB BIGINT = 100;

IF @DbName IS NULL RETURN;

DECLARE file_cursor CURSOR FAST_FORWARD LOCAL FORWARD_ONLY FOR 
    SELECT name FROM sys.master_files WHERE type_desc = 'ROWS';

OPEN file_cursor;
FETCH NEXT FROM file_cursor INTO @LogicalFileName;

WHILE @@FETCH_STATUS = 0
BEGIN
    SELECT @FileSizeMB = size/128., @UsedMB = FILEPROPERTY(@LogicalFileName, 'SpaceUsed')/128. FROM sys.sysfiles WHERE name = @LogicalFileName;
    WHILE @FileSizeMB > @UsedMB + @FreeSizeMB + @ShrinkStepMB
    BEGIN
        SET @Sql = 'USE ' + QUOTENAME(@DbName) + '; DBCC SHRINKFILE (' + QUOTENAME(@LogicalFileName) + ', ' + CONVERT(VARCHAR(20), @FileSizeMB - @ShrinkStepMB) + ') WITH NO_INFOMSGS';
        RAISERROR (N'Start %s', 0, 1, @Sql) WITH NOWAIT;
        EXEC (@Sql);
        RAISERROR('Done %s', 0, 1, @Sql) WITH NOWAIT;
        SELECT @FileSizeMB = size/128., @UsedMB = FILEPROPERTY(@LogicalFileName, 'SpaceUsed')/128. FROM sys.sysfiles WHERE name = @LogicalFileName;
    END;
    FETCH NEXT FROM file_cursor INTO @LogicalFileName;
END;

CLOSE file_cursor;
DEALLOCATE file_cursor;

