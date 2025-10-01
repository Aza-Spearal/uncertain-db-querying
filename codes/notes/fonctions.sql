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

CREATE OR REPLACE FUNCTION getffunction() returns table (function_name text) AS $$
    select p.proname as function_name
	from pg_proc p
	left join pg_namespace n on p.pronamespace = n.oid
	where n.nspname not in ('pg_catalog', 'information_schema') and left(proname, 1)='f';
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION getinterprfunction() returns table (function_name text) AS $$
    select p.proname as function_name
	from pg_proc p
	left join pg_namespace n on p.pronamespace = n.oid
	where n.nspname not in ('pg_catalog', 'information_schema') and left(proname, 7)='interpr';
$$ LANGUAGE sql;

create or replace function binaryLength(col text) returns table (ta text) as $$
begin
       return query execute 'select char_length(f'||col||'(null, null)::text)::text';
end;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION getTypes() returns table (type text) AS $$
	SELECT t.typname as type
	FROM pg_type t
	LEFT JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace
	WHERE (t.typrelid = 0 OR (SELECT c.relkind = 'c' FROM pg_catalog.pg_class c WHERE c.oid = t.typrelid))
	AND NOT EXISTS(SELECT 1 FROM pg_catalog.pg_type el WHERE el.oid = t.typelem AND el.typarray = t.oid)
	AND n.nspname NOT IN ('pg_catalog', 'information_schema');
$$ LANGUAGE sql;

CREATE OR REPLACE function existType(type text) returns BOOLEAN AS $$
    select exists (select 1 from pg_type where typname = type);
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION existFunction(col text) returns BOOLEAN AS $$
	select exists(
    select p.proname as function_name
	from pg_proc p
	left join pg_namespace n on p.pronamespace = n.oid
	where n.nspname not in ('pg_catalog', 'information_schema') and proname='f'||col);
$$ LANGUAGE sql;

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
