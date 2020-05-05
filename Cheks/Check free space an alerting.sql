set nocount on
declare @svrName varchar(255),
		@sql varchar(400)
IF OBJECT_ID('tempdb..#output') IS NOT NULL
    DROP TABLE #output
IF OBJECT_ID('tempdb..##result') IS NOT NULL
    DROP TABLE ##result
--by default it will take the current server name, we can the set the server name as well
set @svrName = @@SERVERNAME
set @sql = 'powershell.exe -c "Get-WmiObject -ComputerName ' + QUOTENAME(@svrName,'''') + ' -Class Win32_Volume -Filter ''DriveType = 3'' | select name,capacity,freespace | foreach{$_.name+''|''+$_.capacity/1048576+''%''+$_.freespace/1048576+''*''}"'
--creating a temporary table
CREATE TABLE #output
(line varchar(255))
--inserting disk name, total space and free space value in to temporary table
insert #output EXEC xp_cmdshell @sql
--script to retrieve the values in MB from PS Script output
select @svrName as 'Servername  '
	  ,GETDATE() as 'Date                   '
	  ,rtrim(ltrim(SUBSTRING(line,1,CHARINDEX('|',line) -1))) as 'Drivename'
      ,round(cast(rtrim(ltrim(SUBSTRING(line,CHARINDEX('|',line)+1,
      (CHARINDEX('%',line) -1)-CHARINDEX('|',line)) )) as Float),0) as 'Capacity(MB)'
      ,round(cast(rtrim(ltrim(SUBSTRING(line,CHARINDEX('%',line)+1,
      (CHARINDEX('*',line) -1)-CHARINDEX('%',line)) )) as Float),0) as 'Freespace(MB)'
      ,round((((round(cast(rtrim(ltrim(SUBSTRING(line,CHARINDEX('%',line)+1,
      (CHARINDEX('*',line) -1)-CHARINDEX('%',line)) )) as Float),0))/
      (round(cast(rtrim(ltrim(SUBSTRING(line,CHARINDEX('|',line)+1,
      (CHARINDEX('%',line) -1)-CHARINDEX('|',line)) )) as Float),0)))*100),2) as 'ProtcentNotUsed'
into ##result      
from #output
where line like '[A-Z][:]%'
order by drivename
if exists (select top 1 1 from ##result where ProtcentNotUsed <=100) 
begin
DECLARE @xml NVARCHAR(MAX)
DECLARE @body NVARCHAR(MAX)
SET @xml = CAST(( SELECT [ServerName] AS 'td','',[Date] AS 'td','',
       [DriveName] AS 'td','', cast ([Capacity(MB)] as int) AS 'td','', cast([Freespace(MB)] as int) AS 'td','', cast([ProtcentNotUsed] as int) AS 'td'
from ##result where ProtcentNotUsed >=10
FOR XML PATH('tr'), ELEMENTS ) AS NVARCHAR(MAX))


SET @body ='<html><body><H3>Info</H3>
<table border = 1> 
<tr>
<th> Server Name </th> <th> Date </th> <th> Driver Name </th> <th> Capacity(MB) </th> <th> Freespace(MB) </th> <th> ProtcentNotUsed </th></tr>'    
 
SET @body = @body + @xml +'</table></body></html>'
EXEC msdb.dbo.sp_send_dbmail
--@profile_name = 'SQL ALERTING', -- replace with your SQL Database Mail Profile 
@body = @body,
@body_format ='HTML',
@recipients = 'email@domain.com', -- replace with your email address
@subject = 'Low free disk space on server!' ;
end
