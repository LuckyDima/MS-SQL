IF OBJECT_ID('tempdb..#tmpBus') IS NOT NULL
    DROP TABLE [#tmpBus];

CREATE TABLE [#tmpBus]
(
    [LogDate] DATETIME,
    [ProccesInfo] VARCHAR(32),
    [text] NVARCHAR(MAX)
);

INSERT INTO [#tmpBus]
EXEC [master].[sys].[xp_readerrorlog] 0, 1, N'Long Sync IO';

INSERT INTO [#tmpBus]
EXEC [master].[sys].[xp_readerrorlog] 1, 1, N'Long Sync IO';

INSERT INTO [#tmpBus]
EXEC [master].[sys].[xp_readerrorlog] 2, 1, N'Long Sync IO';

INSERT INTO [#tmpBus]
EXEC [master].[sys].[xp_readerrorlog] 3, 1, N'Long Sync IO';

USE [dba];

;WITH
cte AS
(
SELECT 
 MIN([LogDate]) OVER(PARTITION BY CAST([LogDate] AS DATE)) MinDate
,MAX([LogDate]) OVER(PARTITION BY CAST([LogDate] AS DATE)) MaxDate
,COUNT(*) OVER (PARTITION BY CAST([LogDate] AS DATE)) Cnt
,[LogDate]
FROM #tmpBus
)
SELECT DISTINCT
	   [DatabaseName],
       [CommandType],
       [StartTime],
       [EndTime],
	   [MinDate],
	   [MaxDate],
       DATEDIFF(S, [StartTime], [EndTime]) [DifTime],
       DATENAME(WEEKDAY, [StartTime]) [DayOfWeek],
	   [Cnt] AS ErrorCountByPeriod,
       REPLACE(
                  (REPLACE((REVERSE(LEFT(REVERSE([Command]), CHARINDEX('MUSKCEHC', REVERSE([Command])) - 1))), ',', ' ')),
                  '  COMPRESSION  COPY_ONLY',
                  ''
              ) [Params]
FROM [dba]..[CommandLog] CROSS JOIN cte AS t
WHERE [StartTime] >= DATEADD(DAY, -31, GETDATE())
      AND [EndTime] <= GETDATE()
      AND [DatabaseName] IN ( 'TrialManager', 'NewCentralUsers', 'BackOffice' )
      AND [CommandType] IN ( 'BACKUP_DATABASE', 'RESTORE_VERIFYONLY' )
	  AND CASE 
			WHEN t.[MinDate] BETWEEN [StartTime] AND [EndTime] 
				 OR t.[MaxDate] BETWEEN [StartTime] AND [EndTime]
			THEN 1 ELSE 0 END = 1
ORDER BY 1,2,3,4;

--select * from #tmpBus order by 1 desc
