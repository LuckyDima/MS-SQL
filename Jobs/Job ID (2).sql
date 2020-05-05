SELECT p.SPID,  x.job_id
FROM msdb.dbo.sysjobs x (nolock)
JOIN sys.sysprocesses p (nolock) 
on P.Program_name like '%' + sys.fn_varbintohexstr(x.job_id) +'%'
ORDER BY P.SPID