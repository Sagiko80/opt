--3:get tasks details from [execution_id]
USE SSISDB;
GO

--\Package\Sequence Container\FLC Refresh Tables
--917668
--917648
--917628
--917611

--902002
--901992
--901977
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;--?
 
DECLARE @execution_id BIGINT = 917668;

 
WITH msgs
AS ( SELECT event_message_id ,
            execution_path ,
            package_name ,
            package_path_full ,
            event_name ,
            message_source_name ,
            package_path
     FROM   internal.event_messages (NOLOCK)
     WHERE  event_name IN ( 'OnPreExecute', 'OnPostExecute' )
            AND operation_id = @execution_id ) ,
     running
AS ( SELECT *
     FROM   msgs o
     WHERE  o.event_name = 'OnPreExecute'
            AND NOT EXISTS (   SELECT *
                               FROM   msgs AS c
                               WHERE  c.event_name = 'OnPostExecute'
                                      AND c.execution_path = o.execution_path ))
SELECT   ex.execution_id ,
         ex.project_name ,
         e.executable_id ,
         e.executable_name ,
         e.package_name ,
         e.package_path ,
         CONVERT(DATETIME, es.start_time) AS start_time ,
         CONVERT(DATETIME, es.end_time) AS end_time ,
         CONVERT(VARCHAR, DATEADD(ms, es.execution_duration, 0), 108) AS 'duration_h:m:s' ,
         es.execution_duration AS 'execution_duration_ms' ,
         es.execution_result ,
         CASE es.execution_result
              WHEN 0 THEN 'Success'
              WHEN 1 THEN 'Failure'
              WHEN 2 THEN 'Completion'
              WHEN 3 THEN 'Cancelled'
         END AS execution_result_description ,
         es.execution_path ,
         r.*
FROM     catalog.executions ex (NOLOCK)
         JOIN catalog.executables e (NOLOCK) ON ex.execution_id = e.execution_id
         JOIN catalog.executable_statistics es (NOLOCK) ON e.executable_id = es.executable_id
                                                  AND e.execution_id = es.execution_id
         FULL OUTER JOIN running r (NOLOCK) ON es.execution_path = r.execution_path
WHERE    e.execution_id = @execution_id
ORDER BY es.execution_id DESC;
 
 
 
 
WITH msgs
AS ( SELECT event_message_id ,
            execution_path ,
            package_name ,
            package_path_full ,
            event_name ,
            message_source_name ,
            package_path
     FROM   internal.event_messages (NOLOCK)
     WHERE  event_name IN ( 'OnPreExecute', 'OnPostExecute' )
            AND operation_id = @execution_id ) ,
     running
AS ( SELECT *
     FROM   msgs o
     WHERE  o.event_name = 'OnPreExecute'
            AND NOT EXISTS (   SELECT *
                               FROM   msgs AS c
                               WHERE  c.event_name = 'OnPostExecute'
                                      AND c.execution_path = o.execution_path ))
SELECT *
FROM   running
