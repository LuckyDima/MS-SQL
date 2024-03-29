SELECT name AS "Name", 

    is_auto_create_stats_on AS "Auto Create Stats",

    is_auto_update_stats_on AS "Auto Update Stats",

    is_auto_update_stats_async_on AS "Asynchronous Update" 

FROM sys.databases

GO

ALTER DATABASE <DB_NAME> SET AUTO_UPDATE_STATISTICS ON 
ALTER DATABASE <DB_NAME> SET AUTO_UPDATE_STATISTICS_ASYNC ON
