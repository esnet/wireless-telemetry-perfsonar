FROM ghcr.io/perfsonar/testpoint:5.2.0

##############################
# OpenTelemetry Configuration
##############################

# OpenTelemetry "standard" configuration
ENV OTEL_EXPORTER_OTLP_ENDPOINT=https://otlp.example.com:8200/
ENV OTEL_EXPORTER_OTLP_HEADERS="Authorization=ApiKey th1sIsaR34lLyS3cur3Ex4mpl3S3Cr3t=="
# these need not be replaced, but can be overridden
ENV OTEL_SERVICE_NAME="wireless-telemetry"
ENV OTEL_METRICS_EXPORTER="console,otlp"
ENV OTEL_LOGS_EXPORTER="console,otlp"
ENV OTEL_TRACES_EXPORTER="console,otlp"

# User-configurable commands to access specific measurements on the hardware platform.
# these can differ between e.g. pi hats etc.

# parsed for float, assumed to report degrees C
ENV OTEL_REPORT_TEMP_CMD="vcgencmd measure_temp"
# parsed for float, assumed to report Volts (V)
ENV OTEL_REPORT_VOLTS_CMD="vcgencmd measure_volts"
# parsed for float, assumed to report cycles per second (Hz)
ENV OTEL_REPORT_CLOCK_CMD="vcgencmd measure_clock arm"
# reported as string
ENV OTEL_REPORT_BOOT_ENVIRONMENT_CMD="vcgencmd bootloader_config"
# parsed for float, assumed to report Volts (V)
ENV OTEL_REPORT_BATTERY_VOLTS_CMD=""
# parsed for pair of floats, assumed to report decimal degrees lat, degrees lng in that order.
ENV OTEL_REPORT_GPS_CMD=""

##########################
# PerfSONAR Configuration
##########################

# Example PerfSONAR Mesh
ENV PERFSONAR_TEMPLATE_URL="https://archive.local/psconfig/psconfig.json"
# See this page for an Example on how to configure this correctly:
# https://docs.perfsonar.net/cookbook_central_archive.html

ENV PERFSONAR_RUN_LATENCY=1
ENV PERFSONAR_LATENCY_DEST=albq-ps-lat.es.net

ENV PERFSONAR_RUN_TRACE=1
ENV PERFSONAR_TRACE_DEST=albq-ps-lat.es.net

ENV PERFSONAR_RUN_RTT=1
ENV PERFSONAR_RTT_DEST=albq-ps-lat.es.net

# EXAMPLE Where to send PerfSONAR results?
ENV PERFSONAR_ARCHIVE_URL=http://ps-archive.example.com/logstash

# EXAMPLE Authorization header for the PerfSONAR archive
ENV PERFSONAR_ARCHIVE_AUTHORIZATION="Basic th1sIS4ls0T0t4l1yS3cr3t3xc3ptFr0m1337H4x0rz=="

##############################
# Node Behavior Configuration
##############################

ENV SYNC_TIME_AND_BOOT_SCHEDULE=1
# no-op for now
ENV SYNC_TIME_AND_BOOT_SCHEDULE_CMD="echo -n '' > /dev/null" 

ENV SHUTDOWN_AFTER_REPORT=0
# mutually exclusive with above
ENV REPORT_INTERVAL=30

#################
# Build Detritus
#################

COPY requirements.txt /

RUN apt update && apt install -y python3.10-venv libraspberrypi-bin netcat
RUN python3 -m venv /wireless_telemetry_venv && /wireless_telemetry_venv/bin/pip install -r /requirements.txt

COPY wireless_telemetry.py /
COPY startup_script.sh /

# execute the startup script with supervisord
RUN echo "" >> /etc/supervisord.conf
RUN echo "[program:startup-script]" >> /etc/supervisord.conf
RUN echo "command=/startup_script.sh" >> /etc/supervisord.conf
RUN echo "redirect_stderr=true" >> /etc/supervisord.conf
RUN echo "stdout_logfile = /dev/stdout" >> /etc/supervisord.conf
RUN echo "stdout_logfile_maxbytes = 0" >> /etc/supervisord.conf

# start supervisord as CMD per upstream