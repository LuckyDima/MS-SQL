DECLARE @JobName SYSNAME, @StepId INT, @Command NVARCHAR(MAX), @PosStart BIGINT, @PosEnd BIGINT, @Server NVARCHAR(128)

-- set these values to find the error message
SET @JobName = 'YourJobName'
SET @StepId = 1

USE [msdb]
SELECT @Command = [s].[command]
FROM [sysjobs] [j]
INNER JOIN [sysjobsteps] [s] ON [s].[job_id] = [j].[job_id]
WHERE [j].[name] = @JobName
  AND [s].[step_id] = @StepId

SET @PosStart = PATINDEX('%/SERVER %', @Command)+8
SET @PosEnd = CHARINDEX(' ', @Command, @PosStart)
SET @Server = SUBSTRING(@Command, @PosStart, @PosEnd - @PosStart)
SET @PosStart = PATINDEX('%"\"%', @Command)+3
SET @PosEnd = PATINDEX('%\""%', @Command)
SET @Command = SUBSTRING(@Command, @PosStart, @PosEnd - @PosStart)
SET @Command = RIGHT(@Command, CHARINDEX('\', REVERSE(@Command)) - 1)

PRINT '--This command must be run in ' + @Server + '
USE [SSISDB]
SELECT TOP 10 [message_time], [message], [event_name], [message_source_name], [subcomponent_name]
FROM [catalog].[event_messages]
WHERE [package_name] = ''' + @Command + '''
  AND [event_name] IN (''OnWarning'', ''OnError'')
ORDER BY [event_message_id] DESC'

USE [SSISDB]
SELECT TOP 10 [message_time], [message], [event_name], [message_source_name], [subcomponent_name]
FROM [catalog].[event_messages]
WHERE [package_name] = @Command
  AND [event_name] IN ('OnWarning', 'OnError')
ORDER BY [event_message_id] DESC