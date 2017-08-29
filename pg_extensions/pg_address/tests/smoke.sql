-- Format the output for nice TAP.
\pset format unaligned
\pset tuples_only true
\pset pager
-- Revert all changes on failure.
\set ON_ERROR_ROLLBACK 1
\set ON_ERROR_STOP true
\set QUIET 1

DROP EXTENSION IF EXISTS pg_address CASCADE;
CREATE EXTENSION pg_address;

CREATE OR REPLACE FUNCTION set_up()
RETURNS void AS $$
    DROP TABLE IF EXISTS test_address CASCADE;
    CREATE TABLE test_address (
        id SERIAL,
        address pg_address,
        PRIMARY KEY (id)
    );
$$ LANGUAGE SQL;

BEGIN;

SELECT plan(10);

SELECT set_up();
INSERT INTO test_address (address) VALUES
    (ROW('Germany', 'Berlinregio', 'Berlin', '10117', 'Haubtstr.', '57b', 'Mitte', 51.2, 4.32));
SELECT is((SELECT count(*) FROM test_address)::int, 1);
SELECT is((SELECT (address).country FROM test_address), 'Germany');
SELECT is((SELECT (address).region FROM test_address), 'Berlinregio');
SELECT is((SELECT (address).city FROM test_address), 'Berlin');
SELECT is((SELECT (address).zip_code FROM test_address), '10117');
SELECT is((SELECT (address).street FROM test_address), 'Haubtstr.');
SELECT is((SELECT (address).num FROM test_address), '57b');
SELECT is((SELECT (address).suburb FROM test_address), 'Mitte');
SELECT is((SELECT (address).lat FROM test_address), 51.2::double precision);
SELECT is((SELECT (address).lon FROM test_address), 4.32::double precision);

ROLLBACK;
