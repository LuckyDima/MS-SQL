
IF  EXISTS (SELECT * FROM sys.server_principals WHERE name = N'<loginname>')
DROP LOGIN [<loginname>]
GO

CREATE LOGIN [<loginname>] WITH PASSWORD=N’pass', SID=0xDC30F6D7CA12164AB6A80A05AC3871A1 , CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF, DEFAULT_DATABASE=[master]




EXEC sp_change_users_login 'Auto_Fix', <loginname>




select name, sid from master.dbo.syslogins where name not like '##%'
and name not like 'NT %' and name not in ( 'sa', 'distributor_admin', 'nagios-autotest')
and sid not in (0xB04867A28600E2408C30D6032E0218B1)
order by name 
