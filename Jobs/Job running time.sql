use msdb
go
/*
drop table #rawdata1
drop table #rawdata2
go
*/
select 1 as keyy,run_date,(substring(b.run_time,1,2)*3600) + (substring(b.run_time,4,2)*60) + (substring(b.run_time,7,2)) as run_time_in_Seconds,run_time into #rawdata1 from (
select run_date,substring(convert(varchar(20),tt),1,2) + ':' +
substring(convert(varchar(20),tt),3,2) + ':' +
substring(convert(varchar(20),tt),5,2) as [run_time] from (
select name,run_date, run_duration, 
case
when len(run_duration) = 6 then convert(varchar(8),run_duration)
when len(run_duration) = 5 then '0' + convert(varchar(8),run_duration)
when len(run_duration) = 4 then '00' + convert(varchar(8),run_duration)
when len(run_duration) = 3 then '000' + convert(varchar(8),run_duration)
when len(run_duration) = 2 then '0000' + convert(varchar(8),run_duration)
when len(run_duration) = 1 then '00000' + convert(varchar(8),run_duration)
end as tt
from dbo.sysjobs sj with (nolock)
inner join dbo.sysjobHistory sh with (nolock) 
on sj.job_id = sh.job_id 
where name = '_db:Log Backup (Multi-Server Job)'
/*and [Message] like '%The job%'*/) a ) b
select 1 as Keyy, run_time_in_Seconds into #rawdata2 from #rawdata1
select rd1.run_date, rd1.run_time, rd1.run_time_in_Seconds ,Avg(rd2.run_time_in_Seconds) as Average_run_time_in_seconds,
case
when Convert(decimal(10,1),rd1.run_time_in_Seconds)/Avg(rd2.run_time_in_Seconds)<= 1.2 then 'Green' 
when Convert(decimal(10,1),rd1.run_time_in_Seconds)/Avg(rd2.run_time_in_Seconds)< 1.4 then 'Yellow' else 'Red'
end as [color],
Case 
when len(convert(varchar(2),Avg(rd2.run_time_in_Seconds)/(3600))) = 1 then '0' + convert(varchar(2),Avg(rd2.run_time_in_Seconds)/(3600))
else convert(varchar(2),Avg(rd2.run_time_in_Seconds)/(3600))
end + ':' + 
case 
when len(convert(varchar(2),Avg(rd2.run_time_in_Seconds)%(3600)/60)) = 1 then '0' + convert(varchar(2),Avg(rd2.run_time_in_Seconds)%(3600)/60)
else convert(varchar(2),Avg(rd2.run_time_in_Seconds)%(3600)/60)
end + ':' + 
case 
when len(convert(varchar(2),Avg(rd2.run_time_in_Seconds)%60)) = 1 then '0' + convert(varchar(2),Avg(rd2.run_time_in_Seconds)%60)
else convert(varchar(2),Avg(rd2.run_time_in_Seconds)%60)
end as [Average Run Time HH:MM:SS] 
from #rawdata2 rd2 inner join #rawdata1 rd1
on rd1.keyy = rd2.keyy
group by run_date,rd1.run_time ,rd1.run_time_in_Seconds 
order by run_date desc