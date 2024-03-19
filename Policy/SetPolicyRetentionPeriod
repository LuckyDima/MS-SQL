SELECT * FROM msdb.dbo.syspolicy_configuration WHERE name = N'HistoryRetentionInDays';

EXEC msdb.dbo.sp_syspolicy_configure
    @name = N'HistoryRetentionInDays',
    @value = 14;

SELECT * FROM msdb.dbo.syspolicy_configuration WHERE name = N'HistoryRetentionInDays'
