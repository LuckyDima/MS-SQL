SELECT * FROM dbo.systargetservers ORDER BY 2

DELETE FROM dbo.systargetservers WHERE server_name ='<servername>\<instancename>'

удалить историю синхронизации
SELECT TOP 90 PERCENT * FROM msdb..sysdownloadlist ORDER BY date_downloaded