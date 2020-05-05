-- Check existing temporary table
IF OBJECT_ID('##XE_Errors') IS NOT NULL DROP TABLE ##XE_Errors;


DECLARE 
@SQLDataRoot NVARCHAR(1024),
@filename NVARCHAR(1024),
@metadatafile NVARCHAR(1024),
@sql NVARCHAR(MAX)

EXEC master..xp_instance_regread
   @rootkey='HKEY_LOCAL_MACHINE',
   @key='SOFTWARE\Microsoft\MSSQLServer\Setup',
   @value_name='SQLDataRoot',
   @value=@SQLDataRoot OUTPUT
 
SELECT @filename = @SQLDataRoot + N'\Log\what_queries_are_failing.xel'
SELECT @metadatafile = @SQLDataRoot + N'\Log\what_queries_are_failing.xem'
SELECT @sql =
	'CREATE EVENT SESSION
	what_queries_are_failing
	ON SERVER
	ADD EVENT sqlserver.error_reported
	(
	ACTION (sqlserver.sql_text, sqlserver.tsql_stack, sqlserver.database_id, sqlserver.username)
	WHERE ([severity]> 10 AND ([error_number]<>2812 AND [message] NOT LIKE N''%CUSTOM''))
	)
	ADD TARGET package0.asynchronous_file_target
	(SET filename = ''' + @filename + ''' ,
	metadatafile = ''' + @metadatafile + ''',
	max_file_size = 5,
	max_rollover_files = 5)
	WITH (MAX_DISPATCH_LATENCY = 5SECONDS)'

--Create an extended event session
IF  EXISTS (SELECT TOP 1 1 FROM sys.server_event_sessions WHERE [name] = N'what_queries_are_failing')
BEGIN 
	DROP EVENT SESSION what_queries_are_failing ON SERVER
	EXEC (@sql)
END 
ELSE 
BEGIN
	EXEC (@sql)
END 


-- Start the EX session
ALTER EVENT SESSION what_queries_are_failing
ON SERVER STATE = START




-- Stop and drop the XE session
ALTER EVENT SESSION what_queries_are_failing ON SERVER STATE = STOP 
DROP EVENT SESSION [what_queries_are_failing] ON SERVER;


-- Create temporary table with XE errors
SELECT @sql = '
;WITH events_cte AS (
SELECT 
DATEADD(mi,
DATEDIFF(mi, GETUTCDATE(), CURRENT_TIMESTAMP),
xevents.event_data.value(''(event/@timestamp)[1]'', ''datetime2'')) AS [err_timestamp],
xevents.event_data.value(''(event/data[@name="severity"]/value)[1]'', ''bigint'') AS [err_severity],
xevents.event_data.value(''(event/data[@name="error_number"]/value)[1]'', ''bigint'') AS [err_number],
xevents.event_data.value(''(event/data[@name="message"]/value)[1]'', ''nvarchar(512)'') AS [err_message],
xevents.event_data.value(''(event/action[@name="sql_text"]/value)[1]'', ''nvarchar(max)'') AS [sql_text],
xevents.event_data
FROM sys.fn_xe_file_target_read_file
(''' + @SQLDataRoot + '\Log\what_queries_are_failing*.xel'',
''' + @SQLDataRoot + '\Log\what_queries_are_failing*.xem'',
NULL, NULL)
CROSS APPLY (SELECT CAST(event_data AS XML) AS event_data) AS xevents
)
SELECT * INTO ##XE_Errors FROM events_cte ORDER BY err_timestamp'

EXEC(@sql)

IF EXISTS (SELECT TOP 1 1 FROM ##XE_Errors)
-- Send e-mail
BEGIN
	EXEC msdb.dbo.sp_send_dbmail 
	@recipients = 'e-mail@domain', -- separate is ;
	@subject = 'Attention! We have errors.'
END 
ELSE 
-- Drop XE files and table with XE errors
BEGIN 
--	ALTER EVENT SESSION [what_queries_are_failing] ON SERVER DROP TARGET package0.event_file
	IF OBJECT_ID('##XE_Errors') IS NOT NULL DROP TABLE ##XE_Errors;
END 


