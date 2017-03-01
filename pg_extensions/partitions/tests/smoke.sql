
-- Format the output for nice TAP.
\pset format unaligned
\pset tuples_only true
\pset pager
-- Revert all changes on failure.
\set ON_ERROR_ROLLBACK 1
\set ON_ERROR_STOP true
\set QUIET 1

DROP EXTENSION IF EXISTS partitions CASCADE;
CREATE EXTENSION partitions;


CREATE OR REPLACE FUNCTION set_up()
RETURNS void AS $$
    DROP TABLE IF EXISTS items_weekly CASCADE;
    CREATE TABLE items_weekly (
        id SERIAL,
        title varchar(255),
        created timestamp,
        PRIMARY KEY (id),
        CONSTRAINT title_unique_weekly UNIQUE (title)
    );
    SELECT init_partitions('items_weekly', 'YYYY_WW');

    DROP TABLE IF EXISTS items_quarter CASCADE;
    CREATE TABLE items_quarter (
        id SERIAL,
        title varchar(255),
        created timestamp,
        PRIMARY KEY (id),
        CONSTRAINT title_unique_quarter UNIQUE (title)
    );
    SELECT init_partitions('items_quarter', 'YYYY_Q');
$$ LANGUAGE SQL;


BEGIN;

SELECT plan(7 + 12 + 2);

-- check schema and simple insert
SELECT set_up();
INSERT INTO items_weekly (title, created) VALUES ('row1', '2016-01-10'::timestamp);
INSERT INTO items_quarter (title, created) VALUES ('row2', '2016-04-10'::timestamp);

-- schema
SELECT tables_are(
    'public',
    ARRAY['items_weekly', 'items_weekly_p_2016_02', 'items_quarter', 'items_quarter_p_2016_2']
);
SELECT has_pk('items_weekly_p_2016_02', 'partition should copy PK from super');
SELECT has_pk('items_quarter_p_2016_2', 'partition should copy PK from super');
SELECT col_is_unique('items_weekly_p_2016_02', 'title', 'partition should copy unique from super');
SELECT col_is_unique('items_quarter_p_2016_2', 'title', 'partition should copy unique from super');
-- data
SELECT is(
    (SELECT count(*) FROM items_weekly_p_2016_02)::int,
    1
);
SELECT is(
    (SELECT count(*) FROM items_quarter_p_2016_2)::int,
    1
);

-- check insert of multiple values
SELECT set_up();
INSERT INTO items_weekly (title, created) VALUES ('row1', '2017-01-01'::timestamp), ('row2', '2017-01-07'::timestamp), ('row3', '2017-06-13'::timestamp), ('row4', '2017-06-17'::timestamp);
INSERT INTO items_quarter (title, created) VALUES ('row1', '2017-04-01'::timestamp), ('row2', '2017-06-30'::timestamp), ('row3', '2017-02-21'::timestamp), ('row4', '2017-03-22'::timestamp);
SELECT is((SELECT count(*) FROM items_weekly_p_2017_01)::int, 2);
SELECT is((SELECT count(*) FROM items_weekly_p_2017_24)::int, 2);
SELECT is((SELECT count(*) FROM items_quarter_p_2017_1)::int, 2);
SELECT is((SELECT count(*) FROM items_quarter_p_2017_2)::int, 2);
SELECT is((SELECT count(*) FROM items_weekly_p_2017_01 WHERE title='row1')::int, 1);
SELECT is((SELECT count(*) FROM items_weekly_p_2017_01 WHERE title='row2')::int, 1);
SELECT is((SELECT count(*) FROM items_weekly_p_2017_24 WHERE title='row3')::int, 1);
SELECT is((SELECT count(*) FROM items_weekly_p_2017_24 WHERE title='row4')::int, 1);
SELECT is((SELECT count(*) FROM items_quarter_p_2017_1 WHERE title='row3')::int, 1);
SELECT is((SELECT count(*) FROM items_quarter_p_2017_1 WHERE title='row4')::int, 1);
SELECT is((SELECT count(*) FROM items_quarter_p_2017_2 WHERE title='row1')::int, 1);
SELECT is((SELECT count(*) FROM items_quarter_p_2017_2 WHERE title='row2')::int, 1);

-- get master table constraint
SELECT set_up();
INSERT INTO items_weekly (title, created) VALUES ('row1', '2016-01-16'::timestamp);
INSERT INTO items_quarter (title, created) VALUES ('row1', '2016-01-16'::timestamp);
SELECT is(
    (SELECT get_master_constraint('items_weekly_p_2016_03_title_key', 'items_weekly')),
    'title_unique_weekly'
);
SELECT is(
    (SELECT get_master_constraint('items_quarter_p_2016_1_title_key', 'items_quarter')),
    'title_unique_quarter'
);

ROLLBACK;
