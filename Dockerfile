FROM ghcr.io/perfsonar/testpoint:docker-actions-refactor

ENV OPENTELEMETRY_URL https://otlp.example.com:8200/intake/v2/events
ENV OPENTELEMETRY_SECRET th1sIsaR34lLyS3cur3Ex4mpl3S3Cr3t

ENV OPENTELEMETRY_REPORT_TEMP_CMD "vcgencmd measure_temp"
ENV OPENTELEMETRY_REPORT_VOLTS_CMD "vcgencmd measure_volts"
ENV OPENTELEMETRY_REPORT_CLOCK_CMD "vcgencmd measure_clock"
ENV OPENTELEMETRY_REPORT_BATTERY_VOLTS_CMD ""
ENV OPENTELEMETRY_REPORT_GPS_CMD ""


# Example PerfSONAR Mesh
ENV PERFSONAR_TEMPLATE_URL "https://archive.local/psconfig/psconfig.json"
# See this page for an Example on how to configure this correctly:
# https://docs.perfsonar.net/cookbook_central_archive.html

ENV PERFSONAR_DO_LATENCY 1
ENV PERFSONAR_DO_TRACE 1
ENV PERFSONAR_LATENCY_DEST albq-ps-lat.es.net
ENV PERFSONAR_TRACE_DEST albq-ps-lat.es.net

# Which archive to use from the PerfSONAR mesh?
ENV PERFSONAR_ARCHIVE_URL https://ps-archive.es.net/logstash

# This will be substituted into the template after fetching with a jq script
ENV PERFSONAR_ARCHIVE_AUTHORIZATION "Bearer th1sIS4ls0T0t4l1yS3cr3t3xc3ptFr0m1337H4x0rz"

COPY requirements.txt /

RUN apt update
RUN apt install -y python3.10-venv
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
