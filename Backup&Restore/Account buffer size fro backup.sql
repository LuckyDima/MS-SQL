--Рассчитать размер буфера для бэкапа
/*
Посмотреть какой размер используется автоматически, без указания параметров
DBCC TRACEON (3605, –1)
DBCC TRACEON (3213, –1)
http://henkvandervalk.com/how-to-increase-sql-database-full-backup-speed-using-compression-and-solid-state-disks
*/

declare @MaxTransferSize float,
@BufferCount bigint,
@DBName varchar(255),
@BackupDevices bigint
set @MaxTransferSize = 0 -- Default value is zero. Value to be provided in MB.
set @BufferCount = 256 -- Default value is zero
set @DBName = 'TrialManager' -- Provide the name of the database to be backed up
set @BackupDevices = 1 -- Number of disk devices that you are writing the backup to
declare @DatabaseDeviceCount int

select @DatabaseDeviceCount=count(distinct(substring(physical_name,1,charindex(physical_name,':')+1)))
	from sys.master_files
	where database_id = db_id(@DBName)
and type_desc <> 'LOG'
if @BufferCount = 0
	set @BufferCount =(@BackupDevices*(3+1) ) + @BackupDevices +(2 * @DatabaseDeviceCount)
if @MaxTransferSize = 0
	set @MaxTransferSize = 1
select 'Total buffer space (MB): ' + cast((@Buffercount * @MaxTransferSize) as varchar(10))
