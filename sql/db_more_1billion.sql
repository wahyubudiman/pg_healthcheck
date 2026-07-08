select datname,age(datfrozenxid) 
from pg_database 
where age(datfrozenxid)>1000000000 
order by 2 desc;
