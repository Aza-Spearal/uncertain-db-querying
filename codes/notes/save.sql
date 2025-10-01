CREATE OR REPLACE FUNCTION createFunctions() returns text AS $$
--CREATE OR REPLACE FUNCTION createFunctions() returns table (name text, x text, y text, result bit varying) AS $$
declare fname text;
declare funct text= 'create or replace function ';
declare leftarg text;
declare rightarg text;
declare lastCondi text;
declare result text;

    BEGIN

        execute 'CREATE TABLE clone AS TABLE functionTable';

        --while numLine('clone')>0 loop

            fname = getValue('name', 'clone', 'null');
            leftarg = getValue('x', 'clone', 'null');
            rightarg = getValue('y', 'clone', 'null');

            funct = 'f'||fname||'(x '||leftarg||', y '||rightarg||') returns bit as $t$ select case ';
            execute 'DELETE FROM clone WHERE name='''||fname||''' and x='''||leftarg||''' and y='''||rightarg||''' and result is null';


            result = getValue('result', 'clone', 'not null and name='''||fname||''' and x='''' and y=''''');

            if RESULT is null then raise EXCEPTION 'There is no '''' (mean: other) with the attribute ''%''', fname;
            end if;

            lastCondi = 'else b'''||result||''' END $t$ LANGUAGE sql';
            execute 'DELETE FROM clone WHERE name='''||fname||''' and x='''' and y=''''';

            while numLine('clone', fname)>0 loop

                leftarg = getValue('x', 'clone', 'not null');
                rightarg = getValue('y', 'clone', 'not null');
                result = getValue('result', 'clone', 'not null');

                if leftarg='' then leftarg='true';
                end if;
                if rightarg='' then rightarg='true';
                end if;

                funct = funct||'when '||leftarg||' and '||rightarg||' then b'''||result||'''';

                if leftarg='true' then leftarg='';
                end if;
                if rightarg='true' then rightarg='';
                end if;

                execute 'DELETE FROM clone WHERE name='''||fname||''' and x='''||leftarg||''' and y='''||rightarg||''' and result='''||result||'''';

            end loop;


            return funct;
            --return 'tt';
            --return query EXECUTE 'select * from clone';
            --return query EXECUTE 'select name, x, y, result from clone';

        --end loop;

        execute 'drop TABLE clone';

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


CREATE OR REPLACE FUNCTION numLinePG(tabl text) returns table(n int) AS $$
	BEGIN
		return query execute 'SELECT COUNT(*)::int FROM '||tabl;
    end;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION numLinePG(tabl text, fname text) returns table(n int) AS $$
	BEGIN
		return query execute 'SELECT COUNT(*)::int FROM '||tabl||' where name='''||fname||'''';
    end;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION numLine(tabl text) returns int AS $$
	SELECT numLinePG(tabl);
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION numLine(tabl text, fname text) returns int AS $$
	SELECT numLinePG(tabl, fname);
$$ LANGUAGE sql;
