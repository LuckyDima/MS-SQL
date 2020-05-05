USE [master]
GO
CREATE DATABASE [<dbname>] ON 
( FILENAME = N'C:\<dbname>.mdf' ),
( FILENAME = N'C:\<dbname>.ndf' )
 FOR ATTACH_REBUILD_LOG
GO