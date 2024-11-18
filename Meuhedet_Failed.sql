declare @FromDay DATETIME = NULL
              ,@ToDay DATETIME = NULL 
              ,@Hours smallint = -24
 
IF @FromDay IS NULL
BEGIN
   SET @ToDay = GETDATE()
   SET @FromDay = DATEADD( DAY, -1, GETDATE())
END
 
IF DATEPART( WEEKDAY , getdate()) = 1 --- sunday
  SET @Hours = -72
 
IF EXISTS ( select * from master.sys.databases where name = 'SSISDB')
BEGIN
 
;with cte_ssis
as
(
Select distinct @@SERVERNAME SERVER_NAME,
    o.Object_Name                        [ProjectName],  
    Replace(e.package_name, '.dtsx', '') [PackageName],
 
    CASE O.status
       WHEN 1 THEN 'created'
          WHEN 2 THEN 'running'
          WHEN 3 THEN 'canceled'
          WHEN 4 THEN 'failed'
          WHEN 5 THEN 'pending'
          WHEN 6 THEN 'ended unexpectedly'
          WHEN 7 THEN 'succeeded'
          WHEN 8 THEN 'stopping'
          WHEN 9 THEN 'completed'
     END AS Status,
       o.stopped_by_name,
     FORMAT( m.message_time, 'yyyy-MM-dd HH:mm', 'en-US' ) AS message_time,
 
    e.message_source_name               [Message Source Name],
    CASE m.message_source_type
       WHEN 10 THEN 'Entry APIs, such as T-SQL and CLR Stored procedures'
       WHEN 20 THEN 'External process used to run package (ISServerExec.exe)'
       WHEN 30 THEN 'Package-level objects'
       WHEN 40 THEN 'Control Flow tasks'
       WHEN 50 THEN 'Control Flow containers'
       WHEN 60 THEN 'Data Flow task'
    END AS message_source,
 
    e.event_name                       [EventName],
    e.subcomponent_name                [SubComponentName],
    e.message_code                     [MessageCod],
    m.message                          [message],
    m.extended_info_id                 [extended_info_id],
    o.caller_name                      [Caller_Name],
    case  when m.message_time between cast(cast(getdate()-1 as date)as varchar(20)) + ' 16:00:00' and cast(cast(getdate() as date)as varchar(20)) + ' 15:59:00' 
                                                       then cast(getdate() as date)
        when m.message_time between cast(cast(getdate()-2 as date)as varchar(20)) + ' 16:00:00' and cast(cast(getdate()-1 as date)as varchar(20)) + ' 15:59:00' 
                                                       then cast(getdate()-1 as date)
              when m.message_time between cast(cast(getdate()-3 as date)as varchar(20)) + ' 16:00:00' and cast(cast(getdate()-2 as date)as varchar(20)) + ' 15:59:00' 
                                                       then cast(getdate()-2 as date)
              when m.message_time between cast(cast(getdate()-4 as date)as varchar(20)) + ' 16:00:00' and cast(cast(getdate()-3 as date)as varchar(20)) + ' 15:59:00' 
                                                       then cast(getdate()-3 as date)
              when m.message_time between cast(cast(getdate()-5 as date)as varchar(20)) + ' 16:00:00' and cast(cast(getdate()-4 as date)as varchar(20)) + ' 15:59:00' 
                                                       then cast(getdate()-4 as date) else  cast(getdate() as date) end
       AS message_date,
       row_number() over (partition by o.Object_Name  order by message_time) row_num
 
From    SSISDB.internal.operations o  
        Join SSISDB.internal.operation_messages m  
            On    o.operation_id = m.operation_id  
        Join SSISDB.internal.event_messages e  
            On    m.operation_id = e.operation_id  
            And    m.operation_message_id = e.event_message_id  
Where    m.message_type = 120 and  m.message_time >  dateadd( day, -1, getdate()) and Status=4
 
)
 
select *,case when row_num!=1 then 0 else row_num end count_Project
from cte_ssis
Order By message_time Desc, [ProjectName]
end
