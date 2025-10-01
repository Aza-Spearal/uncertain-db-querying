CREATE OR REPLACE procedure createFunctions() AS $$
declare fname text;
declare funct text= 'create or replace function ';
declare condition text;
declare lastCondi text;
declare result text;

    BEGIN

        execute 'CREATE TABLE clone AS TABLE functionTable';

        while numLine('clone')>0 loop

            fname = getValue('name', 'clone', 'null');
            condition = getValue('condition', 'clone', 'null');

            funct = 'create or replace function f'||fname||'('||condition||') returns bit as $t$
            select case';

            execute 'DELETE FROM clone WHERE name='''||fname||''' and condition='''||condition||''' and result is null';


            result = getValue('result', 'clone', 'not null and name='''||fname||''' and condition=''''');

            if RESULT is not null then
            	lastCondi = '
                else b'''||result||'''';
                execute 'DELETE FROM clone WHERE name='''||fname||''' and condition=''''';
            else
            	lastCondi='';
            end if;


            while numLine('clone', fname)>0 loop

                condition = getValue('condition', 'clone', 'not null');
                result = getValue('result', 'clone', 'not null');

                funct = funct||'
                when '||condition||' then b'''||result||'''';

                execute 'DELETE FROM clone WHERE name='''||fname||''' and condition='''||condition||''' and result='''||result||'''';

            end loop;

            execute funct||lastCondi||'
                END
                $t$ LANGUAGE sql';

        end loop;

		execute 'drop TABLE if exists clone';

    END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION getVal(sel text, tabl text, wher text) RETURNS table(n text) AS $$
    BEGIN
        RETURN QUERY execute 'select '||sel||'::text from '||tabl||' where result is '||wher;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION getValue(sel text, tabl text, wher text) returns text AS $$
	select getVal(sel, tabl, wher);
$$ LANGUAGE sql;


CREATE OR REPLACE FUNCTION numLine(tabl text) returns table(n int) AS $$
	BEGIN
		return query execute 'SELECT COUNT(*)::int FROM '||tabl;
    end;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION numLine(tabl text, fname text) returns table(n int) AS $$
	BEGIN
		return query execute 'SELECT COUNT(*)::int FROM '||tabl||' where name='''||fname||'''';
    end;
$$ LANGUAGE plpgsql;
