WITH JobHistory AS (
    SELECT 
        h.instance_id, h.job_id, h.step_id, h.step_name, h.message, 
        h.run_status, h.run_date, h.run_time, h.run_duration, h.server, 
        j.originating_server_id, j.name, j.enabled, j.description, 
        j.start_step_id, j.category_id, j.owner_sid, j.date_created, 
        j.date_modified, j.version_number,
        CAST(CONVERT(DATETIME, Cast(run_date AS CHAR(8)) + ' ' + 
            Stuff(Stuff(RIGHT('000000' + Cast(run_time AS VARCHAR(6)), 6), 3, 0, ':'), 6, 0, ':')) 
            AS DATETIME) AS from_dt,
        DATEADD(SECOND, 
            (run_duration / 10000) * 3600 + ((run_duration % 10000) / 100) * 60 + (run_duration % 100), 
            CAST(CONVERT(DATETIME, Cast(run_date AS CHAR(8)) + ' ' + 
            Stuff(Stuff(RIGHT('000000' + Cast(run_time AS VARCHAR(6)), 6), 3, 0, ':'), 6, 0, ':')) 
            AS DATETIME)
        ) AS to_dt
    FROM msdb.dbo.sysjobhistory h
    JOIN msdb.dbo.sysjobs j ON h.job_id = j.job_id
)
SELECT DISTINCT 
    s.instance_id, 
    e.execution_id, 
    e.folder_name, 
    e.project_name, 
    e.package_name, 
    e.project_lsn, 
    e.executed_as_name, 
    e.use32bitruntime, 
    e.operation_type, 
    e.object_type, 
    e.object_id, 
    e.status, 
    e.start_time, 
    e.end_time, 
    e.caller_name, 
    e.process_id
FROM JobHistory AS s
LEFT JOIN SSISDB.catalog.executions e
    ON e.start_time BETWEEN DATEADD(SECOND, -5, s.from_dt) AND DATEADD(SECOND, 5, s.to_dt)
INNER JOIN SSISDB.catalog.operation_messages m 
    ON e.execution_id = m.operation_id 
    AND m.message_type = 120;