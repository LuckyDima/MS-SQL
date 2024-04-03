CREATE EVENT SESSION [FailedLogins]
ON SERVER
    ADD EVENT sqlserver.error_reported
    (ACTION
     (
         sqlos.task_time,
         sqlserver.client_app_name,
         sqlserver.client_hostname,
         sqlserver.database_name,
         sqlserver.nt_username,
         sqlserver.sql_text
     )
     WHERE (
               [severity] = (14)
               AND [state] > (1)
               AND [error_number] = (18456)
           )
    )
    ADD TARGET package0.event_file
    (SET filename = N'<FilePath>.xel', max_rollover_files = (1))
WITH
(
    MAX_MEMORY = 4096KB,
    EVENT_RETENTION_MODE = ALLOW_SINGLE_EVENT_LOSS,
    MAX_DISPATCH_LATENCY = 30 SECONDS,
    MAX_EVENT_SIZE = 0KB,
    MEMORY_PARTITION_MODE = NONE,
    TRACK_CAUSALITY = OFF,
    STARTUP_STATE = OFF
);
GO

USE [YourDatabase]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[CheckFailedLogins] 
AS
WITH Target_Data AS
(
    SELECT CAST(event_data AS XML) AS event_data
    FROM sys.fn_xe_file_target_read_file(
        (
            SELECT TOP (1) CAST(xet.target_data AS XML).value('(EventFileTarget/File/@name)[1]', 'NVARCHAR(MAX)') FileName
            FROM sys.dm_xe_session_targets xet
            JOIN sys.dm_xe_sessions xes ON xes.address = xet.event_session_address
            WHERE xes.name = 'FailedLogins' AND xet.target_name = 'event_file'
            ORDER BY xes.create_time DESC 
        ), NULL, NULL, NULL   )
)
SELECT 
    CONVERT(DATETIME2, SWITCHOFFSET(CONVERT(DATETIMEOFFSET, events.event_data.value('(@timestamp)[1]', 'DATETIME2')), DATENAME(TZOFFSET, SYSDATETIMEOFFSET()))) DatetimeLocal,
    events.event_data.value('(./@name)[1]', 'sysname') EventName,
    IIF((events.event_data.value('(./data[@name="database_name"]/value)[1]', 'sysname')) <> '', events.event_data.value('(./data[@name="database_name"]/value)[1]', 'sysname'), events.event_data.value('(./action[@name="database_name"]/value)[1]', 'sysname')) DatabaseAffected,
    events.event_data.value('(./action[@name="client_app_name"]/value)[1]', 'sysname') Client,
	events.event_data.value('(./data[@name="message"]/value)[1]', 'NVARCHAR(MAX)') Message
FROM Target_Data
CROSS APPLY event_data.nodes('//event') AS events(event_data)
GO
