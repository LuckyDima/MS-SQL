SET NOCOUNT ON
IF OBJECT_ID('tempdb..##TempCheckDB') IS NOT NULL
    DROP TABLE ##TempCheckDB

CREATE TABLE ##TempCheckDB
(
    ServerName NVARCHAR(128),
    ServerIP NVARCHAR(15),    
    DBName NVARCHAR(128),
    Date DATETIME
)
IF OBJECT_ID('tempdb..#Temp') IS NOT NULL
    DROP TABLE #Temp
CREATE TABLE #temp 
(
	ipLine varchar(200)
)

begin
	Declare @ipLine varchar(200)
	Declare @pos int
	Declare @ip varchar(40) 
	set nocount on
	set @ip = NULL
Insert #temp exec master..xp_cmdshell 'ipconfig'
select @ipLine = ipLine from #temp
where upper (ipLine) like '%   IPv4 Address%'
	if (isnull (@ipLine,'***') != '***')
	begin 
		set @pos = CharIndex (':',@ipLine,1);
		set @ip = rtrim(ltrim(substring (@ipLine , 
		@pos + 1 ,
		len (@ipLine) - @pos)))
	end 
end 





DECLARE @CURSOR CURSOR, @LinkName VARCHAR (128), @sql NVARCHAR (max)
SET @CURSOR  = CURSOR SCROLL
FOR
SELECT NAME FROM sys.servers WHERE data_source IS NOT NULL 
AND data_source <> 'LOCALHOST'
AND data_source <> @ip
AND is_linked = 1

OPEN @CURSOR
FETCH NEXT FROM @CURSOR INTO @LinkName

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @sql = 'INSERT INTO ##TempCheckDB 
	SELECT * FROM OPENQUERY ([' + @LinkName + '],
	''SELECT @@SERVERNAME AS ServerName, CAST(CONNECTIONPROPERTY(''''local_net_address'''') as NVARCHAR(15)) AS ServerIP, Name, GETDATE() AS Date
	FROM [master].[sys].[databases] WHERE state <> 0'')'
	EXEC (@sql)
FETCH NEXT FROM @CURSOR INTO @LinkName
END
CLOSE @CURSOR 


IF (SELECT 1 FROM ##TempCheckDB) IS NOT NULL
BEGIN 

DECLARE @body NVARCHAR(MAX)	='<html><body>
<H3></H3>
<table border = 1> 
<tr>
<th> ServerName </th> <th> ServerIP </th> <th> Database name</th> <th> Check Date</th> </tr> ' 
DECLARE @xml xml = ( 
		SELECT [ServerName] [td],'',
			   [ServerIP] [td],'',
			   [DBName] [td],'',
			   [Date] [td],''
from [##TempCheckDB] 

FOR XML PATH('tr'), ELEMENTS 
) 
SELECT @body += CAST(@xml AS NVARCHAR(MAX)) +'</table>
</body></html>'
declare @subj NVARCHAR (256)
SELECT @subj = (SELECT TOP 1 'Server: ' + ServerName + '(' + ServerIP + '). Database "' + DBName + '" is offline.' FROM [##TempCheckDB])

EXEC [msdb].[dbo].[sp_send_dbmail]
    @profile_name = 'default_profile' , -- sysname
    @from_address = 'sqlservice@apacsale.com' , -- varchar(max) 
	@recipients = 'dmitry.ivanov@apacsale.com' , -- varchar(max)   
   -- @copy_recipients = 'test_sql@mysale.pagerduty.com' , -- varchar(max)
    --@blind_copy_recipients = '' , -- varchar(max)
    @subject = @subj , -- nvarchar(255)
	@body_format ='HTML',
	@body = @body,
    --@query = N'' , -- nvarchar(max)
    @reply_to = '' -- varchar(max)

END

DROP TABLE [##TempCheckDB]
DROP TABLE [#Temp]




