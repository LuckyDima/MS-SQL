select schema_name(o.schema_id) + '.' + o.name 
, u.name as [principal_name]
, u.type_desc as [principal_type]
, r.minor_id, r.permission_name, r.state_desc
, o.schema_id, o.principal_id as [alt_owner], o.type_desc
 from sys.database_permissions r
  Left Join sys.database_Principals u
        ON r.grantee_principal_id = u.principal_id
  Left Join sys.all_objects o
        ON o.object_id = r.major_id
 Where class_desc NOT IN ('database') and u.name = 'External_Monitoring'