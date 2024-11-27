
CREATE USER grafanareader WITH PASSWORD 'itgain';

create schema observability;

create table observability.hist_pg_stat_database as select current_timestamp as time,* from pg_stat_database;

GRANT USAGE ON SCHEMA observability TO grafanareader;

GRANT SELECT ON observability.hist_pg_stat_database TO grafanareader;

select * from observability.hist_pg_stat_database;

select create_hypertable('observability.hist_pg_stat_database', 'time', migrate_data => TRUE, chunk_time_interval => INTERVAL '15m', if_not_exists => TRUE);

alter table observability.hist_pg_stat_database set (timescaledb.compress, timescaledb.compress_orderby = 'time',timescaledb.compress_segmentby = 'datname');

SELECT add_compression_policy('observability.hist_pg_stat_database', INTERVAL '5m');

SELECT add_retention_policy('observability.hist_pg_stat_database', INTERVAL '7d');


/* bash
while true; do docker compose exec -t s4dbs_postgres psql -U postgres -d postgres -c "insert into observability.hist_pg_stat_database select current_timestamp as time,* from pg_stat_database;"; sleep 60;done
*/

select * from observability.hist_pg_stat_database