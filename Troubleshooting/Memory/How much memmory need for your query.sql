DECLARE @mgcounter INT
SET @mgcounter = 1
WHILE @mgcounter <= 2 -- return data from dmv 5 times when there is data
BEGIN
    IF (SELECT COUNT(*)
      FROM sys.dm_exec_query_memory_grants) > 0
    BEGIN
             SELECT *
             FROM sys.dm_exec_query_memory_grants mg
                         CROSS APPLY sys.dm_exec_sql_text(mg.sql_handle) -- shows query text
             -- WAITFOR DELAY '00:00:01' -- add a delay if you see the exact same query in results
             SET @mgcounter = @mgcounter + 1
    END
END
