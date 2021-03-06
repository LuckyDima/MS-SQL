sp_adddistributiondb 
@database= 'distribution',
@data_folder ='\\SQL2K8R2CLUSTER\repldata',
@security_mode =1,
@login = 'login',
@password = 'password'



USE master
EXEC sp_adddistributor @distributor = 'SQL2K8R2CLUSTER\SQL2K8R2CLUSTER',
@password = 'password'

distributor_admin

exec sp_helpserver
sp_get_distributor



sp_removedbreplication 'test'
EXEC sp_droppublication @publication = 'test';

exec sp_add_agent_parameter @profile_id = 9, @parameter_name = N'-PublisherFailoverPartner', @parameter_value = N'servername'
exec sp_drop_agent_parameter @profile_id = 9, @parameter_name = N'-PublisherFailoverPartner'

EXEC sp_addremotelogin 'SRV-PRO-DB14';
exec sp_adddistpublisher @publisher = 'servername', @distribution_db = 'distribution'



Cannot drop the distribution database ‘distribution’ because it is currently in use.
EXEC master.dbo.sp_serveroption @server=N'servername', @optname=N'dist', @optvalue=N'false'
GO
EXEC sp_dropdistributor @no_checks = 1, @ignore_distributor = 1
GO

Посмотреть скорость репликации:
sp_replcounters