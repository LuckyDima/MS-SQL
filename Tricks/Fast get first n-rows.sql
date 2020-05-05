SELECT 1 FROM dbo.<tablename> (FASTFIRSTROW) WHERE column = @param

быстро вернуть n-строк 
SELECT 'First Name' + ' ' + Last Name FROM Employees ORDER BY 'First Name' OFFSET 10 ROWS FETCH NEXT 5 ROWS ONLY;