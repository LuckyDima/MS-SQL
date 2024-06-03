IF EXISTS(SELECT * FROM sys.server_event_sessions WHERE name = 'TrackingLogins')
DROP EVENT SESSION [TrackingLogins] ON SERVER;
GO
CREATE EVENT SESSION [TrackingLogins]
ON SERVER
    ADD EVENT sqlserver.sql_batch_completed
    (ACTION
     (
         sqlserver.sql_text,
         sqlserver.server_principal_name,
         sqlserver.client_hostname
     )
     WHERE (
               [sqlserver].[like_i_sql_unicode_string](sql_text, N'CREATE LOGIN%')
               OR [sqlserver].[like_i_sql_unicode_string](sql_text, N'ALTER LOGIN%')
               OR [sqlserver].[like_i_sql_unicode_string](sql_text, N'DROP LOGIN%')
           )
    )
    ADD TARGET package0.event_file
    (SET filename = N'<FilePath>.xel', max_rollover_files = (1))
WITH
(
    MAX_MEMORY = 4096KB,
    EVENT_RETENTION_MODE = ALLOW_SINGLE_EVENT_LOSS,
    MAX_DISPATCH_LATENCY = 1 SECONDS,
    MAX_EVENT_SIZE = 0KB,
    MEMORY_PARTITION_MODE = NONE,
    TRACK_CAUSALITY = OFF,
    STARTUP_STATE = OFF
);
GO
ALTER EVENT SESSION [TrackingLogins] ON SERVER STATE = START;
GO

USE [YourDatabase]
GO

CREATE OR ALTER VIEW dbo.CheckTrackingLogins
AS
WITH Target_Data
AS (SELECT CAST(event_data AS XML) AS event_data
    FROM sys.fn_xe_file_target_read_file(
         (
             SELECT TOP (1)
                    CAST(xet.target_data AS XML).value('(EventFileTarget/File/@name)[1]', 'NVARCHAR(MAX)') FileName
             FROM sys.dm_xe_session_targets xet
                 JOIN sys.dm_xe_sessions xes
                     ON xes.address = xet.event_session_address
             WHERE xes.name = 'TrackingLogins'
                   AND xet.target_name = 'event_file'
             ORDER BY xes.create_time DESC
         ),
         NULL,
         NULL,
         NULL
                                        ) )
SELECT CONVERT(
                  DATETIME2,
                  SWITCHOFFSET(
                                  CONVERT(DATETIMEOFFSET, events.event_data.value('(@timestamp)[1]', 'DATETIME2')),
                                  DATENAME(TZOFFSET, SYSDATETIMEOFFSET())
                              )
              ) DatetimeLocal,
       events.event_data.value('(./@name)[1]', 'sysname') EventName,
	   events.event_data.value('(./action[@name="server_principal_name"]/value)[1]', 'sysname') Executer,
	   events.event_data.value('(./action[@name="client_hostname"]/value)[1]', 'NVARCHAR(256)') HostName,
       events.event_data.value('(./action[@name="sql_text"]/value)[1]', 'VARCHAR(MAX)') SQLStatement
FROM Target_Data
    CROSS APPLY event_data.nodes('//event') AS events(event_data);
