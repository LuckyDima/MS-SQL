USE [YourDatabase]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[IncrementalDbShrink]
(
    @DbName sysname,
    @WithInfo BIT = 0,
    @FreeSizeMB BIGINT = 1024,
    @ShrinkStepMB BIGINT = 128,
    @FileType VARCHAR(16) = 'ROWS',
    @Debug BIT = 0,
    @ErrorMessage NVARCHAR(MAX) = '' OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Sql NVARCHAR(MAX);
    DECLARE @LogicalFileName sysname;
    DECLARE @FileSizeMB BIGINT;
    DECLARE @UsedMB BIGINT;
    DECLARE @Counter SMALLINT = 0;
    DECLARE @PreFileSizeMB BIGINT = 0;
    DECLARE @SPReturnCode SMALLINT;
    DECLARE @TotalSpaceToShrink DECIMAL(18, 4);
    DECLARE @SpaceShrinkedNow DECIMAL(18, 4) = 0;
    DECLARE @PercentCompleted DECIMAL(18, 4);
    DECLARE @PercentCompletedString NVARCHAR(10);

    BEGIN TRY
        DECLARE file_cursor CURSOR FAST_FORWARD LOCAL FORWARD_ONLY FOR
        SELECT name
        FROM sys.master_files
        WHERE type_desc = @FileType
              AND database_id = DB_ID(@DbName);

        OPEN file_cursor;
        FETCH NEXT FROM file_cursor
        INTO @LogicalFileName;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @Sql
                = N'USE ' + QUOTENAME(@DbName)
                  + N'; SELECT @FileSizeMB = size/128., @UsedMB = FILEPROPERTY(@LogicalFileName, ''SpaceUsed'')/128. FROM sys.master_files WHERE name = @LogicalFileName AND database_id = DB_ID(@DbName)';

            EXEC @SPReturnCode = sys.sp_executesql @Sql,
                                                   N'@FileSizeMB BIGINT OUTPUT, @UsedMB BIGINT OUTPUT, @LogicalFileName sysname, @DbName sysname',
                                                   @FileSizeMB OUTPUT,
                                                   @UsedMB OUTPUT,
                                                   @LogicalFileName,
                                                   @DbName;

            IF @SPReturnCode <> 0
            BEGIN
                PRINT 'Error! Code return: ' + CAST(@SPReturnCode AS NVARCHAR(10)) + '. Error message: '
                      + ERROR_MESSAGE();
                RAISERROR('Statement execution failed! %s', 0, 1, @Sql) WITH NOWAIT;
                BREAK;
            END;

            SET @TotalSpaceToShrink = CONVERT(DECIMAL(18, 4), @FileSizeMB - @UsedMB - @FreeSizeMB);

            WHILE @FileSizeMB > @UsedMB + @FreeSizeMB + @ShrinkStepMB
            BEGIN
                SET @Sql
                    = N'USE ' + QUOTENAME(@DbName) + N'; DBCC SHRINKFILE (' + QUOTENAME(@LogicalFileName) + N', '
                      + CONVERT(VARCHAR(20), @FileSizeMB - @ShrinkStepMB) + N') WITH NO_INFOMSGS';

                IF @Debug = 1
                BEGIN
                    RAISERROR('Counter is: %s', 0, 1, @Counter) WITH NOWAIT;
                    RAISERROR('The first command: %s', 0, 1, @Sql) WITH NOWAIT;
                END;

                IF @Counter < 3
                   AND @Debug = 0
                BEGIN
                    EXEC @SPReturnCode = sys.sp_executesql @stmt = @Sql;
                    IF @SPReturnCode <> 0
                    BEGIN
                        PRINT 'Error! Code return: ' + CAST(@SPReturnCode AS NVARCHAR(10)) + '. Error message: '
                              + ERROR_MESSAGE();
                        RAISERROR('Statement execution failed! %s', 0, 1, @Sql) WITH NOWAIT;
                        BREAK;
                    END;
                END;
                ELSE
                    BREAK;

                IF @WithInfo = 1
                BEGIN
                    SELECT @PercentCompleted = CONVERT(DECIMAL(18, 4), (@SpaceShrinkedNow / @TotalSpaceToShrink)) * 100,
                           @PercentCompletedString = CONVERT(NVARCHAR(10), @PercentCompleted, 10);
                    RAISERROR('%s%% completed.', 0, 1, @PercentCompletedString) WITH NOWAIT;
                END;

                SET @Sql
                    = N'USE ' + QUOTENAME(@DbName)
                      + N'; SELECT @FileSizeMB = size/128., @UsedMB = FILEPROPERTY(@LogicalFileName, ''SpaceUsed'')/128. FROM sys.master_files WHERE name = @LogicalFileName AND database_id = DB_ID(@DbName)';
                EXEC @SPReturnCode = sys.sp_executesql @Sql,
                                                       N'@FileSizeMB BIGINT OUTPUT, @UsedMB BIGINT OUTPUT, @LogicalFileName sysname, @DbName sysname',
                                                       @FileSizeMB OUTPUT,
                                                       @UsedMB OUTPUT,
                                                       @LogicalFileName,
                                                       @DbName;

                IF @SPReturnCode <> 0
                BEGIN
                    PRINT 'Error! Code return: ' + CAST(@SPReturnCode AS NVARCHAR(10)) + '. Error message: '
                          + ERROR_MESSAGE();
                    RAISERROR('Statement execution failed! %s', 0, 1, @Sql) WITH NOWAIT;
                    BREAK;
                END;

                IF @PreFileSizeMB <> @FileSizeMB
                BEGIN
                    SELECT @PreFileSizeMB = @FileSizeMB,
                           @Counter = 0;
                    SET @SpaceShrinkedNow = @SpaceShrinkedNow + @ShrinkStepMB;
                END;
                ELSE
                    SET @Counter += 1;

                IF @Debug = 1
                BEGIN
                    DECLARE @Parameters NVARCHAR = CONCAT_WS(@PreFileSizeMB, @FileSizeMB, ',');
                    RAISERROR('The second command: %s', 0, 1, @Sql) WITH NOWAIT;
                    RAISERROR('Parameters @PreFileSizeMB, @FileSizeMB: %s', 0, 1, @Parameters) WITH NOWAIT;
                END;
            END;
            FETCH NEXT FROM file_cursor
            INTO @LogicalFileName;
        END;

        CLOSE file_cursor;
        DEALLOCATE file_cursor;
    END TRY
    BEGIN CATCH
        SET @ErrorMessage = ERROR_MESSAGE();
        PRINT 'Error! Code return: ' + CAST(@SPReturnCode AS NVARCHAR(10)) + '. Error message: ' + ERROR_MESSAGE();
    END CATCH;
END;


