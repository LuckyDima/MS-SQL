--High CPU investigation

select 
 sum(signal_wait_time_ms) as [Signal Wait Time (ms)] 
 ,convert(decimal(7,4), 100.0 * sum(signal_wait_time_ms) / 
 sum (wait_time_ms)) as [% Signal waits] 
 ,sum(wait_time_ms - signal_wait_time_ms) as [Resource Wait Time (ms)] 
 ,convert(decimal(7,4), 100.0 * sum(wait_time_ms - signal_wait_time_ms) / 
 sum (wait_time_ms)) as [% Resource waits] 
from 
 sys.dm_os_wait_stats with (nolock)

/*
Microsoft recommends that the signal wait type should not 
exceed 25 percent, I believe that 15 to 20 percent is a better target on busy systems
*/