Declare @condition_id int
EXEC msdb.dbo.sp_syspolicy_add_condition @name=N'Check extra sysadmin users', @description=N'', @facet=N'Server', @expression=N'<Operator>
  <TypeClass>Bool</TypeClass>
  <OpType>EQ</OpType>
  <Count>2</Count>
  <Function>
    <TypeClass>Numeric</TypeClass>
    <FunctionType>ExecuteSql</FunctionType>
    <ReturnType>Numeric</ReturnType>
    <Count>2</Count>
    <Constant>
      <TypeClass>String</TypeClass>
      <ObjType>System.String</ObjType>
      <Value>Numeric</Value>
    </Constant>
    <Constant>
      <TypeClass>String</TypeClass>
      <ObjType>System.String</ObjType>
      <Value>SELECT COUNT(IS_SRVROLEMEMBER (''''sysadmin'''',name))&lt;?char 13?&gt;
FROM master.sys.server_principals &lt;?char 13?&gt;
WHERE name NOT IN (''''sa'''', ''''NT SERVICE\SQLSERVERAGENT'''', ''''NT Service\MSSQLSERVER'''' ,''''NT AUTHORITY\SYSTEM'''')&lt;?char 13?&gt;
AND is_disabled = 0 AND type LIKE ''''[USRG]'''' AND principal_id &gt; 10</Value>
    </Constant>
  </Function>
  <Constant>
    <TypeClass>Numeric</TypeClass>
    <ObjType>System.Double</ObjType>
    <Value>0</Value>
  </Constant>
</Operator>', @is_name_condition=0, @obj_name=N'', @condition_id=@condition_id OUTPUT
Select @condition_id

GO

