
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
    DROP TABLE IF EXISTS items CASCADE;
    CREATE TABLE items (
        id SERIAL,
        title varchar(255),
        created timestamp,
        PRIMARY KEY (id),
        CONSTRAINT title_unique UNIQUE (title)
    );
    SELECT init_partitions('items', 'DDD_YY');
$$ LANGUAGE SQL;


BEGIN;

SELECT plan(4 + 4 + 1);

-- check schema and simple insert
SELECT set_up();
INSERT INTO items (title, created) VALUES ('row1', '2016-01-10'::timestamp); 
-- schema
SELECT tables_are(
    'public',
    ARRAY['items', 'items_p_010_16']
);
SELECT has_pk('items_p_010_16', 'partition should copy PK from super');
SELECT col_is_unique('items_p_010_16', 'title', 'partition should copy unique from super');
-- data
SELECT is(
    (SELECT count(*) FROM items_p_010_16)::int,
    1
);

-- check insert of multiple values
SELECT set_up();
INSERT INTO items (title, created) VALUES ('row1', '2016-01-10'::timestamp), ('row2', '2016-01-20'::timestamp); 
SELECT is((SELECT count(*) FROM items_p_010_16)::int, 1);
SELECT is((SELECT count(*) FROM items_p_020_16)::int, 1);
SELECT is((SELECT id FROM items_p_010_16 WHERE title='row1'), 1);
SELECT is((SELECT id FROM items_p_020_16 WHERE title='row2'), 2);

-- get master table constraint
SELECT set_up();
INSERT INTO items (title, created) VALUES ('row1', '2016-01-16'::timestamp);
SELECT is(
    (SELECT get_master_constraint('items_p_016_16_title_key', 'items')),
    'title_unique'
);

ROLLBACK;
