WITH JobExecutions AS (
    SELECT 
        j.name AS JobName,
        js.step_name AS StepName,
        js.command AS SSISCommand,
        jh.run_date,
        jh.run_time,
        jh.run_duration,
        DATEADD(SECOND, (jh.run_time % 100) + ((jh.run_time / 100) % 100) * 60 + (jh.run_time / 10000) * 3600, 
                CONVERT(DATETIME, CONVERT(CHAR(8), jh.run_date, 112))) AS JobStartTime
    FROM msdb.dbo.sysjobs j
    JOIN msdb.dbo.sysjobsteps js ON j.job_id = js.job_id
    JOIN msdb.dbo.sysjobhistory jh ON j.job_id = jh.job_id AND js.step_id = jh.step_id
    WHERE js.subsystem = 'SSIS'
)
SELECT 
    j.JobName,
    j.StepName,
    e.execution_id,
    e.package_name,
    e.status,
    e.start_time,
    e.end_time
FROM SSISDB.catalog.executions e
JOIN JobExecutions j
ON e.start_time BETWEEN DATEADD(MINUTE, -2, j.JobStartTime) AND DATEADD(MINUTE, 2, j.JobStartTime)
ORDER BY e.start_time DESC;