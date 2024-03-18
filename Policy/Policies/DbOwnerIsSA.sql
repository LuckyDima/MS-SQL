Declare @object_set_id int
EXEC msdb.dbo.sp_syspolicy_add_object_set @object_set_name=N'policy_ObjectSet', @facet=N'IDatabaseSecurityFacet', @object_set_id=@object_set_id OUTPUT
Select @object_set_id

Declare @target_set_id int
EXEC msdb.dbo.sp_syspolicy_add_target_set @object_set_name=N'policy_ObjectSet', @type_skeleton=N'Server/Database', @type=N'DATABASE', @enabled=True, @target_set_id=@target_set_id OUTPUT
Select @target_set_id

EXEC msdb.dbo.sp_syspolicy_add_target_set_level @target_set_id=@target_set_id, @type_skeleton=N'Server/Database', @level_name=N'Database', @condition_name=N'Only user databases', @target_set_level_id=0


GO

Declare @policy_id int
EXEC msdb.dbo.sp_syspolicy_add_policy @name=N'DB owner is sa', @condition_name=N'Check DB owner is sa', @policy_category=N'', @description=N'', @help_text=N'', @help_link=N'', @schedule_uid=N'1e6a941a-b958-4aaa-9d83-3e2859c9e94a', @execution_mode=4, @is_enabled=True, @policy_id=@policy_id OUTPUT, @root_condition_name=N'', @object_set=N'policy_ObjectSet'
Select @policy_id


GO

