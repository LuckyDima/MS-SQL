set nocount on
Print 'Column Level Privileges to the User:'
select 'grant '+privilege_type+' on '+table_schema+'.'+table_name+' ('+column_name+') to ['+grantee+']'+
case IS_GRANTABLE when 'YES' then ' With GRANT OPTION'
else '' end from INFORMATION_SCHEMA.COLUMN_PRIVILEGES
Print 'Table Level Privileges to the User:'
select 'grant '+privilege_type+' on '+table_schema+'.'+table_name+' to ['+grantee+']' +
case IS_GRANTABLE when 'YES' then ' With GRANT OPTION'else '' 
end from INFORMATION_SCHEMA.TABLE_PRIVILEGES
Print 'Privileges for Procedures/Functions to the User:'
select 
'grant execute on '+c.name+'.'+a.name+' to '+user_name(b.grantee_principal_id)+
case state when 'W'
 then ' with grant option'else ''
  end 
  
  from sys.all_objects a, sys.database_permissions b, 
  sys.schemas c
  where a.object_id = b.major_id and a.type in ('P','FN') and b.grantee_principal_id<>0and b.grantee_principal_id <>2 
  and a.schema_id=c.schema_id