  declare @sql nvarchar(max),            
            @lf  varchar(10)            
    select @lf = char(10)            
    select @sql = N'BULK INSERT Heap.dbo.tmp20120330_wbill              
FROM "D:\subscribers.csv"             
WITH ( FIRSTROW = 2, LASTROW=4 ,CODEPAGE=1251,  FIELDTERMINATOR = '';'', ROWTERMINATOR = ''' + @lf + ''')'            
    exec (@sql)

FIRSTROW - � ����� ������ �������� ��������
LASTROW - �� ����� ������ �������� ��������
CODEPAGE - ������� ��������
FIELDTERMINATOR - ����������� � ������
ROWTERMINATOR - ����������� ����� �����