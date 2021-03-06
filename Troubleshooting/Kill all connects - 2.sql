-- Kill all processes connected to a database.
use master;
 
declare @DatabaseName varchar(50);
declare @Spid varchar(20);
declare @Command varchar(50);
 
set @DatabaseName = 'Configuration';
 
print 'This query''s SPID: ' + convert(varchar, @@spid);
 
-- Select all SPIDs except the SPID for this connection
declare SpidCursor cursor for
select spid from master.dbo.sysprocesses
where dbid = db_id(@DatabaseName)
and spid != @@spid
 
open SpidCursor
 
fetch next from SpidCursor into @spid
 
while @@fetch_status = 0
begin
    print 'Killing process: ' + rtrim(@spid);
    set @Command = 'kill ' + rtrim(@spid) + ';';
    print @Command;
    execute(@Command);
    fetch next from SpidCursor into @spid
end
 
close SpidCursor
deallocate SpidCursor