FROM timescale/timescaledb-postgis:latest-pg12
COPY initdb.sh /docker-entrypoint-initdb.d/003_initdb.sh
COPY data_model.sql /docker-entrypoint-initdb.d/004.sql
COPY timescaledb.sql /docker-entrypoint-initdb.d/005.sql
COPY compatibility.sql /docker-entrypoint-initdb.d/006.sql