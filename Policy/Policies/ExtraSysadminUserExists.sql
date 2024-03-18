Declare @object_set_id int
EXEC msdb.dbo.sp_syspolicy_add_object_set @object_set_name=N'Extra sysadmin exists_ObjectSet', @facet=N'Server', @object_set_id=@object_set_id OUTPUT
Select @object_set_id

Declare @target_set_id int
EXEC msdb.dbo.sp_syspolicy_add_target_set @object_set_name=N'Extra sysadmin exists_ObjectSet', @type_skeleton=N'Server', @type=N'SERVER', @enabled=True, @target_set_id=@target_set_id OUTPUT
Select @target_set_id



GO

Declare @policy_id int
EXEC msdb.dbo.sp_syspolicy_add_policy @name=N'Extra sysadmin user exists', @condition_name=N'Check extra sysadmin users', @policy_category=N'', @description=N'', @help_text=N'', @help_link=N'', @schedule_uid=N'1e6a941a-b958-4aaa-9d83-3e2859c9e94a', @execution_mode=4, @is_enabled=True, @policy_id=@policy_id OUTPUT, @root_condition_name=N'Check extra sysadmin users', @object_set=N'Extra sysadmin exists_ObjectSet'
Select @policy_id


GO

