--Point-in-time restore: Analyzing the system trace 
declare 
 @TraceFilePath nvarchar(2000) 
select @TraceFilePath = convert(nvarchar(2000),value) 
from ::fn_trace_getinfo(0) 
where traceid = 1 and property = 2; 
select 
 StartTime, EventClass 
 ,case EventSubClass 
 when 0 then 'DROP' 
 when 1 then 'COMMIT' 
 when 2 then 'ROLLBACK' 
 end as SubClass 
 ,ObjectID, ObjectName, TransactionID 
from ::fn_trace_gettable(@TraceFilePath, default) 
where EventClass = 47 and DatabaseName = 'MyDB' 
order by StartTime desc