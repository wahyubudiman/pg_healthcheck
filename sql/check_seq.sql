do language plpgsql $$
declare
  v_seq name; 
  v_max int8 := 0; 
  v_last int8 := 0;
begin
  for v_seq in 
    select quote_ident(t2.nspname) || '.' || quote_ident(t1.relname) 
    from pg_class t1, pg_namespace t2 
    where t1.relnamespace=t2.oid and relkind='S' 
  loop
  
    execute 'select max_value from pg_sequences where schemaname='''||substr(v_seq,1,instr(v_seq,'.')-1) ||''' and sequencename='''||substr(v_seq,instr(v_seq,'.')+1,100) ||'''' into v_max; 
    execute 'select last_value from '||v_seq into v_last; 
    if v_max-v_last<500000000 then 
      raise notice 'Warning seq % last % max %', v_seq, v_last, v_max ; 
    -- else
    --   raise notice 'Normal seq % last % max %', v_seq, v_last, v_max ; 
    end if;
  end loop;
end;
$$;
