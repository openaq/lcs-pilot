CREATE OR REPLACE  VIEW measurements_view as
SELECT
    station_name as location,
    value,
    unit,
    measurand as parameter,
    country,
    city,
    null::json as data,
    organization as source_name,
    ts as date_utc,
    stations.geog as coordinates,
    organization_type as source_type,
    false as mobile
FROM
    measurements_stationary
    JOIN sensors USING (sensor_id)
    JOIN measurands USING (measurand_id)
    JOIN stations USING (station_id)
;


CREATE OR REPLACE FUNCTION measurements_trigger_func() RETURNS trigger as $$
DECLARE
station stations%ROWTYPE;
sensor sensors%ROWTYPE;
_measurand measurands%ROWTYPE;
measurement measurements_stationary%ROWTYPE;
BEGIN
    INSERT INTO stations (
        station_name,
        geog,
        mobile,
        city,
        country,
        organization,
        organization_type
    ) VALUES (
        NEW.location,
        NEW.coordinates,
        NEW.mobile,
        NEW.city,
        NEW.country,
        NEW.source_name,
        NEW.source_type
    )
    ON CONFLICT (station_name) DO
    UPDATE SET station_name='' WHERE FALSE
    RETURNING * INTO station;
    IF station IS NULL THEN
        SELECT * INTO  station
        FROM stations
        WHERE stations.station_name=NEW.location;
    END IF;

    INSERT INTO measurands (
        measurand,
        unit
    ) VALUES (
        NEW.parameter,
        NEW.unit
    )
    ON CONFLICT (measurand, unit) DO
    UPDATE SET measurand='' WHERE FALSE
    RETURNING * INTO _measurand;
    IF _measurand IS NULL THEN
        SELECT * INTO  _measurand
        FROM measurands
        WHERE measurands.measurand=NEW.parameter AND unit=NEW.unit;
    END IF;

    INSERT INTO sensors (
        station_id,
        measurand_id
    ) VALUES (
        station.station_id,
        _measurand.measurand_id
    )
    ON CONFLICT (station_id, measurand_id) DO
    UPDATE SET station_id=1 WHERE FALSE
    RETURNING * INTO sensor;
    IF sensor IS NULL THEN
        SELECT * INTO  sensor FROM sensors
        WHERE
            sensors.station_id=station.station_id
            AND sensors.measurand_id=_measurand.measurand_id;
    END IF;

INSERT INTO measurements_stationary (
    sensor_id,
    ts,
    value
) VALUES (
    sensor.sensor_id,
    NEW.date_utc,
    NEW.value
)
ON CONFLICT (sensor_id, ts) DO NOTHING;

RETURN NULL;
END;
$$ LANGUAGE PLPGSQL;


CREATE TRIGGER measurements_insert
    INSTEAD OF INSERT ON measurements_view
    FOR EACH ROW
    EXECUTE PROCEDURE measurements_trigger_func();
