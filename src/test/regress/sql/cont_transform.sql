CREATE STREAM ct_stream0 (x int);
CREATE STREAM ct_stream1 (x int);

CREATE CONTINUOUS VIEW ct0 AS SELECT x::int, count(*) FROM ct_stream0 GROUP BY x;
CREATE CONTINUOUS TRANSFORM ct1 AS SELECT x::int % 4 AS x FROM ct_stream1 WHERE x > 10 AND x < 50 THEN EXECUTE PROCEDURE pipeline_stream_insert('ct_stream0');

CREATE TABLE ct2 (x int);
CREATE OR REPLACE FUNCTION ct_tg()
RETURNS trigger AS
$$
BEGIN
 INSERT INTO ct2 (x) VALUES (NEW.x);
 RETURN NEW;
END;
$$
LANGUAGE plpgsql;
CREATE CONTINUOUS TRANSFORM ct3 AS SELECT x::int FROM ct_stream1 WHERE x % 2 = 0 THEN EXECUTE PROCEDURE ct_tg();

INSERT INTO ct_stream1 (x) SELECT generate_series(0, 100) AS x;

SELECT * FROM ct0 ORDER BY x;
SELECT * FROM ct2 ORDER BY x;

DROP FUNCTION ct_tg() CASCADE;
DROP TABLE ct2;
DROP CONTINUOUS TRANSFORM ct1;
DROP CONTINUOUS VIEW ct0;
DROP STREAM ct_stream0;
DROP STREAM ct_stream1;

-- Stream-table JOIN
CREATE TABLE ct_t (x integer, s text);
INSERT INTO ct_t (x, s) VALUES (0, 'zero');
INSERT INTO ct_t (x, s) VALUES (1, 'one');

CREATE STREAM ct_s0 (x text);
CREATE STREAM ct_s1 (x int);
CREATE CONTINUOUS VIEW ct_v AS SELECT x::text FROM ct_s0;
CREATE CONTINUOUS TRANSFORM ct AS
  SELECT t.s AS x FROM ct_s1 s JOIN ct_t t on t.x = s.x::integer
  THEN EXECUTE PROCEDURE pipeline_stream_insert('ct_s0');

INSERT INTO ct_s1 (x) VALUES (0), (1);
INSERT INTO ct_s1 (x) VALUES (0), (2);

SELECT * FROM ct_v ORDER BY x;

DROP CONTINUOUS TRANSFORM ct;
DROP CONTINUOUS VIEW ct_v;
DROP TABLE ct_t;
DROP STREAM ct_s1;
DROP STREAM ct_s0;

CREATE STREAM ct_s (x int, y text);

CREATE CONTINUOUS TRANSFORM ct_invalid AS SELECT y, x FROM ct_s THEN EXECUTE PROCEDURE pipeline_stream_insert('ct_s');
CREATE CONTINUOUS TRANSFORM ct_invalid AS SELECT x, x AS y FROM ct_s THEN EXECUTE PROCEDURE pipeline_stream_insert('ct_s');
CREATE CONTINUOUS TRANSFORM ct_valid AS SELECT x, 'a'::text FROM ct_s THEN EXECUTE PROCEDURE pipeline_stream_insert('ct_s');

DROP STREAM ct_s CASCADE;

CREATE STREAM ct_s0 (x int);
CREATE STREAM ct_s1 (x int);

CREATE CONTINUOUS TRANSFORM ct_t AS SELECT x % 4 AS x FROM ct_s0 THEN EXECUTE PROCEDURE pipeline_stream_insert('ct_s1');
CREATE CONTINUOUS VIEW ct_v0 AS SELECT x FROM ct_s1;
CREATE CONTINUOUS VIEW ct_v1 AS SELECT x FROM output_of('ct_t');

INSERT INTO ct_s0 SELECT generate_series(1, 10) x;

SELECT * FROM ct_v0;
SELECT * FROM ct_v1;

DROP STREAM ct_s0 CASCADE;
