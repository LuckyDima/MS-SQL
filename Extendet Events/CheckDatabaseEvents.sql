CREATE EVENT SESSION [DatabaseEvents]
ON SERVER
    ADD EVENT sqlserver.database_attached
    (ACTION
     (
         sqlserver.client_app_name,
         sqlserver.client_hostname,
         sqlserver.database_name,
         sqlserver.nt_username,
         sqlserver.session_nt_username,
         sqlserver.sql_text,
         sqlserver.username
     )
    ),
    ADD EVENT sqlserver.database_created
    (ACTION
     (
         sqlserver.client_app_name,
         sqlserver.client_hostname,
         sqlserver.database_name,
         sqlserver.nt_username,
         sqlserver.session_nt_username,
         sqlserver.sql_text,
         sqlserver.username
     )
    ),
    ADD EVENT sqlserver.database_detached
    (ACTION
     (
         sqlserver.client_app_name,
         sqlserver.client_hostname,
         sqlserver.database_name,
         sqlserver.nt_username,
         sqlserver.session_nt_username,
         sqlserver.sql_text,
         sqlserver.username
     )
    ),
    ADD EVENT sqlserver.database_dropped
    (ACTION
     (
         sqlserver.client_app_name,
         sqlserver.client_hostname,
         sqlserver.database_name,
         sqlserver.nt_username,
         sqlserver.session_nt_username,
         sqlserver.sql_text,
         sqlserver.username
     )
    ),
    ADD EVENT sqlserver.database_started
    (ACTION
     (
         sqlserver.client_app_name,
         sqlserver.client_hostname,
         sqlserver.database_name,
         sqlserver.nt_username,
         sqlserver.session_nt_username,
         sqlserver.sql_text,
         sqlserver.username
     )
    ),
    ADD EVENT sqlserver.database_stopped
    (ACTION
     (
         sqlserver.client_app_name,
         sqlserver.client_hostname,
         sqlserver.database_name,
         sqlserver.nt_username,
         sqlserver.session_nt_username,
         sqlserver.sql_text,
         sqlserver.username
     )
    ),
    ADD EVENT sqlserver.object_altered
    (ACTION
     (
         sqlserver.client_app_name,
         sqlserver.client_hostname,
         sqlserver.database_name,
         sqlserver.nt_username,
         sqlserver.session_nt_username,
         sqlserver.sql_text,
         sqlserver.username
     )
     WHERE (sqlserver.sql_text LIKE '%sp_renamedb%' OR sqlserver.sql_text LIKE '%ALTER%DATABASE%MODIFY%NAME%')
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
    STARTUP_STATE = ON
);
GO

USE [YourDatabase]
GO

CREATE OR ALTER VIEW dbo.CheckDatabaseEvents 
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
             WHERE xes.name = 'DatabaseEvents'
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
       events.event_data.value('(./data[@name="database_id"]/value)[1]', 'INT') DatabaseId,
       IIF((events.event_data.value('(./data[@name="database_name"]/value)[1]', 'sysname')) <> '',
           events.event_data.value('(./data[@name="database_name"]/value)[1]', 'sysname'),
           events.event_data.value('(./action[@name="database_name"]/value)[1]', 'sysname')) DatabaseAffected,
       events.event_data.value('(./action[@name="username"]/value)[1]', 'sysname') UserName,
       events.event_data.value('(./action[@name="client_app_name"]/value)[1]', 'sysname') Client,
       events.event_data.value('(./action[@name="sql_text"]/value)[1]', 'sysname') SQLStatement,
       events.event_data.value('(./data[@name="object_name"]/value)[1]', 'sysname') ObjectName
FROM Target_Data
    CROSS APPLY event_data.nodes('//event') AS events(event_data);
