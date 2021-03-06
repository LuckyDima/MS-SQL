 SELECT 'Authentication Method'=(
	CASE 
		WHEN nt_user_name IS not null THEN 'Windows Authentication' 
		ELSE 'SQL Authentication' 
	END),
   login_name AS 'Login Name', ISNULL(nt_user_name,'-') AS 'Windows Login Name',
   COUNT(session_id) AS 'Session Count'
   FROM sys.dm_exec_sessions
   GROUP BY login_name,nt_user_name