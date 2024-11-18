--0:get package details
SELECT distinct [name]
  FROM [SSISDB].[internal].[packages]
  where name like '%DMK_000_MRR_M%'
  --'%GEN_03_Mrr_Master%'
  --'%Dim_Agreement%'

  --1:get specific [execution_id] from package_name
SELECT [execution_id]
      ,[created_time]
      ,[status]
      ,[start_time]
      ,[end_time]
      ,[process_id]
  FROM [SSISDB].[catalog].[executions]
      where 
	package_name='SF_01_Mrr_Parent.dtsx'
	--'GEN_03_Mrr_Master.dtsx'
--'Dim_Agreement.dtsx'
order by 2 desc


select start_time,end_time,
*
  FROM [SSISDB].[catalog].[executions]
  where project_name='SWBI Quality - SSIS'
  order by 1 desc