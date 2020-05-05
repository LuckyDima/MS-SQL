
--EX get global attributes

select xp.name as [Package], xo.name as [Predicate], xo.Description 
from sys.dm_xe_packages xp join sys.dm_xe_objects xo on 
 xp.guid = xo.package_guid 
where 
 (xp.capabilities is null or xp.capabilities & 1 = 0) and -- exclude private packages 
 (xo.capabilities is null or xo.capabilities & 1 = 0) and -- exclude private objects 
 xo.object_type = 'pred_source' 
order by 
 xp.name, xo.name


--EX get comparison functions 
select xp.name as [Package], xo.name as [Comparison Function], xo.Description 
from sys.dm_xe_packages xp join sys.dm_xe_objects xo on 
 xp.guid = xo.package_guid 
where 
 (xp.capabilities is null or xp.capabilities & 1 = 0) and -- exclude private packages 
 (xo.capabilities is null or xo.capabilities & 1 = 0) and -- exclude private objects 
 xo.object_type = 'pred_compare' 
order by 
 xp.name, xo.name


--EX get actions 
select xp.name as [Package], xo.name as [Action], xo.Description 
from sys.dm_xe_packages xp join sys.dm_xe_objects xo on 
 xp.guid = xo.package_guid 
where 
 (xp.capabilities is null or xp.capabilities & 1 = 0) and -- exclude private packages 
 (xo.capabilities is null or xo.capabilities & 1 = 0) and -- exclude private objects 
 xo.object_type = 'action' 
order by 
 xp.name, xo.name



--EX get types and maps 
select xo.object_type as [Object], xo.name, xo.description, xo.type_name, xo.type_size 
from sys.dm_xe_objects xo 
where xo.object_type in ('type','map')