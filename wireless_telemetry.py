import logging

from opentelemetry import trace
from opentelemetry import metrics
import os
import subprocess

tracer = trace.get_tracer_provider().get_tracer("wireless-telemetry.tracer")
meter = metrics.get_meter("wireless-telemetry.meter")
logger = logging.getLogger()

# Trace context correlation
with tracer.start_as_current_span("device-report"):
    if os.environ['OPENTELEMETRY_REPORT_TEMP_CMD']:
        result = subprocess.run(os.environ['OPENTELEMETRY_REPORT_TEMP_CMD'].split(" "), capture_output=True, text=True)
        temp = meter.create_gauge("device.temperature", unit="CEL", description="CPU temperature of measurement device, in degrees Celcius")
        temp.set(result.stdout)
    if os.environ['OPENTELEMETRY_REPORT_VOLTS_CMD']:
        result = subprocess.run(os.environ['OPENTELEMETRY_REPORT_VOLTS_CMD'].split(" "), capture_output=True, text=True)
        volts = meter.create_gauge("device.volts", unit="V", description="CPU voltage")
        volts.set(result.stdout)
    if os.environ['OPENTELEMETRY_REPORT_CLOCK_CMD']:
        result = subprocess.run(os.environ['OPENTELEMETRY_REPORT_CLOCK_CMD'].split(" "), capture_output=True, text=True)
        logger.info("Device Clock: %s" % result.stdout)
    if os.environ['OPENTELEMETRY_REPORT_BATTERY_VOLTS_CMD']:
        result = subprocess.run(os.environ['OPENTELEMETRY_REPORT_BATTERY_VOLTS_CMD'].split(" "), capture_output=True, text=True)
        batt_volts = meter.create_gauge("battery.volts", unit="V", description="Battery voltage")
        batt_volts.set(result.stdout)
    if os.environ['OPENTELEMETRY_REPORT_GPS_CMD']:
        result = subprocess.run(os.environ['OPENTELEMETRY_REPORT_GPS_CMD'].split(" "), capture_output=True, text=True)
        position = meter.create_gauge("device.gps_position", unit="lat/lng", description="Latitude and Longitude of device")
        position.set(result.stdout)
