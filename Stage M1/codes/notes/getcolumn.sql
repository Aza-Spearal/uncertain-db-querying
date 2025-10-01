create table r (level numeric, gender char(1), size int);
insert into r values (1.4, 'F', 73);
insert into r values (1.5, 'F', null);
insert into r values (3.2, 'M', 72);
insert into r values (3.5, 'F', 76);
insert into r values (40, 'F', 100);

select column_name from information_schema.columns where table_name = 'r';

select * from (select column_name from information_schema.columns as col where table_name = 'r') as col;


select column_name from information_schema.columns where table_name = 'r' and column_name='gender';





--Existe t'il une colonne de function qui a la même valeur qu'une case sous y ?
select * from function, (select column_name from information_schema.columns where table_name = 'function') as col where column_name=function.y;

--Est-ce qu'il existe une colonne col dans la table tab ?
CREATE OR REPLACE FUNCTION fi(in tabl text, in col text, out result text) AS $$
        select column_name from information_schema.columns where table_name = tabl and column_name=col;
$$ LANGUAGE sql;


CREATE OR REPLACE FUNCTION query6() RETURNS TABLE (col varchar(40)) AS $$--OK
declare tname text = 'r';
BEGIN
    RETURN query execute format('select column_name from information_schema.columns where table_name = %I', tname);
END;
$$ LANGUAGE plpgsql;
select * from query6();--column "r" does not exist



CREATE OR REPLACE FUNCTION query2() RETURNS TABLE (col varchar(40)) AS $$--OK
BEGIN
    RETURN QUERY select column_name from information_schema.columns where table_name = 'r';
END;
$$ LANGUAGE plpgsql;
select * from query2(); --structure of query does not match function result type


--FONCTIONS MARCHENT PAS

CREATE OR REPLACE FUNCTION query3(tname text) RETURNS TABLE (level numeric) AS $$--syntax error at or near "select"
BEGIN
    RETURN QUERY execute select level from tname;--+complexe pareil
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION query5(tname text) RETURNS TABLE (col text) AS $$--RETURN cannot have a parameter in function returning set
BEGIN
    RETURN execute format('select column_name from information_schema.columns where table_name = %I', tname);
END;
$$ LANGUAGE plpgsql;
