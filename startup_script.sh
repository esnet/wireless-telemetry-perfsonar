#!/bin/bash

# wait for postgres...
if ! nc -z localhost 5432
then
  echo "Waiting for Postgres..."
  exit 1
fi

# Measure every 30s. Begin loop with this to allow for warmup after postgres comes up
sleep ${REPORT_INTERVAL}

echo "Logging Environment Configuration..."
echo OTEL_EXPORTER_OTLP_ENDPOINT ${OTEL_EXPORTER_OTLP_ENDPOINT}
echo OTEL_EXPORTER_OTLP_HEADERS ${OTEL_EXPORTER_OTLP_HEADERS}
echo OTEL_SERVICE_NAME ${OTEL_SERVICE_NAME}
echo OTEL_METRICS_EXPORTER ${OTEL_METRICS_EXPORTER}
echo OTEL_LOGS_EXPORTER ${OTEL_LOGS_EXPORTER}
echo OTEL_TRACES_EXPORTER ${OTEL_TRACES_EXPORTER}
echo
echo OTEL_REPORT_TEMP_CMD ${OTEL_REPORT_TEMP_CMD}
echo OTEL_REPORT_VOLTS_CMD ${OTEL_REPORT_VOLTS_CMD}
echo OTEL_REPORT_CLOCK_CMD ${OTEL_REPORT_CLOCK_CMD}
echo OTEL_REPORT_BOOT_ENVIRONMENT_CMD ${OTEL_REPORT_BOOT_ENVIRONMENT_CMD}
echo OTEL_REPORT_BATTERY_VOLTS_CMD ${OTEL_REPORT_BATTERY_VOLTS_CMD}
echo OTEL_REPORT_GPS_CMD ${OTEL_REPORT_GPS_CMD}
echo
echo PERFSONAR_TEMPLATE_URL ${PERFSONAR_TEMPLATE_URL}
echo PERFSONAR_RUN_LATENCY ${PERFSONAR_RUN_LATENCY}
echo PERFSONAR_LATENCY_DEST ${PERFSONAR_LATENCY_DEST}
echo PERFSONAR_RUN_TRACE ${PERFSONAR_RUN_TRACE}
echo PERFSONAR_TRACE_DEST ${PERFSONAR_TRACE_DEST}
echo PERFSONAR_RUN_RTT ${PERFSONAR_RUN_RTT}
echo PERFSONAR_RTT_DEST ${PERFSONAR_RTT_DEST}
echo PERFSONAR_ARCHIVE_URL ${PERFSONAR_ARCHIVE_URL}
echo PERFSONAR_ARCHIVE_AUTHORIZATION ${PERFSONAR_ARCHIVE_AUTHORIZATION}
echo
echo SYNC_TIME_AND_BOOT_SCHEDULE ${SYNC_TIME_AND_BOOT_SCHEDULE}
echo SYNC_TIME_AND_BOOT_SCHEDULE_CMD ${SYNC_TIME_AND_BOOT_SCHEDULE_CMD}
echo
echo SHUTDOWN_AFTER_REPORT ${SHUTDOWN_AFTER_REPORT}
echo REPORT_INTERVAL ${REPORT_INTERVAL}


# being super-explicit. These are configurations for the opentelemetry-instrument command below
export OTEL_EXPORTER_OTLP_ENDPOINT=${OTEL_EXPORTER_OTLP_ENDPOINT}
export OTEL_EXPORTER_OTLP_HEADERS=${OTEL_EXPORTER_OTLP_HEADERS}
export OTEL_TRACES_EXPORTER=${OTEL_TRACES_EXPORTER}
export OTEL_LOGS_EXPORTER=${OTEL_LOGS_EXPORTER}
export OTEL_METRICS_EXPORTER=${OTEL_METRICS_EXPORTER}

# report device metrics
source /wireless_telemetry_venv/bin/activate
opentelemetry-instrument python /wireless_telemetry.py
# deactivate venv so pscheduler works
deactivate

# perform perfsonar tests
# do this "raw" with pScheduler in this context
# the device is assumed to be low-power and will power off when this script is complete
if (( $PERFSONAR_RUN_LATENCY ))
then
    pscheduler task --archive '{ "archiver": "http", "data": { "schema": 2, "_url": "'"${PERFSONAR_ARCHIVE_URL}"'", "op": "put", "_headers": { "x-ps-observer": "'"${THE_HOSTNAME}"'", "authorization": "'"${PERFSONAR_ARCHIVE_AUTHORIZATION}"'", "content-type": "application/json" } } }' latency --dest ${PERFSONAR_LATENCY_DEST}
fi

if (( $PERFSONAR_RUN_RTT ))
then
    pscheduler task --archive '{ "archiver": "http", "data": { "schema": 2, "_url": "'"${PERFSONAR_ARCHIVE_URL}"'", "op": "put", "_headers": { "x-ps-observer": "'"${THE_HOSTNAME}"'", "authorization": "'"${PERFSONAR_ARCHIVE_AUTHORIZATION}"'", "content-type": "application/json" } } }' rtt --dest ${PERFSONAR_RTT_DEST}
fi

if (( $PERFSONAR_DO_TRACE ))
then
    pscheduler task --archive '{ "archiver": "http", "data": { "schema": 2, "_url": "'"${PERFSONAR_ARCHIVE_URL}"'", "op": "put", "_headers": { "x-ps-observer": "'"${THE_HOSTNAME}"'", "authorization": "'"${PERFSONAR_ARCHIVE_AUTHORIZATION}"'", "content-type": "application/json" } } }' trace --dest ${PERFSONAR_TRACE_DEST}
fi

if (( $SYNC_TIME_AND_SCHEDULE ))
then
    $SYNC_TIME_AND_SCHEDULE_CMD
fi

# after report, shut down

if (( $SHUTDOWN_AFTER_REPORT ))
then
    shutdown -h now
fi

# non-zero exit to make sure we're restarted by supervisor
exit 1
