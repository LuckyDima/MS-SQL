DECLARE @object_set_id INT;
EXEC msdb.dbo.sp_syspolicy_add_object_set @object_set_name = N'Extra sysadmin exists_ObjectSet',
                                          @facet = N'Server',
                                          @object_set_id = @object_set_id OUTPUT;
SELECT @object_set_id;

DECLARE @target_set_id INT;
EXEC msdb.dbo.sp_syspolicy_add_target_set @object_set_name = N'Extra sysadmin exists_ObjectSet',
                                          @type_skeleton = N'Server',
                                          @type = N'SERVER',
                                          @enabled = True,
                                          @target_set_id = @target_set_id OUTPUT;
SELECT @target_set_id;

GO

DECLARE @policy_id INT;
EXEC msdb.dbo.sp_syspolicy_add_policy @name = N'Extra sysadmin user exists',
                                      @condition_name = N'Check extra sysadmin users',
                                      @policy_category = N'Internal Check',
                                      @description = N'',
                                      @help_text = N'',
                                      @help_link = N'',
                                      @schedule_uid = N'',
                                      @execution_mode = 4,
                                      @is_enabled = True,
                                      @policy_id = @policy_id OUTPUT,
                                      @root_condition_name = N'',
                                      @object_set = N'Extra sysadmin exists_ObjectSet';
SELECT @policy_id;
