SELECT * FROM create_hypertable('measurements_stationary','ts');

ALTER TABLE measurements_stationary SET (
    timescaledb.compress,
    timescaledb.compress_segmentby='sensor_configuration_id'
);

-- SELECT add_compress_chunks_policy('measurements_stationary', INTERVAL '1 week');

SELECT * FROM create_hypertable('measurements_mobile','ts');

ALTER TABLE measurements_mobile SET (
    timescaledb.compress,
    timescaledb.compress_segmentby='sensor_configuration_id'
);

-- SELECT add_compress_chunks_policy('measurements_mobile', INTERVAL '1 week');

CREATE VIEW measurements_stationary_daily
WITH (timescaledb.continuous) AS
SELECT
    sensor_configuration_id,
    time_bucket('1 day', ts) as hour,
    min(value),
    max(value),
    count(*),
    avg(value)
FROM
    measurements_stationary
GROUP BY
    hour, sensor_configuration_id
;