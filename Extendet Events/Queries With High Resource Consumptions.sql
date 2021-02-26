CREATE EVENT SESSION [QueriesWithHighResourceConsumptions]
ON SERVER
    ADD EVENT sqlos.wait_info
    (ACTION (sqlserver.client_app_name,
             sqlserver.client_hostname,
             sqlserver.database_name,
             sqlserver.sql_text,
             sqlserver.username)
     WHERE (   [sqlserver].[is_system] = (0)
         AND   [sqlserver].[database_id] > (4)
         AND   [Duration] > (25000000))),
    ADD EVENT sqlserver.rpc_completed
    (WHERE (   (   [cpu_time] >= (5000000)
              OR   [logical_reads] >= (10000)
              OR   [writes] >= (10000))
         AND   [sqlserver].[is_system] = (0)
         AND   [sqlserver].[database_id] > (4))),
    ADD EVENT sqlserver.sql_statement_completed
    (ACTION (sqlserver.client_app_name,
             sqlserver.client_hostname,
             sqlserver.sql_text,
             sqlserver.tsql_stack,
             sqlserver.username)
     WHERE (   (   [package0].[greater_than_equal_uint64]([cpu_time], (5000000))
              OR   [package0].[greater_than_equal_uint64]([logical_reads], (10000))
              OR   [package0].[greater_than_equal_uint64]([writes], (10000)))
         AND   [package0].[equal_boolean]([sqlserver].[is_system], (0))
         AND   [package0].[greater_than_uint64]([sqlserver].[database_id], (4))
         AND   [package0].[greater_than_equal_int64]([Duration], (5000000))))
    ADD TARGET package0.event_file
    (SET filename = N'QueriesWithHighResourceConsumptions', max_file_size = (100))
WITH (MAX_MEMORY = 4096KB,
      EVENT_RETENTION_MODE = ALLOW_SINGLE_EVENT_LOSS,
      MAX_DISPATCH_LATENCY = 30 SECONDS,
      MAX_EVENT_SIZE = 0KB,
      MEMORY_PARTITION_MODE = NONE,
      TRACK_CAUSALITY = OFF,
      STARTUP_STATE = OFF);
GO