drop table IF EXISTS r;

create table r (level numeric, gender char, size int);
insert into r values (1.4, 'F', 73);
insert into r values (1.5, 'F', null);
insert into r values (3.2, 'M', 72);
insert into r values (3.5, 'F', 76);
insert into r values (40, 'F', 100);


drop table IF EXISTS s;
create table s (level numeric, gender char);
insert into s values (1, 'F');
insert into s values (1.8, 'M');
insert into s values (1.6, 'F');
insert into s values (3.5, 'M');


CREATE OR REPLACE FUNCTION flevel(x numeric, y numeric) RETURNS bit AS $$
	SELECT
    CASE
      WHEN (x=y) or ((0<=x and x<2) AND (0<=y and y<2)) THEN b'11'
      WHEN ((2<=x and x<5) AND (2<=y and y<5)) THEN b'10'
      WHEN ((0<=x and x<2) AND (2<=y and y<5)) or
	  	   ((2<=x and x<5) AND (0<=y and y<2)) THEN b'01'
      ELSE b'00'
    END
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION fgender(x char, y char) RETURNS bit AS $$
    SELECT
	CASE
        WHEN (x=y) or (x is null and y is null) then b'1'
        else b'0'
    END
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION fsize(x int, y int) RETURNS bit AS $$
    SELECT
	CASE
		WHEN (x=y and x is not null) or ((x between 70 and 80) AND (y between 70 and 80)) then b'11'
     	WHEN (x is not null or y is not null) then b'10'
        else b'00'
    END
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION interprlevel(b bit) RETURNS boolean AS $$
    SELECT
    CASE
      WHEN b='11' or b='10' THEN true
      ELSE false
    END
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION interprgender(b bit) RETURNS boolean AS $$
    SELECT
    CASE
      WHEN b='1' THEN true
      ELSE false
    END
$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION interprsize(b bit) RETURNS boolean AS $$
    SELECT
    CASE
      WHEN b='11' THEN true
      ELSE false
    END
$$ LANGUAGE sql;
