WITH JobFailures AS (
    SELECT 
        j.name AS JobName,
        h.job_id,
        h.step_name COLLATE SQL_Latin1_General_CP1_CI_AS AS step_name,
        CONVERT(DATETIME, 
            CAST(h.run_date AS CHAR(8)) + ' ' + 
            STUFF(STUFF(RIGHT('000000' + CAST(h.run_time AS VARCHAR(6)), 6), 3, 0, ':'), 6, 0, ':')
        ) AS RunDateTime,
        h.run_status,
        h.message COLLATE SQL_Latin1_General_CP1_CI_AS AS SQLAgentErrorMessage
    FROM msdb.dbo.sysjobhistory h WITH (NOLOCK)
    JOIN msdb.dbo.sysjobs j WITH (NOLOCK) ON h.job_id = j.job_id
    WHERE h.run_status = 0
)
SELECT 
    jf.JobName,
    jf.step_name,
    jf.RunDateTime,
    jf.run_status,
    jf.SQLAgentErrorMessage,
    CAST(m.message AS NVARCHAR(MAX)) AS SSISErrorMessage
FROM JobFailures jf
INNER JOIN SSISDB.catalog.executions e WITH (NOLOCK)
    ON jf.job_id = e.job_id
INNER JOIN SSISDB.catalog.operation_messages m WITH (NOLOCK)
    ON e.execution_id = m.operation_id
    AND m.message_type = 120
    AND m.message IS NOT NULL
ORDER BY jf.RunDateTime DESC;