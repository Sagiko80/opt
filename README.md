
select h.instance_id, h.job_id ,h.step_id, h.step_name,h.message, h.run_status, h.run_date, h.run_time, h.run_duration,h.server, j.originating_server_id, j.name, j.enabled, j.description, j.start_step_id,j.category_id,j.owner_sid,j.date_created, j.date_modified, j.version_number
into #jobs_all
FROM   msdb.dbo.sysjobhistory h WITH (nolock)
       JOIN msdb.dbo.sysjobs j WITH (nolock)
         ON h.job_id = j.job_id

--drop table #jobs
select * 
into #jobs
from #jobs_all
WHERE  step_id=0 


select *,
CAST(CONVERT(DATETIME, Cast(run_date AS CHAR(8)) + ' ' + Stuff(Stuff(RIGHT('000000' + Cast(run_time AS VARCHAR(6)), 6), 3, 0, ':'), 6, 0, ':')) AS DATETIME) AS from_dt,
dateadd(second,(run_duration/100) * 60 + right(run_duration,2), CAST(CONVERT(DATETIME, Cast(run_date AS CHAR(8)) + ' ' + Stuff(Stuff(RIGHT('000000' + Cast(run_time AS VARCHAR(6)), 6), 3, 0, ':'), 6, 0, ':')) AS DATETIME)) AS to_dt
into #steps
from #jobs_all
WHERE  step_id != 0 
and run_status != 1




SELECT distinct s.instance_id,
 e.execution_id, e.folder_name, e.project_name, e.package_name, e.project_lsn, e.executed_as_name, e.use32bitruntime, e.operation_type, e.object_type, e.object_id, e.status, e.start_time, e.end_time, e.caller_name, e.process_id
 --into #exec
FROM   #steps as s
       LEFT JOIN ssisdb.catalog.executions e WITH (nolock)
               ON  cast(dateadd(second,1,e.start_time) as datetime) >= from_dt
and   cast(dateadd(second, -1,e.end_time) as datetime) <= to_dt
			   INNER JOIN SSISDB.catalog.operation_messages m WITH (NOLOCK) ON e.execution_id = m.operation_id AND m.message_type = 120 
      
