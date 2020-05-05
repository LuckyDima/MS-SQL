USE [master]
GO
ALTER DATABASE SpotlightStatisticsRepository SET EMERGENCY
GO
ALTER DATABASE [SpotlightStatisticsRepository] SET  SINGLE_USER WITH ROLLBACK IMMEDIATE
GO
DBCC CHECKDB (SpotlightStatisticsRepository, REPAIR_ALLOW_DATA_LOSS) WITH NO_INFOMSGS;
GO
ALTER DATABASE SpotlightStatisticsRepository SET ONLINE
GO
ALTER DATABASE [SpotlightStatisticsRepository] SET  MULTI_USER WITH ROLLBACK IMMEDIATE
GO

�������� ������:
http://www.sqlskills.com/blogs/paul/category/Corruption.aspx