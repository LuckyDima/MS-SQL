-- Получить список natively-compiled объектов

 s.name + '.' + o.name as [Object Name], o.object_id 
from 
 ( select schema_id, name, object_id
from sys.tables 
 where is_memory_optimized = 1 
 union all 
 select schema_id, name, object_id 
 from sys.procedures 
 ) o join sys.schemas s on 
 o.schema_id = s.schema_id; 
select base_address, language, description, name 
from sys.dm_os_loaded_modules 
where description = 'XTP Native DLL';
