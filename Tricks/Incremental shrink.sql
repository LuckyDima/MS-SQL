USE [YourDatabase]
GO
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
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
    DECLARE @Enumerator SMALLINT = 1;
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
                  + N' SELECT @FileSizeMB = size/128., @UsedMB = FILEPROPERTY(@LogicalFileName, ''SpaceUsed'')/128. FROM sys.master_files WHERE name = @LogicalFileName AND database_id = DB_ID(@DbName)';

            EXEC @SPReturnCode = sys.sp_executesql @stmt = @Sql,
                                                   @params = N'@LogicalFileName sysname, @DbName sysname, @FileSizeMB BIGINT OUTPUT, @UsedMB BIGINT OUTPUT',
                                                   @LogicalFileName = @LogicalFileName,
                                                   @DbName = @DbName,
                                                   @FileSizeMB = @FileSizeMB OUTPUT,
                                                   @UsedMB = @UsedMB OUTPUT;

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
                      + CONVERT(VARCHAR(20), @FileSizeMB - @ShrinkStepMB * @Enumerator) + N') WITH NO_INFOMSGS';

                IF @Debug = 1
                BEGIN
                    RAISERROR('Counter is: %s', 0, 1, @Enumerator) WITH NOWAIT;
                    RAISERROR('The first command: %s', 0, 1, @Sql) WITH NOWAIT;
                END;

                IF @Enumerator <= 5
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
                BEGIN
                    RAISERROR(
                                 'Advice. You could try to increase or decrease a @ShrinkStepMB value. Current value is: %s',
                                 0,
                                 1,
                                 @ShrinkStepMB
                             ) WITH NOWAIT;
                    BREAK;
                END;

                IF @WithInfo = 1
                BEGIN
                    SELECT @PercentCompleted = CONVERT(DECIMAL(18, 4), (@SpaceShrinkedNow / @TotalSpaceToShrink)) * 100,
                           @PercentCompletedString = CONVERT(NVARCHAR(10), @PercentCompleted, 10);
                    RAISERROR('%s%% completed.', 0, 1, @PercentCompletedString) WITH NOWAIT;
                END;

                SET @Sql
                    = N'USE ' + QUOTENAME(@DbName)
                      + N' SELECT @FileSizeMB = size/128., @UsedMB = FILEPROPERTY(@LogicalFileName, ''SpaceUsed'')/128. FROM sys.master_files WHERE name = @LogicalFileName AND database_id = DB_ID(@DbName)';
                EXEC @SPReturnCode = sys.sp_executesql @stmt = @Sql,
                                                       @params = N'@LogicalFileName sysname, @DbName sysname, @FileSizeMB BIGINT OUTPUT, @UsedMB BIGINT OUTPUT',
                                                       @LogicalFileName = @LogicalFileName,
                                                       @DbName = @DbName,
                                                       @FileSizeMB = @FileSizeMB OUTPUT,
                                                       @UsedMB = @UsedMB OUTPUT;

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
                           @Enumerator = 1;
                    SET @SpaceShrinkedNow = @SpaceShrinkedNow + @ShrinkStepMB;
                END;
                ELSE
                    SET @Enumerator += 1;

                IF @Debug = 1
                BEGIN
                    DECLARE @Parameters NVARCHAR(MAX) = CONCAT(@PreFileSizeMB, ', ', @FileSizeMB);
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
