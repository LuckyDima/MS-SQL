declare @kill varchar(8000) = '';
select @kill=@kill+'kill '+convert(varchar(5),spid)+';'
    from master..sysprocesses  
where dbid=db_id('<dbname>') and  spid >50;
PRINT (@kill)
exec (@kill)


declare @sql nvarchar(max)
select @sql=isnull(@sql+';','')+'kill '+cast(spid as nvarchar) from master..sysprocesses where dbid=db_id('Bknd2Content')
select @sql



WHILE 1<>0
BEGIN
declare @sql nvarchar(max), @proc int
--SET @proc = cast((SELECT cast (blocked as nvarchar) from master..sysprocesses where spid = 155) as nvarchar)
select @sql = isnull(@sql+';','')+'kill '+ cast (blocked as nvarchar) from master..sysprocesses where spid = 155
PRINT (@sql)
EXEC (@sql)
END
