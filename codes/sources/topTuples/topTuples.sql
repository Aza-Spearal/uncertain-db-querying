CREATE OR REPLACE PROCEDURE createAbstract(string text) AS $$
declare comma_posi int = strpos(string, ',');
declare tabl text;

    BEGIN

        while comma_posi<>-1 loop

        	if comma_posi=0 then tabl=btrim(string, ' ');
            else tabl=btrim(left(string, comma_posi-1), ' ');
			end if;

            execute
            'create or replace function abstract_'||tabl||'(querry text) returns table('||colBit(tabl)||') as $t$
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


create or replace function colList(tabl text) returns text as $$
DECLARE nattrib int = getNumAttr(tabl);
DECLARE String text = '';
DECLARE currentCol text;
begin

    for i in 1..nattrib LOOP

        currentCol=getNamewithnum(tabl, i::text);

        if String!='' then
            String=String||', ';
        end if;

        String=String||currentCol;

	end loop;

    return String;

end;
$$ LANGUAGE plpgsql;


create or replace function colType(tabl text) returns text as $$
DECLARE nattrib int = getNumAttr(tabl);
DECLARE queryString text = '';
DECLARE currentCol text;
DECLARE currentType text;
begin

    for i in 1..nattrib LOOP

        currentCol=getNamewithnum(tabl, i::text);
        currentType=getTypewithNum(tabl, i::text);

        if queryString!='' then
            queryString=queryString||', ';
        end if;

        queryString=queryString||currentCol||' '||currentType;

	end loop;

    return queryString;

end;
$$ LANGUAGE plpgsql;


create or replace function colBit(tabl text) returns text as $$
DECLARE nattrib int = getNumAttr(tabl);
DECLARE queryString text = '';
DECLARE currentCol text;
DECLARE nBits int;
DECLARE currentFunc text;
begin

    for i in 1..nattrib LOOP

        currentCol=getNamewithnum(tabl, i::text);

        if queryString!='' then
            queryString=queryString||', ';
        end if;

        if existFunction(currentCol) then
            queryString=queryString||currentCol||' bit('||binaryLength(currentCol)||')';
        elsif currentCol='hidden_col' then
            queryString=queryString||'hidden_col int';
        else
            queryString=queryString||currentCol||' bit(1)';
        end if;

	end loop;

    return queryString;

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
        else equality = left(cond, comma_posi-1);
        end if;

        equality = btrim(equality, ' ');
        equal_posi = strpos(equality, '=');

        expr1 = btrim(left(equality, equal_posi-1), ' ');
        expr2 = btrim(substr(equality, equal_posi+1), ' ');

        N=getNumwithName(tabl, expr1);

        if N is not NULL then
            arr[n] = 'f'||expr1||'('||tabl||'.'||expr1||','||expr2||')';
        elsif getNumwithName(tabl, expr2) is not null then
        	N=getNumwithName(tabl, expr2);
            arr[n] = 'f'||expr2||'('||tabl||'.'||expr2||','||expr1||')';
        else
            raise exception '% is not correct', '"'||expr1||'='||expr2||'"';
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

        if queryString != 'select ' then
            queryString=queryString||',';
        end if;

        if name='hidden_col' THEN
            queryString = queryString||'hidden_col';
		elsif arr[i] is null or not existFunction(name) THEN
        	queryString = queryString||'null::bit';
        else
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

CREATE OR REPLACE FUNCTION existFunction(col text) returns BOOLEAN AS $$
	select exists(
    select p.proname as function_name
	from pg_proc p
	left join pg_namespace n on p.pronamespace = n.oid
	where n.nspname not in ('pg_catalog', 'information_schema') and proname='f'||col);
$$ LANGUAGE sql;

create or replace function binaryLength(col text) returns table (ta text) as $$
begin
       return query execute 'select char_length(f'||col||'(null, null)::text)::text';
end;
$$ LANGUAGE plpgsql;


--====================================================================================


