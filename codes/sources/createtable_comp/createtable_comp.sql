CREATE OR REPLACE PROCEDURE createtable_comp(string text) AS $$
declare comma_posi int = strpos(string, ',');
declare tabl text;
DECLARE nattrib int;
DECLARE col text;
DECLARE typeCol text;
declare typeNew text;
DECLARE attrString text = '(';
DECLARE nRows int;

    BEGIN

        while comma_posi<>-1 loop

        	if comma_posi=0 then tabl=btrim(string, ' ');
            else tabl=btrim(left(string, comma_posi-1), ' ');
			end if;

            nattrib = getNumAttr(tabl);
            nRows = getnumrows(tabl);

            execute 'drop table if exists '||tabl||'_comp';

            for i in 1..nattrib LOOP
            	col = getNamewithNum(tabl, i::text);
                typeCol = getTypewithNum(tabl, i::text);

                if existBothFunctions(col) then
                    typeNew = col||'_comp';
                    if not existType(typeNew) THEN
                        execute 'create type '||typeNew||' AS (val '||typeCol||')';
                    end if;
                    call createOP(col, typeCol, typeNew);
                ELSE
                    typeNew=typeCol;
                end if;

                attrString=attrString||col||' '||typeNew;

                if i<> nAttrib then
                    attrString=attrString||', ';
                ELSE
                    attrString=attrString||')';
                end if;

            end loop;

            execute 'create table '||tabl||'_comp '||attrString;

            for i in 1..nRows LOOP
                execute 'insert into '||tabl||'_comp values '||getTuple(tabl, i::text);
            end loop;

			attrString='(';

            if comma_posi>0 THEN
                string = substr(string, comma_posi+1);
                comma_posi = strpos(string, ',');
            else comma_posi=-1;
            end if;

        end loop;

    END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE function getTuple(tabl text, tuple text) returns text AS $$
