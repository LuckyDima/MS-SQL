Declare @condition_id int
EXEC msdb.dbo.sp_syspolicy_add_condition @name=N'Check DB owner is sa', @description=N'', @facet=N'IDatabaseSecurityFacet', @expression=N'<Operator>
  <TypeClass>Bool</TypeClass>
  <OpType>EQ</OpType>
  <Count>2</Count>
  <Attribute>
    <TypeClass>Bool</TypeClass>
    <Name>IsOwnerSysadmin</Name>
  </Attribute>
  <Function>
    <TypeClass>Bool</TypeClass>
    <FunctionType>True</FunctionType>
    <ReturnType>Bool</ReturnType>
    <Count>0</Count>
  </Function>
</Operator>', @is_name_condition=0, @obj_name=N'', @condition_id=@condition_id OUTPUT
Select @condition_id

GO