CREATE OR REPLACE FUNCTION dominate(BIT VARYING, BIT VARYING) RETURNS boolean AS $$
	SELECT (($1 & $2) = $2) AND (NOT $1 = $2) ;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION get_column_names(input_table_name text) RETURNS text[] AS $$
	SELECT ARRAY(
			SELECT column_name::text
			FROM information_schema."columns"
			WHERE "table_name"=input_table_name AND "data_type"='bit');
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION concatenate(input_row anyelement, columns_name text[]) RETURNS BIT VARYING AS $$
	DECLARE
		col text;
		result BIT VARYING = B'';
		b BIT VARYING;
	BEGIN
		FOREACH col IN ARRAY columns_name LOOP
			EXECUTE 'SELECT ($1).' || quote_ident(col) USING input_row INTO b;
			SELECT result || COALESCE(b, B'') INTO result;
		END LOOP;
		RETURN result;
	END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION skyline(input_table text) RETURNS TABLE(hidden_col int) AS $$
	DECLARE
		col_names text[];
		tuple RECORD;
		tuple_is_dominated boolean;
		size_window int = 100;
		window_full boolean;
		temp_empty boolean;
	BEGIN
		CREATE TEMP TABLE skyline_input (hidden_col int, abstract_tuple BIT VARYING);
		CREATE TEMP TABLE skyline_window (LIKE skyline_input);
		CREATE TEMP TABLE skyline_temp_file (LIKE skyline_input);
		SELECT get_column_names(input_table) INTO col_names;
		EXECUTE format('INSERT INTO skyline_input SELECT hidden_col, concatenate( %I , $1 ) FROM %I ', input_table, input_table) USING col_names;

		LOOP
			FOR tuple IN SELECT * FROM skyline_input LOOP
				SELECT count(*) > 0 FROM skyline_window WHERE dominate(abstract_tuple,tuple.abstract_tuple) INTO tuple_is_dominated;
				IF tuple_is_dominated THEN
					NULL;
				ELSE
					DELETE FROM skyline_window WHERE dominate(tuple.abstract_tuple, abstract_tuple);
					SELECT count(*) >= size_window INTO window_full FROM skyline_window;
					IF window_full THEN
						INSERT INTO skyline_temp_file values(tuple.hidden_col, tuple.abstract_tuple);
					ELSE
						INSERT INTO skyline_window values(tuple.hidden_col, tuple.abstract_tuple);
					END IF;
				END IF;
			END LOOP;

			RETURN QUERY SELECT skyline_window.hidden_col FROM skyline_window;
			DELETE FROM skyline_window;
			DELETE FROM skyline_input;
			SELECT count(*) = 0 FROM skyline_temp_file INTO temp_empty;
			IF temp_empty THEN
				DROP TABLE skyline_temp_file;
				DROP TABLE skyline_window;
				DROP TABLE skyline_input;
				RETURN;
			ELSE
				INSERT INTO skyline_input SELECT * FROM skyline_temp_file;
				DELETE FROM skyline_temp_file;
			END IF;

		END LOOP;
	END;
$$ LANGUAGE plpgsql;

--=========================================================================================


CREATE OR REPLACE PROCEDURE create_topTuples(string text) AS $$
declare comma_posi int = strpos(string, ',');
declare tabl text;

    BEGIN

        while comma_posi<>-1 loop

        	if comma_posi=0 then tabl=btrim(string, ' ');
            else tabl=btrim(left(string, comma_posi-1), ' ');
			end if;

            execute 'drop function if exists topTuples_'||tabl;

            execute
            'create or replace function topTuples_'||tabl||'(string text) returns table('||colType(tabl)||') as $t$

            declare tabl text = '''||tabl||''';
            declare colliste text = colList(tabl);
            begin
            	create table table_copy ('||colType(tabl)||');
                ALTER TABLE table_copy ADD COLUMN hidden_col serial;
                insert into table_copy select * from '||tabl||';

                call createAbstract(''table_copy'');

                create table table_abstract ('||colBit(tabl)||', hidden_col int);
                insert into table_abstract select * from abstract_table_copy(string);

    			return query execute format(''select %s from skyline(''''table_abstract'''') as skyline, table_copy where skyline.hidden_col=table_copy.hidden_col'', colliste);

                drop table if exists table_abstract, table_copy;
                drop function if exists abstract_table_copy;
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
