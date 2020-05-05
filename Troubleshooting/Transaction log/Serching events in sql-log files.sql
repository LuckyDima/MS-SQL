DECLARE @StartDate VARCHAR(50) =CAST(DATEADD(dd, -2, GETDATE()) AS VARCHAR(50))
DECLARE @EndDate VARCHAR(50) = CAST(DATEADD(dd, -1, GETDATE()) AS VARCHAR(50))
DECLARE @LogFile SMALLINT = 0
DECLARE @MaxLogFileNumver SMALLINT = 0

 

CREATE TABLE #SQLLog
    (
    LogDate    DATETIME,
    ProcessInfo VARCHAR(20),
    [Text] VARCHAR(MAX)
    )

 

CREATE TABLE #Files
    (
    [Value] VARCHAR(MAX),
    [Data] SMALLINT
    )

 

INSERT INTO #Files
EXEC xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'NumErrorLogs'

 

SELECT @MaxLogFileNumver = [Data] FROM #Files

 


WHILE NOT EXISTS (SELECT TOP (1) 1 FROM #SQLLog) AND @LogFile <= @MaxLogFileNumver
BEGIN
    INSERT INTO #SQLLog
    EXEC xp_readerrorlog @LogFile, 1, NULL, NULL, @StartDate, @EndDate
    SET @LogFile = @LogFile + 1
END

 


SELECT
    Count(*) AS Occurences,
    [Text]
FROM #SQLLog
WHERE 
    [Text] NOT LIKE 'Database backed up%'
    AND [Text] NOT LIKE 'Database was restored%'
    AND [Text] NOT LIKE 'Log was backed up%'
    AND [Text] NOT LIKE 'Database differential changes were backed up%'
    AND [Text] NOT LIKE 'Starting up database%'
    AND [Text] NOT LIKE 'Restore is complete%'
                AND [Text] NOT LIKE '%Login succeed%'
                AND [Text] NOT LIKE '%Login failed%'
GROUP BY [Text]
ORDER BY Occurences DESC

 


DROP TABLE #SQLLog, #Files