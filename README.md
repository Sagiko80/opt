WITH JobHistory AS (
    SELECT 
        h.instance_id, 
        h.job_id, 
        h.step_id, 
        h.step_name, 
        h.message, 
        h.run_status, 
        h.run_date, 
        h.run_time, 
        h.run_duration, 
        h.server, 
        j.originating_server_id, 
        j.name, 
        j.enabled, 
        j.description, 
        j.start_step_id, 
        j.category_id, 
        j.owner_sid, 
        j.date_created, 
        j.date_modified, 
        j.version_number, 
        CAST(CONVERT(DATETIME, CAST(run_date AS CHAR(8)) + ' ' + 
            STUFF(STUFF(RIGHT('000000' + CAST(run_time AS VARCHAR(6)), 6), 3, 0, ':'), 6, 0, ':')) 
            AS DATETIME) AS from_dt,
        DATEADD(SECOND, 
            (run_duration / 100) * 60 + RIGHT(run_duration, 2), 
            CAST(CONVERT(DATETIME, CAST(run_date AS CHAR(8)) + ' ' + 
            STUFF(STUFF(RIGHT('000000' + CAST(run_time AS VARCHAR(6)), 6), 3, 0, ':'), 6, 0, ':')) 
            AS DATETIME)
        ) AS to_dt,
        ROW_NUMBER() OVER (ORDER BY h.instance_id DESC) AS rn -- Rank by latest instance_id
    FROM msdb.dbo.sysjobhistory h WITH (NOLOCK)
    JOIN msdb.dbo.sysjobs j WITH (NOLOCK) 
        ON h.job_id = j.job_id
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
LEFT JOIN SSISDB.catalog.executions e WITH (NOLOCK)
    ON e.start_time BETWEEN DATEADD(MINUTE, -10, s.from_dt) AND DATEADD(MINUTE, 10, s.to_dt)
INNER JOIN SSISDB.catalog.operation_messages m WITH (NOLOCK) 
    ON e.execution_id = m.operation_id 
    AND m.message_type = 120
WHERE s.rn = 1; -- Get only the last instance_id