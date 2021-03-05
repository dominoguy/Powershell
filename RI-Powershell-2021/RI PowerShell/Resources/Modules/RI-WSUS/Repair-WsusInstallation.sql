EXEC msdb.dbo.sp_delete_database_backuphistory @database_name = N'SUSDB'
GO
USE [master]
GO
ALTER DATABASE [SUSDB] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
GO
DROP DATABASE [SUSDB]
GO
