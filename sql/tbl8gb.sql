select relname,age(relfrozenxid),pg_relation_size(oid)/1024/1024/1024.0 Table_Size_GB 
from pg_class 
where relkind='r' 
and pg_relation_size(oid)/1024/1024/1024.0 > 8 
order by 3 desc;
