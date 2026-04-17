-- Show deadlock for last 3 days
SELECT 
    [Time_Local] = DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()), 
                   CAST(event_data AS XML).value('(/event/@timestamp)[1]', 'datetime2')),
    [Database] = CAST(event_data AS XML).value(
        '(/event/data[@name="xml_report"]/value/deadlock/process-list/process/@database)[1]', 'nvarchar(128)'),
    [Object] = CAST(event_data AS XML).value(
        '(/event/data[@name="xml_report"]/value/deadlock/resource-list/*/@objectname)[1]', 'nvarchar(512)'),
    [Lock_Type] = CAST(event_data AS XML).value(
        '(/event/data[@name="xml_report"]/value/deadlock/resource-list/*/@mode)[1]', 'nvarchar(10)'),
    [Victim_Login] = CAST(event_data AS XML).value(
        '(/event/data[@name="xml_report"]/value/deadlock/process-list/process[@id=(../../victim-list/victimProcess/@id)]/@loginname)[1]', 'nvarchar(128)'),
    [Victim_App] = CAST(event_data AS XML).value(
        '(/event/data[@name="xml_report"]/value/deadlock/process-list/process[@id=(../../victim-list/victimProcess/@id)]/@clientapp)[1]', 'nvarchar(255)'),
    [Victim_Query] = CAST(event_data AS XML).value(
        '(/event/data[@name="xml_report"]/value/deadlock/process-list/process[@id=(../../victim-list/victimProcess/@id)]/inputbuf)[1]', 'nvarchar(max)'),
    [Winner_Query] = CAST(event_data AS XML).value(
        '(/event/data[@name="xml_report"]/value/deadlock/process-list/process[@id!=(../../victim-list/victimProcess/@id)]/inputbuf)[1]', 'nvarchar(max)'),
    [DeadlockGraph] = CAST(event_data AS XML).query('/event/data[@name="xml_report"]/value/deadlock')
FROM sys.fn_xe_file_target_read_file('system_health*.xel', NULL, NULL, NULL)
WHERE object_name = 'xml_deadlock_report'
AND CAST(event_data AS XML).value('(/event/@timestamp)[1]', 'datetime2') > DATEADD(DAY,-3,GETDATE())
ORDER BY [Time_Local] DESC;

SELECT 
    [Date]        = CAST([Time_Local] AS DATE), 
    [First_Event] = MIN([Time_Local]), 
    [Last_Event]  = MAX([Time_Local]), 
    [Total_Count] = COUNT(*)
FROM (
    SELECT 
        [Time_Local] = DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), GETDATE()), 
                       CAST(event_data AS XML).value('(/event/@timestamp)[1]', 'datetime2'))
    FROM sys.fn_xe_file_target_read_file('system_health*.xel', NULL, NULL, NULL)
    WHERE object_name = 'xml_deadlock_report'
      AND CAST(event_data AS XML).value('(/event/@timestamp)[1]', 'datetime2') > DATEADD(DAY, -3, GETUTCDATE())
) t 
GROUP BY CAST([Time_Local] AS DATE)
ORDER BY [Date] DESC;



