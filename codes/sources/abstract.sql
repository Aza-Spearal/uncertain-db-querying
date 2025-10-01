CREATE OR REPLACE PROCEDURE createAbstract(string text) AS $$
declare comma_posi int = strpos(string, ',');
declare tabl text;

    BEGIN

        while comma_posi<>-1 loop

        	if comma_posi=0 then tabl=btrim(string, ' ');
            else tabl=btrim(left(string, comma_posi-1), ' ');
			end if;

            execute
            'create or replace function abstract_'||tabl||'(querry text) returns table'||colAbstract(tabl)||' as $t$
            declare tabl text = '''||tabl||''';
            begin
                return query execute format(abstract(tabl, querry)||''%s''||tabl, '' from '');
            end
            $t$ LANGUAGE plpgsql';

            if comma_posi>0 THEN
                string = substr(string, comma_posi+1);
                comma_posi = strpos(string, ',');
            else comma_posi=-1;
            end if;

        end loop;

    END;
$$ LANGUAGE plpgsql;


create or replace function colAbstract(tabl text) returns text as $$
DECLARE nattrib int = getNumAttr(tabl);
DECLARE queryString text = '(';
DECLARE currentCol text;
begin

    for i in 1..nattrib LOOP

        currentCol=getNamewithnum(tabl, i::text);

        if queryString!='(' and (isKey(tabl, currentCol) or existfunction(currentCol)) then
            queryString=queryString||', ';
        end if;

        if isKey(tabl, currentCol) then
            queryString=queryString||currentCol||' '||getTypewithNum(tabl, i::text);
        elsif existfunction(currentCol) then
            queryString=queryString||currentCol||' bit';
        end if;

	end loop;

    return queryString||')';

end;
$$ LANGUAGE plpgsql;


create or replace function abstract(tabl text, cond text) returns text as $$

declare arr text[];
declare comma_posi int = strpos(cond, ',');
declare equality text;
declare equal_posi int = strpos(cond, '=');
declare expr1 text;
declare expr2 text;
declare N numeric;

declare nAttr numeric = getnumattr(tabl);
declare name text;
declare queryString text ='select ';

begin

	while equal_posi>0 LOOP

    	if comma_posi=0 then equality=cond;
        else equality = btrim(left(cond, comma_posi-1), ' ');
        end if;

        expr1 = btrim(left(equality, equal_posi-1), ' ');
        expr2 = btrim(substr(equality, equal_posi+1), ' ');

        N=getNumwithName(tabl, expr1);

        if N is not NULL then
            arr[n] = 'f'||expr1||'('||tabl||'.'||expr1||','||expr2||')';
        elsif getNumwithName(tabl, expr2) is not null then
        	N=getNumwithName(tabl, expr2);
            arr[n] = 'f'||expr2||'('||tabl||'.'||expr2||','||expr1||')';
        else
            raise exception '% is not a correct form', '"'||expr1||'='||expr2||'"';
        end if;

 		if comma_posi>0 THEN
            cond = btrim(substr(cond, comma_posi+1), ' ');
            comma_posi = strpos(cond, ',');
            equal_posi = strpos(cond, '=');
        ELSE
        	equal_posi=0;
        end if;

    end loop;

    FOR i IN 1..nAttr LOOP

		name = getNamewithNum(tabl, i::text);

		if isKey(tabl, name) THEN
			arr[i]=name;
    	elsif arr[i] is null THEN
        	arr[i]='null::bit';
        end if;

		if existFunction(name) or isKey(tabl, name) then
			if queryString != 'select ' then
				queryString=queryString||',';
			end if;

			queryString= queryString||arr[i];

		end if;

    end loop;

    return queryString;

end;
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

CREATE OR REPLACE FUNCTION getNamewithNum(tabl text, col text) returns text AS $$
        select column_name
        from information_schema.columns
        where table_name = tabl and dtd_identifier=col;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION getTypewithNum(tabl text, col text) returns text AS $$
        select udt_name
        from information_schema.columns
        where table_name = tabl and dtd_identifier=col;
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION isKey(tabl text, col text) returns BOOLEAN AS $$
    select exists(
    SELECT
      pg_attribute.attname
    FROM pg_index, pg_class, pg_attribute, pg_namespace
    WHERE
      pg_class.oid = tabl::regclass AND
      indrelid = pg_class.oid AND
      pg_class.relnamespace = pg_namespace.oid AND
      pg_attribute.attrelid = pg_class.oid AND
      pg_attribute.attnum = any(pg_index.indkey)
      AND indisprimary
      and pg_attribute.attname=col);
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION existFunction(col text) returns BOOLEAN AS $$
	select exists(
    select p.proname as function_name
	from pg_proc p
	left join pg_namespace n on p.pronamespace = n.oid
	where n.nspname not in ('pg_catalog', 'information_schema') and proname='f'||col);
$$ LANGUAGE sql;
