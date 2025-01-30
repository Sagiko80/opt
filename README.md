select opr.object_name,msg.message_time,msg.message
from ssisdb.internal.operation_messages (nolock) as msg
inner join ssisdb.internal.operations (nolock) as opr
on opr.operation_id=msg.operation_id
where msg.message_type=120
and message_time>getdate()-3
order by 2 desc
