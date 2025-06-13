import logging

from opentelemetry import trace
from opentelemetry import metrics
import os
import subprocess
import re

tracer = trace.get_tracer_provider().get_tracer("wireless-telemetry.tracer")
meter = metrics.get_meter("wireless-telemetry.meter")
logger = logging.getLogger()

def parse_floats(string, length=0, regex=r'[\d\.]+'):
    '''
    returns a list of floats of with 'length' number of results
    '''
    try:
        string = string.split("=")[1]
    except IndexError:
        pass
    results = re.findall(regex, string)
    if not results:
        return None if not length else [None] * length
    if not length:
        return float(results[0])
    return [float(result) for result in results[:length]]

def trim(string):
    return string.strip()

def report_command(var, gauge, unit=None, description=None, formatter=parse_floats, formatter_kwargs={}):
    if os.environ.get(var):
        print("reporting on %s" % var)
        result = subprocess.run(os.environ[var].split(" "), capture_output=True, text=True)
        gauge = meter.create_gauge(gauge, unit=unit, description=description)
        print("stdout from command %s was %s" % (os.environ[var], result.stdout))
        parsed_value = formatter(result.stdout, **formatter_kwargs)
        print("value for command %s from %s is '%s'" % (os.environ[var], var, parsed_value))
        gauge.set(parsed_value)

# Trace context correlation
with tracer.start_as_current_span("device-report"):
    commands = [
        {
            'var': 'OTEL_REPORT_TEMP_CMD',
            'gauge': 'device.cpu_temperature',
            'unit': 'CEL',
            'description': 'CPU Temperature of Measurement Device, in degrees Celcius',
        },
        {
            'var': 'OTEL_REPORT_VOLTS_CMD',
            'gauge': 'device.cpu_voltage',
            'unit': 'V',
            'description': 'CPU 1 Voltage',
        },
        {
            'var': 'OTEL_REPORT_CLOCK_CMD',
            'gauge': 'device.cpu_frequency',
            'unit': 'Hz',
            'description': 'CPU Clock Frequency',
        },
        {
            'var': 'OTEL_BOOT_ENVIRONMENT_CMD',
            'gauge': 'device.cpu_frequency',
            'unit': 'Hz',
            'description': 'CPU Clock Frequency',
            'formatter': trim
        },
        {
            'var': 'OTEL_REPORT_BATTERY_VOLTS_CMD',
            'gauge': 'device.battery_voltage',
            'unit': 'V',
            'description': 'Battery Voltage',
        },
        {
            'var': 'OTEL_REPORT_GPS_CMD',
            'gauge': 'device.gps_position',
            'description': 'Latitude and Longitude of Device',
            'formatter': parse_floats,
            'formatter_kwargs': { 'length': 2 }
        },
    ]
    for command in commands:
        report_command(**command)
