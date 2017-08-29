
\echo Use "CREATE EXTENSION pg_address" to load this file. \quit

CREATE TYPE pg_address AS (
    country VARCHAR(255),
    region VARCHAR(255),
    city VARCHAR(255),
    zip_code VARCHAR(255),
    suburb VARCHAR(255),
    street TEXT,
    num VARCHAR(255),
    lat DOUBLE PRECISION,
    lon DOUBLE PRECISION
);
