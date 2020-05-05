;with ObjectHierarchy ( Base_Object_id , Base_Schema_id , Base_Object_Name , Base_Object_Type, Object_Id , Schema_Id , Name , Type_Desc , Level , Obj_Path,type_table_object_id) 
as 
( select  so.object_id as Base_Object_Id 
        , so.schema_id as Base_Schema_Id 
       , so.name as Base_Object_Name 
       , so.type_desc as Base_Object_Type
       , so.object_id as Object_Id 
       , so.schema_id as Schema_Id 
       , so.name 
       , so.type_desc 
       , 0 as Level 
       , convert ( nvarchar ( 1000 ) , N' | ' + so.name ) as Obj_Path 
	   ,type_table_object_id
  from sys.all_objects so 
  LEFT JOIN sys.sql_expression_dependencies ed on ed.referenced_id = so.object_id 
  LEFT JOIN sys.all_objects rso on rso.object_id = ed.referencing_id 
  LEFT JOIN sys.table_types tt ON tt.type_table_object_id = so.object_id
  WHERE 
	(rso.type is null and so.type in ('FN','IF','P','SN','TF','TR','TT','V')  AND so.object_id > 0)
	--OR ISNULL(tt.type_table_object_id,'') = so.object_id

  union all 
  select   cp.Base_Object_Id as Base_Object_Id 
         , cp.Base_schema_id 
        , cp.Base_Object_Name 
        , cp.Base_Object_Type
        , so.object_id as Object_Id 
        , so.schema_id as ID_Schema 
        , so.name 
        , so.type_desc 
        , Level + 1 as Level 
        , convert ( nvarchar ( 1000 ) , cp.Obj_Path + N' | ' + so.name ) as Obj_Path
		, type_table_object_id 
   from sys.all_objects so 
   inner join sys.sql_expression_dependencies ed on ed.referenced_id = so.object_id 
   inner join sys.all_objects rso on rso.object_id = ed.referencing_id 
   inner join ObjectHierarchy as cp on rso.object_id = cp.Object_id and rso.object_id <> so.object_id 
   where (so.type in ('FN','IF','P','SN','TF','TR','TT','V') and ( rso.type is null or rso.type in ('FN','IF','P','SN','TF','TR','TT','V') ) 
    and cp.Obj_Path not like '% | ' + so.name + ' | %' )
	--OR ISNULL(type_table_object_id,'') = so.object_id
	AND so.object_id > 0
	)   -- prevent cycles n hierarcy

select   Base_Object_Name 
       , Base_Object_Type
       , 
		 --  CASE WHEN level > 1 THEN REPLICATE ( '       ' , Level ) ELSE  '|-------' END +
	   REPLICATE ( '-------' , Level ) + 
	   CASE WHEN Level !=0 THEN '> ' ELSE '' END + Name as Indented_Name 
      , SCHEMA_NAME ( Schema_Id ) + '.' + Name as Object_Name 
      , Type_Desc as Object_Type 
      , Level 
      , Obj_Path 
    from ObjectHierarchy as p 
order by Obj_Path 

