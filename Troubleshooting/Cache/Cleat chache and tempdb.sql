DBCC FREESYSTEMCACHE ('ALL') WITH MARK_IN_USE_FOR_REMOVAL;
DBCC FREESESSIONCACHE WITH NO_INFOMSGS;
DBCC FREEPROCCACHE WITH NO_INFOMSGS;
DBCC FLUSHPROCINDB(db_id) - очистка кэша для конкретной базы(команда не документирована)

declare @stmt nvarchar(max)
set @stmt=''
SELECT 
    @stmt=@stmt + N' drop table ' + QUOTENAME(name)
FROM 
    tempdb.sys.tables with (nolock)
WHERE 
    name like '#[^#]%' 
    and object_id(N'tempdb..' + QUOTENAME(name)) is not null
exec(@stmt)

____________________________________________


CREATE RESOURCE POOL InMemoryTableDB
  WITH 
    ( MIN_MEMORY_PERCENT = 80, 
    MAX_MEMORY_PERCENT = 80 );
GO

ALTER RESOURCE GOVERNOR RECONFIGURE;
GO

EXEC sp_xtp_bind_db_resource_pool 'HotelInventory', 'InMemoryTableDB'
GO
EXEC sys.sp_xtp_unbind_db_resource_pool 'HotelInventory'

SELECT d.database_id, d.name, d.resource_pool_id
FROM sys.databases d
GO

SELECT pool_id
     , Name
     , min_memory_percent
     , max_memory_percent
     , max_memory_kb/1024 AS max_memory_mb
     , used_memory_kb/1024 AS used_memory_mb 
     , target_memory_kb/1024 AS target_memory_mb
   FROM sys.dm_resource_governor_resource_pools




GO
DBCC FREEPROCCACHE ('JobHighPriority');
GO

DBCC FREEPROCCACHE 
DBCC DROPCLEANBUFFERS
DBCC FREESESSIONCACHE WITH NO_INFOMSGS;
DBCC FREESYSTEMCACHE ('ALL') WITH MARK_IN_USE_FOR_REMOVAL;
DBCC FREESYSTEMCACHE ('ALL', 'TravelRoot');

SELECT * FROM sys.dm_resource_governor_resource_pools
SELECT (30720-30720*0.1)/1024

SELECT
(physical_memory_in_use_kb/1024) AS Memory_usedby_Sqlserver_MB,
(locked_page_allocations_kb/1024) AS Locked_pages_used_Sqlserver_MB,
(total_virtual_address_space_kb/1024) AS Total_VAS_in_MB,
process_physical_memory_low,
process_virtual_memory_low
FROM sys.dm_os_process_memory;


   SELECT SUM(cache_memory_kb)/1024 FROM sys.dm_resource_governor_resource_pools;
   IF (SELECT SUM(cache_memory_kb)/1024 FROM sys.dm_resource_governor_resource_pools) > 
   (SELECT CAST(value AS INT)-CAST(value AS INT)*0.05 FROM master.sys.configurations WHERE   name = 'max server memory (MB)')
   BEGIN
    PRINT 'Drop system cache for all pools'
	DBCC FREESYSTEMCACHE ('ALL') WITH MARK_IN_USE_FOR_REMOVAL;
   END
