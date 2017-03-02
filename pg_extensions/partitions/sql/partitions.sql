
\echo Use "CREATE EXTENSION partitions" to load this file. \quit

-- util functions
CREATE OR REPLACE FUNCTION table_name(_master_table name, _mask text, _created timestamp)
RETURNS text AS $$
    SELECT format('%s_p_%s', _master_table, to_char(_created, _mask));
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION create_partition(_master_table name, _mask text, _created timestamp)
RETURNS void AS $$
DECLARE
    _table_name text;
    _table_created boolean;
BEGIN
    _table_name := table_name(_master_table, _mask, _created);

    BEGIN
        EXECUTE format(
            'CREATE TABLE %I (LIKE %I INCLUDING ALL);',
            _table_name, _master_table
        );
        _table_created := true;
        RAISE NOTICE 'Table % was created', _table_name;
    EXCEPTION
        WHEN duplicate_table THEN
            _table_created := false;
            RAISE NOTICE 'Table already exists';
    END;
    
    IF _table_created THEN
        PERFORM create_table_constraint(_table_name, _mask, _created);
        EXECUTE format(
            'ALTER TABLE %I
             INHERIT %I
             ;',
            _table_name, _master_table
        );
        RAISE NOTICE 'Constraints for % were created', _table_name;
    END IF;
END;
$$ LANGUAGE plpgsql VOLATILE;

CREATE OR REPLACE FUNCTION create_table_constraint(_table_name name, _mask text, _create timestamp)
RETURNS void AS $$
DECLARE
    _current date;
    _start_dt date;
    _end_dt date;
BEGIN
    SELECT _create::date INTO _current;

    CASE _mask
        WHEN 'YYYY_WW' THEN
            SELECT date_trunc('year', _current) + make_interval(0, 0, EXTRACT (DOY FROM _current)::int / 7) INTO _start_dt;
            SELECT _start_dt + INTERVAL '7 days' INTO _end_dt;
        WHEN 'YYYY_Q' THEN
            SELECT date_trunc('quarter', _current) INTO _start_dt;
            SELECT date_trunc('quarter', _start_dt + INTERVAL '92 days') INTO _end_dt;
        ELSE
            RAISE EXCEPTION 'Not supported mask %', _mask
                USING HINT = 'Correct masks: YYYY_WW, YYYY_Q',
                      ERRCODE='invalid_parameter_value';
    END CASE;

    EXECUTE format(
        'ALTER TABLE %I
         ADD CHECK (created >= %L AND created < %L)
         ;',
        _table_name, _start_dt, _end_dt
    );
END;
$$ LANGUAGE plpgsql VOLATILE;

CREATE OR REPLACE FUNCTION init_partitions(_master_table name, _mask text)
RETURNS void AS $$
DECLARE
    _row_trigger_name text;
BEGIN
    IF NOT (_mask IN ('YYYY_Q', 'YYYY_WW')) THEN
        RAISE EXCEPTION 'Not supported mask %', _mask
            USING HINT = 'Correct masks: YYYY_WW, YYYY_Q',
                  ERRCODE='invalid_parameter_value';
    END IF;

    _row_trigger_name := format('trigget_row_%s', _master_table);

    EXECUTE format(
        'DROP TRIGGER IF EXISTS %I ON %I;',
        _row_trigger_name, _master_table
    );
    EXECUTE format(
        'CREATE TRIGGER %I
         BEFORE INSERT ON %I
         FOR EACH ROW EXECUTE PROCEDURE partition_row_insert(%L);
        ',
        _row_trigger_name, _master_table, _mask
    );
    RAISE NOTICE 'Row trigger % was created for %', _row_trigger_name, _master_table;
END;
$$ LANGUAGE plpgsql VOLATILE;

CREATE OR REPLACE FUNCTION get_master_constraint(_constraint_name name, _master_table name)
RETURNS name AS $$
    -- this functions returns name of constrain of the master table.
    -- It matchs constraint by master table name and list of fields that are the constraint.
    -- constraint -> index -> index -> cnstraint
    SELECT master_constraint.conname
        FROM pg_index master_ind
        LEFT JOIN pg_index child_ind ON child_ind.indkey=master_ind.indkey
        LEFT JOIN pg_class ON pg_class.oid=master_ind.indrelid
        LEFT JOIN pg_constraint child_constraint ON child_constraint.conindid=child_ind.indexrelid
        LEFT JOIN pg_constraint master_constraint ON master_constraint.conindid=master_ind.indexrelid
        WHERE master_ind.indisunique=true
            AND child_constraint.conname=_constraint_name
            AND pg_class.relname=_master_table
        LIMIT 1;
$$ LANGUAGE sql;

-- trigger functions
CREATE OR REPLACE FUNCTION partition_row_insert()
RETURNS TRIGGER AS $$
DECLARE
    _table_name text;
    _mask text;
    _query text;
    _exc_constraint name;
    _new_exc_constraint name;
BEGIN
    _mask := TG_ARGV[0];
    _query := 'INSERT INTO %I VALUES ($1.*);';
    _table_name := table_name(TG_TABLE_NAME, _mask, NEW.created);
    BEGIN
        EXECUTE format(_query, _table_name) USING NEW;
    EXCEPTION
        WHEN undefined_table THEN
            PERFORM create_partition(TG_TABLE_NAME, _mask, NEW.created);
            EXECUTE format(_query, _table_name) USING NEW;
        WHEN unique_violation THEN
            GET STACKED DIAGNOSTICS _exc_constraint=CONSTRAINT_NAME;
            SELECT get_master_constraint(_exc_constraint, TG_TABLE_NAME) INTO _new_exc_constraint;
            RAISE unique_violation USING
                TABLE=TG_TABLE_NAME,
                CONSTRAINT=_new_exc_constraint,
                MESSAGE=format('duplicate key value violates unique constraint "%I"', _new_exc_constraint);
    END;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;
