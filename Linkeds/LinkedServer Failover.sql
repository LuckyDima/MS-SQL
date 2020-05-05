DECLARE @srv NVARCHAR (128), @bd NVARCHAR (128), @user NVARCHAR (128), @pass NVARCHAR (128), @ssrv NVARCHAR (128), @dsrv NVARCHAR (128), @prvstr NVARCHAR (1024)
SET @srv = N'<linkedname>'							--имя линка
SET @bd = N'<dbname>'						--имя базы
SET @user = N'<username>'							--логин пользователя (должен быть зарегистрирован SQL login на сервере источнике)
SET @pass = N'<password>'						--пароль пользователя
SET @ssrv = N'<servername1>'		--сервер источник
SET @dsrv = N'<servername2>'		--файловер сервер
SET @prvstr = 'Server='+@ssrv+';FailoverPartner='+@dsrv
--PRINT (@ssrv)
--PRINT (@dsrv)
--PRINT (@prvstr)
IF  EXISTS (SELECT srv.name FROM sys.servers srv WHERE srv.server_id != 0 AND srv.name = @srv)
EXEC master.dbo.sp_dropserver @server=@srv, @droplogins='droplogins'
EXEC master.dbo.sp_addlinkedserver @server = @srv
, @srvproduct= @ssrv 
, @provider=N'SQLNCLI'
, @provstr= @prvstr
, @catalog= @bd
EXEC master.dbo.sp_addlinkedsrvlogin 
@rmtsrvname= @srv
,@useself=N'False'
,@locallogin=NULL
,@rmtuser= @user
,@rmtpassword= @pass






EXEC master.dbo.sp_addlinkedserver @server = N'<linkedname>', @srvproduct=N'<server1>', @provider=N'SQLNCLI', @provstr=N'Server=<server1>;FailoverPartner=<server2>', @catalog=N'<dbname>'
 /* For security reasons the linked server remote logins password is changed with ######## */
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'<linkedname>',@useself=N'False',@locallogin=NULL,@rmtuser=N'<username>',@rmtpassword='########'





You got the message below:
Msg 7416, Level 16, State 2, Line 1
Access to the remote server is denied because no login-mapping exists..
Cause: When creating a linked server with the parameter @provstr and you use a local SQL Server non-admin or non-Windows account, you have to add the parameter "User Name"   into the @provstr
Resolution : Add "User ID=Username" into the provider string on your linked server
EXEC master.dbo.sp_addlinkedserver @server = N'LinkServerName', @provider=N'SQLNCLI',@srvproduct = 'MS SQL Server', @provstr=N'SERVER=serverName\InstanceName;User ID=myUser' 

EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname = N'LinkServerName', @locallogin = NULL , @useself = N'False', @rmtuser = N'myUser', @rmtpassword = N'*****'
Check:
SELECT  TOP 1 * FROM LinkServerName.msdb.dbo.backupset
GO
SELECT * FROM OPENQUERY (LinkServerName, 'SELECT TOP 1 * FROM msdb.dbo.backupset ')

