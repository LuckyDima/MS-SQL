EXEC sp_addextendedproperty
@name = N'microsoft_database_tools_support',
@value = 'Hide',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table', @level1name = '!Table_1';
GO


EXEC sp_dropextendedproperty
@name = N'microsoft_database_tools_support',
@level0type = N'Schema', @level0name = 'dbo',
@level1type = N'Table', @level1name = '!Table_1';
GO

SELECT objtype, objname, name, value  
FROM fn_listextendedproperty(default, default, default, default, default, default, default);  
GO  

SELECT objtype, objname, name, value  
FROM fn_listextendedproperty (NULL, 'schema', 'dbo', 'table', default, NULL, NULL);  
GO  
