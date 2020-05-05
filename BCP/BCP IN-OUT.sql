"C:\Program Files\Microsoft SQL Server\110\Tools\Binn\"bcp.exe [<dbname>].[<schemaname>].[<tablename>] out G:\TEMP\file.dat -c -t "|" -r "\r\n" -T -E -S . 

"C:\Program Files\Microsoft SQL Server\110\Tools\Binn\"bcp.exe [<dbname>].[<schemaname>].[<tablename>] format nul -f G:\TEMP\file.fmt -c -T

"C:\Program Files\Microsoft SQL Server\110\Tools\Binn\"bcp.exe [<dbname>].[<schemaname>].[<tablename>] in G:\TEMP\file.dat -c -t "|" -r "\r\n"  -T  
