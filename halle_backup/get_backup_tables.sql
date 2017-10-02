CREATE SCHEMA IF NOT EXISTS backup;
CREATE TABLE IF NOT EXISTS backup.status (
    table_name text,
    n_tup_ins bigint,
    n_tup_upd bigint,
    n_tup_del bigint,
    n_tup_hot_upd bigint,
    dt timestamp,
    CONSTRAINT backup_status_pk PRIMARY KEY (table_name) 
);

CREATE OR REPLACE FUNCTION backup.get_tables()
RETURNS TABLE(table_name text) AS
$$
    SELECT pst.schemaname || '.' || pst.relname 
    FROM pg_stat_user_tables pst
    LEFT JOIN backup.status st ON (
        st.table_name = pst.schemaname || '.' || pst.relname
    )
    WHERE
        st.table_name IS NULL OR
        pst.n_tup_ins != st.n_tup_ins OR
        pst.n_tup_upd != st.n_tup_upd OR
        pst.n_tup_del != st.n_tup_del OR
        pst.n_tup_hot_upd != st.n_tup_hot_upd;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION backup.save_state(table_name_ text)
RETURNS VOID AS
$$
DECLARE 
    st_ pg_stat_user_tables;
BEGIN
    SELECT * INTO st_
    FROM pg_stat_user_tables
    WHERE schemaname || '.' || relname = table_name_;

    INSERT INTO backup.status AS st
    VALUES (
        st_.schemaname || '.' || st_.relname,
        st_.n_tup_ins,
        st_.n_tup_upd,
        st_.n_tup_del,
        st_.n_tup_hot_upd,
        NOW()
    )
    ON CONFLICT ON CONSTRAINT backup_status_pk
    DO UPDATE SET
        n_tup_ins = st_.n_tup_ins,
        n_tup_upd = st_.n_tup_upd,
        n_tup_del = st_.n_tup_del,
        n_tup_hot_upd = st_.n_tup_hot_upd
    WHERE
        st.table_name = table_name_;
END 
$$ LANGUAGE PLPGSQL;
