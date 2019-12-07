import 'package:googleapis/monitoring/v3.dart';
import 'package:iot_api/api.dart';
import 'package:logging/logging.dart';
import 'package:stackdriver_iot/pusher.dart';

// have to use 'custom.googleapis.com/' as prefix cannot use anything else
final _TEMPERATURE_METRIC_TYPE = 'custom.googleapis.com/iot/temperature';
final _log = Logger('stackdriver');

class TemperaturePusher extends Pusher {
  final MonitoringApi api;
  final String projectName;
  MetricDescriptor temperatureMetric;

  TemperaturePusher(this.api, this.projectName);

  @override
  Future<void> process(Timeseries timeseries, TimeseriesPoint point) async {
    final metric = Metric()
      ..labels = {
        'source': timeseries.source,
        'sensor': timeseries.sensorType,
        'point-type': PointTypeTypeTransformer.toJsonMap[point.type].toLowerCase()}
      ..type = temperatureMetric.type;

    final value = TypedValue()..doubleValue = point.n;

    final interval = TimeInterval();

    if (point.when != null) {
      interval.endTime = point.when.toUtc().toIso8601String();
    } else {
      interval.endTime = DateTime.now().toUtc().toIso8601String();
    }

    final ts = TimeSeries()
      ..metric = metric
      ..valueType = 'DOUBLE'
      ..points = [
        Point()
          ..interval = interval
          ..value = value,
      ];

    try {
      await api.projects.timeSeries
          .create(CreateTimeSeriesRequest()
        ..timeSeries = [ts], projectName);
    } catch (e, s) {
      _log.severe('Failed to publish metric: ${timeseries.source} : ${point}', e, s);
    }
  }

  @override
  PointType getType() {
    return PointType.TEMP_C;
  }

  @override
  Future<void> setupMetrics(ListMetricDescriptorsResponse existingMetricDescriptors) async {
    temperatureMetric = existingMetricDescriptors.metricDescriptors.firstWhere(
            (md) => md.type == _TEMPERATURE_METRIC_TYPE,
        orElse: () => null);

    if (temperatureMetric == null) {
      final request = MetricDescriptor()
        ..description = 'temperature'
        ..displayName = 'temperature'
        ..type = _TEMPERATURE_METRIC_TYPE
        ..metricKind = 'GAUGE'
        ..unit = '1'
        ..valueType = 'DOUBLE';

      _log.info('stackdriver metric does not exist, creating...');
      temperatureMetric =
      await api.projects.metricDescriptors.create(request, projectName);

      _log.info('new metric is $temperatureMetric');
    } else {
      _log.info('metric already exists, we are good to start logging.');
      print('metric type already exists');
    }
  }

}
