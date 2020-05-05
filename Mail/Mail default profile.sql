update [msdb].[dbo].[sysmail_principalprofile]
set is_default = 1
where profile_id =
      (select max(profile_id)
      from [msdb].[dbo].[sysmail_profile]
      where [name] = '<profilename>'
      )
      
      select * from [msdb].[dbo].[sysmail_profile]
      
      select * from [msdb].[dbo].[sysmail_principalprofile]