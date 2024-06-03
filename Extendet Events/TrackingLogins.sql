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
