-- webinar grafana dashboard sql
-- CPU Utilization
SELECT
    $__timeGroupAlias(snapshot_time,$__interval),
    hostname,
    1 - (CASE WHEN max(val4) >= lag(max(val4)) OVER (PARTITION BY entity ORDER BY $__timeGroup(snapshot_time,$__interval)) THEN max(val4) - lag(max(val4)) OVER (PARTITION BY entity ORDER BY $__timeGroup(snapshot_time,$__interval)) WHEN lag(max(val4)) OVER (PARTITION BY entity ORDER BY $__timeGroup(snapshot_time,$__interval)) IS NULL THEN NULL ELSE max(val4) END)/cast (
        CASE
        WHEN max(val1 + val2 + val3 + val4 + val5 + val6 + val7) >= lag(max(val1 + val2 + val3 + val4 + val5 + val6 + val7)) OVER (
            PARTITION BY entity
            ORDER BY
            $__timeGroup(snapshot_time,$__interval)
        ) THEN max(val1 + val2 + val3 + val4 + val5 + val6 + val7) - lag(max(val1 + val2 + val3 + val4 + val5 + val6 + val7)) OVER (
            PARTITION BY entity
            ORDER BY
            $__timeGroup(snapshot_time,$__interval)
        )
        WHEN lag(max(val1 + val2 + val3 + val4 + val5 + val6 + val7)) OVER (
            PARTITION BY entity
            ORDER BY
            $__timeGroup(snapshot_time,$__interval)
        ) IS NULL THEN NULL
        ELSE max(val1 + val2 + val3 + val4 + val5 + val6 + val7)
        END
    as decimal ) AS "cpu_utilization_pct"
    FROM spg_mon_os.v_proc_stat
    WHERE
    $__timeFilter(snapshot_time) AND
    entity LIKE 'cpu'
    GROUP BY 1,hostname, entity
    ORDER BY 1

-- system load
SELECT
    $__timeGroupAlias(snapshot_time,$__interval),
    hostname,
    max(load5) AS "load5"
    FROM spg_mon_os.v_proc_loadavg
    WHERE
    $__timeFilter(snapshot_time)
    GROUP BY 1,hostname
    ORDER BY 1

-- time disk read
SELECT
    $__timeGroupAlias(snapshot_time,$__interval),
    hostname,device,
    ((CASE WHEN avg(time_spent_reading_ms) >= lag(avg(time_spent_reading_ms)) OVER (PARTITION BY display_name,device ORDER BY $__timeGroup(snapshot_time,$__interval)) THEN avg(time_spent_reading_ms) - lag(avg(time_spent_reading_ms)) OVER (PARTITION BY display_name,device ORDER BY $__timeGroup(snapshot_time,$__interval)) WHEN lag(avg(time_spent_reading_ms)) OVER (PARTITION BY display_name,device ORDER BY $__timeGroup(snapshot_time,$__interval)) IS NULL THEN NULL ELSE avg(time_spent_reading_ms) END)/extract(epoch from min(snapshot_time) - lag(min(snapshot_time)) OVER (PARTITION BY display_name,device ORDER BY $__timeGroup(snapshot_time,$__interval)))) --AS "time_spent_reading_ms",
    /
    ((CASE WHEN avg(reads_total) > lag(avg(reads_total)) OVER (PARTITION BY display_name,device ORDER BY $__timeGroup(snapshot_time,$__interval)) THEN avg(reads_total) - lag(avg(reads_total)) OVER (PARTITION BY display_name,device ORDER BY $__timeGroup(snapshot_time,$__interval)) WHEN lag(avg(reads_total)) OVER (PARTITION BY display_name,device ORDER BY $__timeGroup(snapshot_time,$__interval)) IS NULL THEN NULL ELSE NULL END)/extract(epoch from min(snapshot_time) - lag(min(snapshot_time)) OVER (PARTITION BY display_name,device ORDER BY $__timeGroup(snapshot_time,$__interval)))) --AS "reads_total",
    as time_per_read
    FROM spg_mon_os.v_proc_diskstats
    WHERE
    $__timeFilter(snapshot_time)
    and time_spent_doing_io_ms > 0
    GROUP BY 1,2,3,display_name
    ORDER BY 1,2,3

-- time per disk write
SELECT
    $__timeGroupAlias(snapshot_time,$__interval),
    hostname,device,
    ((CASE WHEN avg(time_spent_writing_ms) >= lag(avg(time_spent_writing_ms)) OVER (PARTITION BY display_name,device ORDER BY $__timeGroup(snapshot_time,$__interval)) THEN avg(time_spent_writing_ms) - lag(avg(time_spent_writing_ms)) OVER (PARTITION BY display_name,device ORDER BY $__timeGroup(snapshot_time,$__interval)) WHEN lag(avg(time_spent_writing_ms)) OVER (PARTITION BY display_name,device ORDER BY $__timeGroup(snapshot_time,$__interval)) IS NULL THEN NULL ELSE avg(time_spent_writing_ms) END)/extract(epoch from min(snapshot_time) - lag(min(snapshot_time)) OVER (PARTITION BY display_name,device ORDER BY $__timeGroup(snapshot_time,$__interval)))) --AS "time_spent_writing_ms",
    /
    ((CASE WHEN avg(writes_compl) > lag(avg(writes_compl)) OVER (PARTITION BY display_name,device ORDER BY $__timeGroup(snapshot_time,$__interval)) THEN avg(writes_compl) - lag(avg(writes_compl)) OVER (PARTITION BY display_name,device ORDER BY $__timeGroup(snapshot_time,$__interval)) WHEN lag(avg(writes_compl)) OVER (PARTITION BY display_name,device ORDER BY $__timeGroup(snapshot_time,$__interval)) IS NULL THEN NULL ELSE NULL END)/extract(epoch from min(snapshot_time) - lag(min(snapshot_time)) OVER (PARTITION BY display_name,device ORDER BY $__timeGroup(snapshot_time,$__interval)))) --AS "writes_compl"
    as time_per_write
    FROM spg_mon_os.v_proc_diskstats
    WHERE
    $__timeFilter(snapshot_time)
    and time_spent_doing_io_ms > 0
    GROUP BY 1,2,3,display_name
    ORDER BY 1,2,3

