DECLARE @TableName varchar(100)
DECLARE @SQL nvarchar(max)
DECLARE @bcpCommand VARCHAR(8000)
DECLARE @FileNamePath nvarchar(max)
DECLARE @DirectoryPath nvarchar(max) = 'C:\out\'



SET @FileNamePath = 'FailureLog_'+replace(replace(replace(convert(varchar(23), getdate(), 120), '-',''), ':', ''), ' ', '_') + '.txt'

SET @TableName =
(
SELECT
TOP 1 ss.name+'.'+st.name [TableName]
FROM
sys.tables st (nolock)
INNER JOIN
sys.schemas ss (nolock)
ON
st.schema_id = ss.schema_id
GROUP BY
ss.name,st.name
ORDER BY
max(st.create_date) desc
)
SET @bcpCommand = 'bcp "SELECT * FROM ' + @TableName + ' (NoLock)' + '" queryout '
SET @bcpCommand = @bcpCommand + @DirectoryPath  + @FileNamePath+ ' -c -t"|" -S EM-SQL01 -T'


PRINT @bcpcommand