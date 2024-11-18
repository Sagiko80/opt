select opr.object_name,msg.message_time,msg.message
from ssisdb.catalog.operation_messages as msg
inner join ssisdb.catalog.operations as opr
on opr.operation_id=msg.operation_id
where msg.message_type=120
and message_time>getdate()-3
and object_name<>'SWBI File Convertor - SSIS'---------------
order by 2 desc

