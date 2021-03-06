declare cLogins cursor

      for

      select Name

        from sys.server_principals

       where type_desc LIKE  'WINDOWS%'

      

open cLogins

declare @login varchar(100)

fetch cLogins into @login

while @@FETCH_STATUS=0

      begin

            begin try

                  declare @sql nvarchar(max)

                  set @sql = 'alter login ' + quotename(@login,'[') + ' with  name = ' + quotename(@login,'[')

                  execute (@sql)

            end try

            begin catch

                  if ERROR_NUMBER() = 15098

                        print @login  + ' failed validation with the system SID. This user/group account has been recreated. You will need to drop and recreate the login and associated database user accounts'

                  else

                        print @login + ' - ' + error_message() + ' (' + cast(error_number() as varchar(10)) + ')'

            end catch

            fetch cLogins into @login

      end

deallocate cLogins 