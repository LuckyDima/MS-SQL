--Point-in-time restore: Using the fn_dump_dblog function 
select [Current LSN], [Begin Time], Operation,[Transaction Name], [Description] 
from fn_dump_dblog 
( default, default, default, default, 'C:\backups\mydb.trn',default, default, default 
,default, default, default, default, default, default, default, default, default, default 
,default, default, default, default, default, default, default, default, default, default 
,default, default, default, default, default, default, default, default, default, default 
,default, default, default, default, default, default, default, default, default, default 
,default, default, default, default, default, default, default, default, default, default 
,default, default, default, default, default, default, default, default, default, default ) 
where [Transaction Name] = 'DROPOBJ';