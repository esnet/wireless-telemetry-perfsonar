#!/bin/bash

# report device metrics
source /wireless_telemetry_venv/bin/activate && opentelemetry-instrument \
  --traces_exporter console,otlp \
  --metrics_exporter console,otlp \
  --logs_exporter console,otlp \
  --service_name wireless-telemetry \
  /wireless_telemetry_venv/bin/python /wireless_telemetry.py

# perform perfsonar tests
if (( $PERFSONAR_DO_LATENCY ))
then
cat >/owamp_task.json<<EOF
{ "schema": 1,
  "test": {
    "type": "latency",
    "spec": {
      "schema": 1,
      "dest": "${PERFSONAR_LATENCY_DEST}",
      "packet-count": 10
    },
    "archives": {
      "archiver": "http",
      "data": {
        "schema": 2,
        "_url": "${PERFSONAR_ARCHIVE_URL}",
        "op": "put",
        "_headers": {
            "x-ps-observer": "{% scheduled_by_address %}",
            "authorization": "${PERFSONAR_ARCHIVE_AUTHORIZATION}"
            "content-type": "application/json"
        }
      }
    }
  }
}
EOF
   pscheduler task --import /owamp_task.json .
fi

if (( $PERFSONAR_DO_TRACE ))
then
cat >/trace_task.json<<EOF
{ "schema": 1,
  "test": {
    "type": "trace",
    "spec": {
      "schema": 1,
      "dest": "${PERFSONAR_TRACE_DEST}",
    },
    "archives": {
      "archiver": "http",
      "data": {
        "schema": 2,
        "_url": "${PERFSONAR_ARCHIVE_URL}",
        "op": "put",
        "_headers": {
            "x-ps-observer": "{% scheduled_by_address %}",
            "authorization": "${PERFSONAR_ARCHIVE_AUTHORIZATION}"
            "content-type": "application/json"
        }
      }
    }
  }
}
EOF
    pscheduler task --import /trace_task.json . 
fi
