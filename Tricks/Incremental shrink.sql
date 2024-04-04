DECLARE @DbName sysname;
DECLARE @sql VARCHAR(8000);
DECLARE @name sysname;
DECLARE @sizeMB BIGINT;
DECLARE @UsedMB BIGINT;
DECLARE @FreeMB BIGINT = 1000;
DECLARE @ShrinkMB BIGINT = 100;

IF @DbName IS NULL RETURN;

DECLARE file_cursor CURSOR FOR
    SELECT name
    FROM sys.master_files
    WHERE type_desc = 'ROWS'; -- Мы выбираем только файлы данных

OPEN file_cursor;
FETCH NEXT FROM file_cursor INTO @name;

WHILE @@FETCH_STATUS = 0
BEGIN
    SELECT @sizeMB = size/128., @UsedMB = FILEPROPERTY(@name, 'SpaceUsed')/128.	FROM sys.sysfiles WHERE name = @name;
    WHILE @sizeMB > @UsedMB + @FreeMB + @ShrinkMB
    BEGIN
        SET @sql = 'USE ' + QUOTENAME(@DbName) + '; DBCC SHRINKFILE (' + QUOTENAME(@name) + ', ' + CONVERT(VARCHAR(20), @sizeMB - @ShrinkMB) + ') WITH NO_INFOMSGS';
        RAISERROR (N'Start %s', 0, 1, @sql) WITH NOWAIT;
        EXEC (@sql);
        RAISERROR('Done %s', 0, 1, @sql) WITH NOWAIT;
        SELECT @sizeMB = size/128., @UsedMB = FILEPROPERTY(@name, 'SpaceUsed')/128.	FROM sys.sysfiles WHERE name = @name;
    END;
    FETCH NEXT FROM file_cursor INTO @name;
END;

CLOSE file_cursor;
DEALLOCATE file_cursor;