DECLARE nattrib int = getNumAttr(tabl);
DECLARE queryString text = '(';
DECLARE currentCol text;
DECLARE currentVal text;
DECLARE insertstring text;
    BEGIN
            for i in 1..nattrib LOOP
            	currentCol=getNamewithnum(tabl, i::text);
            	currentVal= getCurrentVal(currentCol, tabl, tuple);

                if existBothFunctions(currentCol) then
                    if currentVal is null THEN
                    	insertstring='row(null)';
                    else
                    	insertstring='row('''||currentVal||''')';
                    end if;
                else
                    if currentVal is null THEN
                    	insertstring='null';
                    else
                    	insertstring=''''||currentVal||'''';
                    end if;
                end if;

                queryString=queryString||insertstring;

                if i<> nAttrib then
                	queryString=queryString||', ';
                ELSE
                	queryString=queryString||')';
                end if;

            end loop;
            return queryString;
    END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE PROCEDURE createOP(col text, typecol text, typecomp text) AS $$
    BEGIN
        execute
        'create or replace function eq'||col||'(x '||typecomp||', y '||typecomp||') returns boolean as $t$
        select interpr'||col||'(f'||col||'(x.val, y.val));
        $t$ LANGUAGE sql';

        execute
        'create or replace function eq'||col||'(x '||typecomp||', y '||typecol||') returns boolean as $t$
        select interpr'||col||'(f'||col||'(x.val, y));
        $t$ LANGUAGE sql';

        execute
        'create or replace function eq'||col||'(x '||typecol||', y '||typecomp||') returns boolean as $t$
        select interpr'||col||'(f'||col||'(x, y.val));
        $t$ LANGUAGE sql';

        execute 'drop OPERATOR if exists ==('||typecomp||', '||typecomp||')';
        execute 'drop OPERATOR if exists =('||typecomp||', '||typecol||')';
        execute 'drop OPERATOR if exists =('||typecol||', '||typecomp||')';

        execute 'CREATE OPERATOR == (
               FUNCTION = eq'||col||',
               LEFTARG = '||typecomp||',
               RIGHTARG = '||typecomp||',
               NEGATOR = !== ,
               COMMUTATOR = ==,
               RESTRICT = eqsel,
               JOIN = eqjoinsel,
               MERGES
            )';

        execute 'CREATE OPERATOR = (
               FUNCTION = eq'||col||',
               LEFTARG = '||typecomp||',
               RIGHTARG = '||typecol||',
               NEGATOR = != ,
               COMMUTATOR = =,
               RESTRICT = eqsel,
               JOIN = eqjoinsel,
               MERGES
            )';

        execute 'CREATE OPERATOR = (
               FUNCTION = eq'||col||',
               LEFTARG = '||typecol||',
               RIGHTARG = '||typecomp||',
               NEGATOR = != ,
               COMMUTATOR = =,
               RESTRICT = eqsel,
               JOIN = eqjoinsel,
               MERGES
            )';


            --=========================================================================


            execute
            'create or replace function neq'||col||'(x '||typecomp||', y '||typecomp||') returns boolean as $t$
            select not interpr'||col||'(f'||col||'(x.val, y.val));
            $t$ LANGUAGE sql';

            execute
            'create or replace function neq'||col||'(x '||typecomp||', y '||typecol||') returns boolean as $t$
            select not interpr'||col||'(f'||col||'(x.val, y));
            $t$ LANGUAGE sql';

            execute
            'create or replace function neq'||col||'(x '||typecol||', y '||typecomp||') returns boolean as $t$
            select not interpr'||col||'(f'||col||'(x, y.val));
            $t$ LANGUAGE sql';

            execute 'drop OPERATOR if exists !==('||typecomp||', '||typecomp||')';
            execute 'drop OPERATOR if exists <>=('||typecomp||', '||typecomp||')';
            execute 'drop OPERATOR if exists !=('||typecomp||', '||typecol||')';
            execute 'drop OPERATOR if exists !=('||typecol||', '||typecomp||')';

            execute 'CREATE OPERATOR !== (
                   FUNCTION = neq'||col||',
                   LEFTARG = '||typecomp||',
                   RIGHTARG = '||typecomp||',
                   NEGATOR = == ,
                   COMMUTATOR = !==,
                   RESTRICT = neqsel,
                   JOIN = neqjoinsel,
                   MERGES
                )';

            execute 'CREATE OPERATOR <>= (
                   FUNCTION = neq'||col||',
                   LEFTARG = '||typecomp||',
                   RIGHTARG = '||typecomp||',
                   NEGATOR = == ,
                   COMMUTATOR = <>=,
                   RESTRICT = neqsel,
                   JOIN = neqjoinsel,
                   MERGES
                )';

            execute 'CREATE OPERATOR != (
                   FUNCTION = neq'||col||',
                   LEFTARG = '||typecomp||',
                   RIGHTARG = '||typecol||',
                   NEGATOR = = ,
                   COMMUTATOR = !=,
                   RESTRICT = neqsel,
                   JOIN = neqjoinsel,
                   MERGES
                )';

            execute 'CREATE OPERATOR != (
                   FUNCTION = neq'||col||',
                   LEFTARG = '||typecol||',
                   RIGHTARG = '||typecomp||',
                   NEGATOR = = ,
                   COMMUTATOR = !=,
                   RESTRICT = neqsel,
                   JOIN = neqjoinsel,
                   MERGES
                )';
    END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE function getCurrentVal(currentCol text, tabl text, tuple text) returns table (n text) AS $$
    BEGIN
        return query execute 'select '||currentCol||'::text from '||'(select *, row_number()over() as rownum from '||tabl||') as x where rownum='||tuple;
    END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION getNumAttr(tabl text) returns text AS $$
        select max(dtd_identifier)
        from information_schema.columns
        where table_name = tabl;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION getNumwithName(tabl text, name text) returns text AS $$
        select dtd_identifier
        from information_schema.columns
        where table_name = tabl and column_name=name;
$$ LANGUAGE sql;


CREATE OR REPLACE FUNCTION getTypewithNum(tabl text, col text) returns text AS $$
        select udt_name
        from information_schema.columns
        where table_name = tabl and dtd_identifier=col;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION getNamewithNum(tabl text, col text) returns text AS $$
        select column_name
        from information_schema.columns
        where table_name = tabl and dtd_identifier=col;
$$ LANGUAGE sql;

CREATE OR REPLACE function getNumRows(tabl text) returns table (n int) AS $$
    BEGIN
        return query execute 'SELECT count(*)::int FROM '||tabl;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION existBothFunctions(col text) returns BOOLEAN AS $$
	select
    (select exists(
    select p.proname as function_name
	from pg_proc p
	left join pg_namespace n on p.pronamespace = n.oid
	where n.nspname not in ('pg_catalog', 'information_schema') and proname='f'||col))
    and
    (select exists(
    select p.proname as function_name
	from pg_proc p
	left join pg_namespace n on p.pronamespace = n.oid
	where n.nspname not in ('pg_catalog', 'information_schema') and proname='interpr'||col));
$$ LANGUAGE sql;

CREATE OR REPLACE function existType(type text) returns BOOLEAN AS $$
    select exists (select 1 from pg_type where typname = type);
$$ LANGUAGE sql;
