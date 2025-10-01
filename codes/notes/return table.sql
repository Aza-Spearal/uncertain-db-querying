select format('%s', sel);

left('abcde', 2) → ab
right('abcde', 2) → de

ltrim('zzzytest', 'xyz') → test
rtrim('testxxzx', 'xyz') → test
btrim('xyxtrimyyx', 'xyz') → trim

strpos('high', 'ig') → 2
substr('alphabet', 3) → phabet
substr('alphabet', 3, 2) → ph

starts_with ( string text, prefix text ) → boolean
starts_with('alphabet', 'alph') → t

format('Hello %s, %1$s', 'World') → Hello World, World

/*=======================================================
4 possibilités: 1 paramètre | 3 paramètres,     return table | return setof.
privilégié le 1 paramèter car on rencoie tout le string d'un coup
*/

nom colonne:
--retourne table X
select * from query('select flevel(r.level, 2) as level from r');

--retourne query5
select query('select flevel(r.level, 2) as level from r');


create or replace function query5 (tab text) returns table (loli bit(2)) as $$
begin
	return query execute tab;
end;
$$ LANGUAGE plpgsql;

select query5('select flevel(r.level, 2) from r') as level;



CREATE or replace FUNCTION getfi(n text) RETURNS SETOF bit(2) AS $$
    begin
    return query EXECUTE n;
    end;
$$ LANGUAGE plpgSQL;

select getfi('select flevel(level,2) from r') as level;


CREATE or replace FUNCTION fonct() RETURNS SETOF text AS $BODY$
BEGIN
    RETURN QUERY SELECT x
                   FROM functionTable
                  WHERE name='fB';
    --RETURN;
    --NOT FOUND
 END;
$BODY$ LANGUAGE plpgsql;

create or replace function query5 (attr text, val text, tab text) returns table (loli bit(2)) as $$
begin
	return query execute 'select f'||attr||'('||attr||', '||val||') as '||attr||' from '||tab;
end;
$$ LANGUAGE plpgsql;

select * from query5('level', '2', 'r');


create or replace function query7 (attr text, val text, tab text) returns setof bit(2) as $$
begin
	return query execute 'select f'||attr||'('||attr||', '||val||') as '||attr||' from '||tab;
end;
$$ LANGUAGE plpgsql;

select * from query7('level', '2', 'r');



CREATE or replace FUNCTION getfp(n text) RETURNS SETOF record AS $$
    select flevel(level,2), fsize(size,2) from r;
$$ LANGUAGE SQL;

select * from getfp('r') as (level bit(2), size bit(2));


--NE MONTRE QUE LA PREMIERE COLONNE
create or replace function query7 (in tab text, out result bit(2)) as $$
	select flevel(level, 2) as level from r;
$$ LANGUAGE sql;



--OK========================================================
--Il faudrait créer pleins de fonctions en fonction du nombre de paramètres donnés.
create or replace function query(lv numeric, gen char(1), siz int) returns table (level bit(2), gender bit, size bit(2)) as $$
begin
	return query
    select fA(r.level, lv), fB(r.gender, gen), fC(r.size, siz) from r;
end;
$$ LANGUAGE plpgsql;

select level, gender, size from query(2, 'F', 70);
select level from query(2, 'F', 70); --MARCHE AUSSI !!!


--MARCHE PAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
create or replace function query4 (lv numeric, gen char(1), siz int, tab text) returns table (level bit(2), gender bit, size bit(2)) as $$
begin
	return query execute 'select fA(foo.level, '||lv||') as level, fB(foo.gender, '||gen||') as gender, fC(foo.size, '||siz||') as size from '||tab||' as foo';
end;
$$ LANGUAGE plpgsql;

select * from query4(2, 'F', 45, 'r');
