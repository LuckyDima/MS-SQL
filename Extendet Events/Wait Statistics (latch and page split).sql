CREATE EVENT SESSION [Wait Statistics] ON SERVER
ADD EVENT sqlserver.latch_suspend_end /* sqlserver.latch_suspend_begin */
(
    ACTION (sqlserver.session_id, sqlserver.sql_text)
    WHERE (class = N'BUF')
), ADD EVENT sqlserver.latch_suspend_warning
(
    ACTION (sqlserver.session_id)
    WHERE (class = N'BUF')
), ADD EVENT sqlserver.page_split
(
    ACTION (sqlserver.session_id)
)
ADD TARGET package0.event_file
( 
    SET FILENAME = N'D:\Wait Statistics.xel'
       ,MAX_FILE_SIZE = 4000
)
WITH
(
    MAX_MEMORY = 4096KB
   ,EVENT_RETENTION_MODE = ALLOW_SINGLE_EVENT_LOSS
   ,MAX_DISPATCH_LATENCY = 15 SECONDS
   ,TRACK_CAUSALITY = OFF
   ,MEMORY_PARTITION_MODE = NONE
   ,STARTUP_STATE = OFF
);

/*
ALTER EVENT SESSION [Wait Statistics] ON SERVER STATE = START;
ALTER EVENT SESSION [Wait Statistics] ON SERVER STATE = STOP;
DROP EVENT SESSION [Wait Statistics] ON SERVER;
*/