-- block/cache hit ratio
with delta as (
    SELECT
    $__timeGroupAlias(snapshot_time,$__interval),
    display_name,hostname,datname,
    (CASE WHEN max(blks_read) >= lag(max(blks_read)) OVER (order by $__timeGroup(snapshot_time,$__interval)) THEN max(blks_read) - lag(max(blks_read)) OVER (order by $__timeGroup(snapshot_time,$__interval)) WHEN lag(max(blks_read)) OVER (order by $__timeGroup(snapshot_time,$__interval)) IS NULL THEN NULL ELSE max(blks_read) END)/extract(epoch from min(snapshot_time) - lag(min(snapshot_time)) OVER (order by $__timeGroup(snapshot_time,$__interval))) AS "blks_read",
    (CASE WHEN max(blks_hit) >= lag(max(blks_hit)) OVER (order by $__timeGroup(snapshot_time,$__interval)) THEN max(blks_hit) - lag(max(blks_hit)) OVER (order by $__timeGroup(snapshot_time,$__interval)) WHEN lag(max(blks_hit)) OVER (order by $__timeGroup(snapshot_time,$__interval)) IS NULL THEN NULL ELSE max(blks_hit) END)/extract(epoch from min(snapshot_time) - lag(min(snapshot_time)) OVER (order by $__timeGroup(snapshot_time,$__interval))) AS "blks_hit"
    FROM spg_mon_pg.v_pg_stat_database
    WHERE
    $__timeFilter(snapshot_time)
    GROUP BY 1,2,3,4
    )
    select time,display_name,hostname,datname,blks_hit/(blks_hit+blks_read) as blks_hit_ratio from delta
    ORDER BY 1,2

-- applications connected
SELECT
    $__timeGroupAlias(snapshot_time,$__interval),
    display_name,hostname,datname,
    max(numbackends) AS "numbackends"
    FROM spg_mon_pg.v_pg_stat_database
    WHERE
    $__timeFilter(snapshot_time)
    GROUP BY 1,display_name,hostname,datname
    ORDER BY 1,2    

-- tup inserted
SELECT
    $__timeGroupAlias(snapshot_time,$__interval),
    display_name,hostname,datname,
    (CASE WHEN max(tup_inserted) >= lag(max(tup_inserted)) OVER (PARTITION BY display_name ORDER BY $__timeGroup(snapshot_time,$__interval)) THEN max(tup_inserted) - lag(max(tup_inserted)) OVER (PARTITION BY display_name ORDER BY $__timeGroup(snapshot_time,$__interval)) WHEN lag(max(tup_inserted)) OVER (PARTITION BY display_name ORDER BY $__timeGroup(snapshot_time,$__interval)) IS NULL THEN NULL ELSE max(tup_inserted) END)/extract(epoch from min(snapshot_time) - lag(min(snapshot_time)) OVER (PARTITION BY display_name ORDER BY $__timeGroup(snapshot_time,$__interval))) AS "tup_inserted"
    FROM spg_mon_pg.v_pg_stat_database
    WHERE
    $__timeFilter(snapshot_time) 
    GROUP BY 1,display_name,hostname,datname
    ORDER BY 1

-- tup returned
SELECT
    $__timeGroupAlias(snapshot_time,$__interval),
    display_name,hostname,datname,
    (CASE WHEN max(tup_returned) >= lag(max(tup_returned)) OVER (PARTITION BY display_name ORDER BY $__timeGroup(snapshot_time,$__interval)) THEN max(tup_returned) - lag(max(tup_returned)) OVER (PARTITION BY display_name ORDER BY $__timeGroup(snapshot_time,$__interval)) WHEN lag(max(tup_returned)) OVER (PARTITION BY display_name ORDER BY $__timeGroup(snapshot_time,$__interval)) IS NULL THEN NULL ELSE max(tup_returned) END)/extract(epoch from min(snapshot_time) - lag(min(snapshot_time)) OVER (PARTITION BY display_name ORDER BY $__timeGroup(snapshot_time,$__interval))) AS "tup_returned"
    FROM spg_mon_pg.v_pg_stat_database
    WHERE
    $__timeFilter(snapshot_time) 
    GROUP BY 1,display_name,hostname,datname
    ORDER BY 1

-- lock contentions
select
    time_bucket_gapfill('$__interval',snapshot_time) as time,
    hostname,dbname,
    count(distinct blocked_pid::text || blocking_pid::text) 
    as num_lock_contentions
    from spg_mon_pg.v_pg_mon_lockwaits
    where
    $__timeFilter(snapshot_time) and
        datname is not null 
    group by 1,2,3

-- slow queries
with delta as (
    select snapshot_time,display_name,dbname,queryid,
        case when calls > lag(calls) over (partition by display_name,dbname,queryid order by snapshot_time) then
        mean_exec_time
        else null
        end as mean_exec_time
    from spg_mon_pg.v_pg_stat_statements
    where
        $__timeFilter(snapshot_time) and
        datname is not null 
        and mean_exec_time > 1000
    ) select
    time_bucket_gapfill('$__interval',snapshot_time) as time,
    display_name,dbname,
    locf(count(distinct queryid)) as num_querie_slow_1s 
    from delta
    where $__timeFilter(snapshot_time)
    group by 1,2,3
    order by 1