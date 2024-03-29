SELECT  
    s.session_id 
  , c.connect_time 
  , s.login_time 
  , s.login_name 
  , c.protocol_type 
  , c.auth_scheme 
  , s.HOST_NAME 
  , s.program_name
FROM sys.dm_exec_sessions s 
  JOIN sys.dm_exec_connections c 
    ON s.session_id = c.session_id

  
  
select * from sys.dm_broker_activated_tasks 
select * from sys.dm_broker_connections
select * from sys.routes
select * from Sys.Services

SELECT *
FROM sys.databases
WHERE database_id = DB_ID();

DECLARE @xmlMessage XML;
      SELECT @xmlMessage.value(
        'declare namespace
           brokerns="http://schemas.microsoft.com/SQL/ServiceBroker/Error";
           (/brokerns:Error/brokerns:Description)[1]', 
        'nvarchar(3000)')
        

      SELECT @xmlMessage.value(
        N'declare namespace
           brokerns="http://schemas.microsoft.com/SQL/ServiceBroker/Error";
               (/brokerns:Error/brokerns:Code)[1]', 
        'int')
       
       
select * from sys.dm_broker_connections 
select * from sys.dm_broker_forwarded_messages
select * from sys.dm_broker_queue_monitors     
select * from sys.service_queues   
select * from  sys.conversation_endpoints

--alter database msdb set disable_broker WITH ROLLBACK IMMEDIATE
--ALTER DATABASE Billing3 SET NEW_BROKER
----c3badc14-ed78-4591-8211-f6fdf682248b
--ALTER DATABASE msdb SET ENABLE_BROKER
select name,service_broker_guid, is_broker_enabled
 from sys.databases where name in ('msdb')