
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
        CONSTRAINT title_unique UNIQUE (title)
    );
    SELECT init_partitions('items_weekly', 'YYYY_WW');
$$ LANGUAGE SQL;


BEGIN;

SELECT plan(4 + 4 + 1);

-- check schema and simple insert
SELECT set_up();
INSERT INTO items_weekly (title, created) VALUES ('row1', '2016-01-10'::timestamp);
-- schema
SELECT tables_are(
    'public',
    ARRAY['items_weekly', 'items_weekly_p_2016_02']
);
SELECT has_pk('items_weekly_p_2016_02', 'partition should copy PK from super');
SELECT col_is_unique('items_weekly_p_2016_02', 'title', 'partition should copy unique from super');
-- data
SELECT is(
    (SELECT count(*) FROM items_weekly_p_2016_02)::int,
    1
);

-- check insert of multiple values
SELECT set_up();
INSERT INTO items_weekly (title, created) VALUES ('row1', '2016-01-10'::timestamp), ('row2', '2016-01-20'::timestamp);
SELECT is((SELECT count(*) FROM items_weekly_p_2016_02)::int, 1);
SELECT is((SELECT count(*) FROM items_weekly_p_2016_03)::int, 1);
SELECT is((SELECT id FROM items_weekly_p_2016_02 WHERE title='row1'), 1);
SELECT is((SELECT id FROM items_weekly_p_2016_03 WHERE title='row2'), 2);

-- get master table constraint
SELECT set_up();
INSERT INTO items_weekly (title, created) VALUES ('row1', '2016-01-16'::timestamp);
SELECT is(
    (SELECT get_master_constraint('items_weekly_p_2016_03_title_key', 'items_weekly')),
    'title_unique'
);

ROLLBACK;
