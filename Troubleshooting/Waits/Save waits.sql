    USE master
    GO
    IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID (N'[dbo].[get_waitstats_2005]') AND type in ( N'P', N'PC'))
    DROP PROCEDURE [dbo].[get_waitstats_2005]
    GO

    CREATE PROCEDURE [dbo].[get_waitstats_2005] (
              @report_format varchar(20)='all',
              @report_order varchar(20)='resource')
    AS
    -- This stored procedure is provided "AS IS" with no warranties, and
    -- confers no rights.
    -- Use of included script samples are subject to the terms specified at
    -- http://www.microsoft.com/info/cpyright.htm
    --
    -- ��� ��������� ����� ������ �������� � ������� �������� �� �������
    -- �� �����
    -- (1) total wait time -- ����� �������� ������� � �������,
    -- �������� @report_format ='all' ������������ ����� � �������� � ��������
    -- (2) �������� ������ (���������)
    -- a. ����� ��� spid � �������� ������ ��������� ����������� ������,
    -- �� ������������ � ������ �������� �������, ����� ����
    -- ������ ������� � ������ � ������� ������� T0
    -- b. ���������� ����� ��������� �� ��, ��� ������ ��������, �
    -- spid ������������ � ������� ���������� � ������ ������� ����� T1
    -- c. spid ������� ���� �� ���������� ��������� �� T2, ��������� �����������
    -- ��������� ��������� ������������ ��� ����������
    -- �� ������� �� ���������� � ������� �����������
    -- (3) resource wait time -- ����������� �����, ������ ���������
    -- ������, ���� �� �� ������ ���������, T1-T0
    -- (4) signal wait time -- �����, ������� ������ � ���� �������
    -- ����� ������ ���� �������� (T1)
    -- � �� ������� T2, � ������� ������� ����� ����� � �������.
    -- ����� �������, signal wasignal ��������� T2-T1
    -- (5) �������� ������: ������������� �� ����� �������� ������� � �������
    -- �������� ������������?
    -- a. ����� ������� �������� ��������� �� ����� �����, ������� �����
    -- ��������� ���������� ���������������
    -- b. ������, ���� �� ������������� � ����� ��������� �������� �������,
    -- ��������� ������ ���� ������� �� ��������� ������� ��������
    -- �������������� spid
    -- c. ������� ������� �������� ������� ��������� �� ��, ��� ��������� ��
    -- ����� ������������ ������� ������������������,
    -- ��� ������� spid �������� ������������ �����, ���� �� �� ������������
    -- �� ������� �� ���������� � ����� ���� �
    -- ������� � ������� ���������
    -- (6) ��� ��������� ������ ����������� �� ����� ����������
    -- ��������� track_waitstats
    --
    -- Revision 4/19/2005
    -- (1) add computation for CPU Resource Waits = Sum(signal waits /
    -- total waits)
    -- (2) add @report_order parm to allow sorting by resource, signal
    -- or total waits
    --
    set nocount on

    declare @now datetime,
    @totalwait numeric(20,1),
    @totalsignalwait numeric(20,1),
    @totalresourcewait numeric(20,1),
    @endtime datetime,@begintime datetime,
    @hr int,
    @min int,
    @sec int

    if not exists (select 1
              from sysobjects
              where id = object_id ( N'[dbo].[waitstats]') and
                        OBJECTPROPERTY(id, N'IsUserTable') = 1)
    begin
              raiserror('Error [dbo].[waitstats] table does not exist',
                        16, 1) with nowait
              return
    end

    if lower(@report_format) not in ('all','detail','simple')
              begin
                        raiserror ('@report_format must be either ''all'',
                                   ''detail'', or ''simple''',16,1) with nowait
                        return
              end
    if lower(@report_order) not in ('resource','signal','total')
              begin
                        raiserror ('@report_order must be either ''resource'',
                                  ''signal'', or ''total''',16,1) with nowait
                        return
              end
    if lower(@report_format) = 'simple' and lower(@report_order) <> 'total'
              begin
                        raiserror ('@report_format is simple so order defaults to
    ''total''',
                                  16,1) with nowait
                        select @report_order = 'total'
              end


    select
              @now=max(now),
              @begintime=min(now),
              @endtime=max(now)
    from [dbo].[waitstats]
    where [wait_type] = 'Total'

    --- subtract waitfor, sleep, and resource_queue from Total
    select @totalwait = sum([wait_time_ms]) + 1, @totalsignalwait =
    sum([signal_wait_time_ms]) + 1
    from waitstats
    where [wait_type] not in (
                        'CLR_SEMAPHORE',
                        'LAZYWRITER_SLEEP',
                        'RESOURCE_QUEUE',
                        'SLEEP_TASK',
                         'SLEEP_SYSTEMTASK',
                        'Total' ,'WAITFOR',
                        '***total***') and
              now = @now

    select @totalresourcewait = 1 + @totalwait - @totalsignalwait

    -- insert adjusted totals, rank by percentage descending
    delete waitstats
    where [wait_type] = '***total***' and
    now = @now

    insert into waitstats
    select
              '***total***',
              0,@totalwait,
              0,
              @totalsignalwait,
              @now

    select 'start time'=@begintime,'end time'=@endtime,
              'duration (hh:mm:ss:ms)'=convert(varchar(50),@endtime-
    @begintime,14),
              'report format'=@report_format, 'report order'=@report_order

    if lower(@report_format) in ('all','detail')
    begin
    ----- format=detail, column order is resource, signal, total. order by resource desc
              if lower(@report_order) = 'resource'
                        select [wait_type],[waiting_tasks_count],
                                  'Resource wt (T1-T0)'=[wait_time_ms]-[signal_wait_time_ms],
                                  'res_wt_%'=cast (100*([wait_time_ms] -
                                            [signal_wait_time_ms]) /@totalresourcewait as
    numeric(20,1)),
                        'Signal wt (T2-T1)'=[signal_wait_time_ms],
                        'sig_wt_%'=cast (100*[signal_wait_time_ms]/@totalsignalwait as
    numeric(20,1)),
                        'Total wt (T2-T0)'=[wait_time_ms],
                        'wt_%'=cast (100*[wait_time_ms]/@totalwait as numeric(20,1))
              from waitstats
              where [wait_type] not in (
                        'CLR_SEMAPHORE',
                        'LAZYWRITER_SLEEP',
                        'RESOURCE_QUEUE',
                        'SLEEP_TASK',
                        'SLEEP_SYSTEMTASK',
                        'Total',
                        'WAITFOR') and
                        now = @now
              order by 'res_wt_%' desc

    ----- format=detail, column order signal, resource, total. order by signal desc
              if lower(@report_order) = 'signal'
                        select [wait_type],
                                  [waiting_tasks_count],
                                  'Signal wt (T2-T1)'=[signal_wait_time_ms],
                                  'sig_wt_%'=cast (100*[signal_wait_time_ms]/@totalsignalwait
                                  as numeric(20,1)),
                                  'Resource wt (T1-T0)'=[wait_time_ms]-[signal_wait_time_ms],
                                  'res_wt_%'=cast (100*([wait_time_ms] -
                                            [signal_wait_time_ms]) /@totalresourcewait as
    numeric(20,1)),
              'Total wt (T2-T0)'=[wait_time_ms],
              'wt_%'=cast (100*[wait_time_ms]/@totalwait as
    numeric(20,1))
              from waitstats
              where [wait_type] not in (
                        'CLR_SEMAPHORE',
                        'LAZYWRITER_SLEEP',
                        'RESOURCE_QUEUE',
                        'SLEEP_TASK',
                        'SLEEP_SYSTEMTASK',
                        'Total',
                        'WAITFOR') and
                        now = @now
                        order by 'sig_wt_%' desc

    ----- format=detail, column order total, resource, signal. order by total desc
             if lower(@report_order) = 'total'
              select
                        [wait_type],
                        [waiting_tasks_count],
                        'Total wt (T2-T0)'=[wait_time_ms],
                        'wt_%'=cast (100*[wait_time_ms]/@totalwait as numeric(20,1)),
                        'Resource wt (T1-T0)'=[wait_time_ms]-[signal_wait_time_ms],
                        'res_wt_%'=cast (100*([wait_time_ms] -
                                  [signal_wait_time_ms]) /@totalresourcewait as numeric(20,1)),
                        'Signal wt (T2-T1)'=[signal_wait_time_ms],
                        'sig_wt_%'=cast (100*[signal_wait_time_ms]/@totalsignalwait as
    numeric(20,1))
         from waitstats
         where [wait_type] not in (
                        'CLR_SEMAPHORE',
                        'LAZYWRITER_SLEEP',
                        'RESOURCE_QUEUE',
                        'SLEEP_TASK',
                        'SLEEP_SYSTEMTASK',
                        'Total',
                        'WAITFOR') and
                        now = @now
              order by 'wt_%' desc
    end
    else
    ---- simple format, total waits only
         select
              [wait_type],
              [wait_time_ms],
              percentage=cast (100*[wait_time_ms]/@totalwait as numeric(20,1))
         from waitstats
         where [wait_type] not in (
                   'CLR_SEMAPHORE',
                   'LAZYWRITER_SLEEP',
                   'RESOURCE_QUEUE',
                   'SLEEP_TASK',
                   'SLEEP_SYSTEMTASK',
                   'Total',
                   'WAITFOR') and
              now = @now
         order by percentage desc

    ---- compute cpu resource waits
    select
         'total waits'=[wait_time_ms],
         'total signal=CPU waits'=[signal_wait_time_ms],
         'CPU resource waits % = signal waits / total waits'=
              cast (100*[signal_wait_time_ms]/[wait_time_ms] as
    numeric(20,1)),
         now
    from [dbo].[waitstats]
    where [wait_type] = '***total***'
    order by now
    GO



    if exists (select * from sys.objects where object_id = object_id(N'[dbo].[track_waitstats_2005]') and OBJECTPROPERTY(object_id, N'IsProcedure') = 1)
         drop procedure [dbo].[track_waitstats_2005]
    go
    CREATE proc [dbo].[track_waitstats_2005] (@num_samples int=10
                        ,@delay_interval int=1
                        ,@delay_type nvarchar(10)='minutes'
                        ,@truncate_history nvarchar(1)='N'
                        ,@clear_waitstats nvarchar(1)='Y')
    as
    --
    -- This stored procedure is provided "AS IS" with no warranties, and confers no rights.
    -- Use of included script samples are subject to the terms specified at http://www.microsoft.com/info/cpyright.htm
    --
    -- T. Davidson
    -- @num_samples is the number of times to capture waitstats, default is 10 times
    -- default delay interval is 1 minute
    -- delaynum is the delay interval - can be minutes or seconds
    -- delaytype specifies whether the delay interval is minutes or seconds
    -- create waitstats table if it doesn-t exist, otherwise truncate
    -- Revision: 4/19/05
    --- (1) added object owner qualifier
    --- (2) optional parameters to truncate history and clear waitstats
    set nocount on
    if not exists (select 1 from sys.objects where object_id = object_id ( N'[dbo].[waitstats]') and OBJECTPROPERTY(object_id, N'IsUserTable') = 1)
         create table [dbo].[waitstats]
              ([wait_type] nvarchar(60) not null,
              [waiting_tasks_count] bigint not null,
              [wait_time_ms] bigint not null,
              [max_wait_time_ms] bigint not null,
              [signal_wait_time_ms] bigint not null,
              now datetime not null default getdate())
    If lower(@truncate_history) not in (N'y',N'n')
         begin
         raiserror ('valid @truncate_history values are ''y'' or ''n''',16,1) with nowait
         end
    If lower(@clear_waitstats) not in (N'y',N'n')
         begin
         raiserror ('valid @clear_waitstats values are ''y'' or ''n''',16,1) with nowait
         end
    If lower(@truncate_history) = N'y'
         truncate table dbo.waitstats
    If lower (@clear_waitstats) = N'y'
         dbcc sqlperf ([sys.dm_os_wait_stats],clear) with no_infomsgs -- clear out waitstats

    declare @i int,@delay varchar(8),@dt varchar(3), @now datetime, @totalwait numeric(20,1)
         ,@endtime datetime,@begintime datetime
         ,@hr int, @min int, @sec int
    select @i = 1
    select @dt = case lower(@delay_type)
         when N'minutes' then 'm'
         when N'minute' then 'm'
         when N'min' then 'm'
         when N'mi' then 'm'
         when N'n' then 'm'
         when N'm' then 'm'
         when N'seconds' then 's'
         when N'second' then 's'
         when N'sec' then 's'
         when N'ss' then 's'
         when N's' then 's'
         else @delay_type
    end
    if @dt not in ('s','m')
    begin
         raiserror ('delay type must be either ''seconds'' or ''minutes''',16,1) with nowait
         return
    end
    if @dt = 's'
    begin
         select @sec = @delay_interval % 60, @min = cast((@delay_interval / 60) as int), @hr = cast((@min / 60) as int)
    end
    if @dt = 'm'
    begin
         select @sec = 0, @min = @delay_interval % 60, @hr = cast((@delay_interval / 60) as int)
    end
    select @delay= right('0'+ convert(varchar(2),@hr),2) + ':' +
         + right('0'+convert(varchar(2),@min),2) + ':' +
         + right('0'+convert(varchar(2),@sec),2)
    if @hr > 23 or @min > 59 or @sec > 59
    begin
         select 'delay interval and type: ' + convert (varchar(10),@delay_interval) + ',' + @delay_type + ' converts to ' + @delay
         raiserror ('hh:mm:ss delay time cannot > 23:59:59',16,1) with nowait
         return
    end
    while (@i <= @num_samples)
    begin
              select @now = getdate()
              insert into [dbo].[waitstats] ([wait_type], [waiting_tasks_count], [wait_time_ms], [max_wait_time_ms], [signal_wait_time_ms], now)
              select [wait_type], [waiting_tasks_count], [wait_time_ms], [max_wait_time_ms], [signal_wait_time_ms], @now
                   from sys.dm_os_wait_stats
              insert into [dbo].[waitstats] ([wait_type], [waiting_tasks_count], [wait_time_ms], [max_wait_time_ms], [signal_wait_time_ms], now)
                   select 'Total',sum([waiting_tasks_count]), sum([wait_time_ms]), 0, sum([signal_wait_time_ms]),@now
                   from [dbo].[waitstats]
                   where now = @now
              select @i = @i + 1
              waitfor delay @delay
    end
    GO








__________________________________________


����� �������� � ���� ������ master ���� �������� , ����� ��������� ������ �� ���, �������� ���:

    EXEC dbo.track_waitstats_2005 @num_samples=20
                                 ,@delay_interval=30
                                 ,@delay_type='s'
                                 ,@truncate_history='y'
                                 ,@clear_waitstats='y'
    GO

��������� ��������� � ���������� ������� ����������. �� ��������� ��� � �������� � ������ ����� �������� ����� �� ���������. ������� ��� ����� ������ ������ ���������:

    execute dbo.get_waitstats_2005
    GO
