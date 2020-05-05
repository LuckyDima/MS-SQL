--�������� ����������� snapshot-�, ���� �������� �� ����� ��� ��������\��������, �� ���� 4 �������
DECLARE @srvr1 NVARCHAR(128), @srvr2 NVARCHAR(128), @retval1 INT, @retval2 INT;
SET @srvr1 = 'EPS_SNAPSHOT';
SET @srvr2 = 'IFS2_SNAPSHOT';
BEGIN TRY
    EXEC @retval1 = sys.sp_testlinkedserver @srvr1;
    EXEC @retval2 = sys.sp_testlinkedserver @srvr2;
END TRY
BEGIN CATCH
    SET @retval1 = SIGN(@@ERROR);
    SET @retval2 = SIGN(@@ERROR);
END CATCH ;
IF @retval1 <> 0 OR @retval2 <> 0
	BEGIN
WAITFOR DELAY '00:00:04'
  --RAISERROR('������������� Snapshot. ���������� ���������!', 16, 2 );
	END
