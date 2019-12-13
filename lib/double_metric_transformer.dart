import 'package:googleapis/monitoring/v3.dart';
import 'package:iot_api/api.dart';
import 'package:logging/logging.dart';
import 'package:stackdriver_iot/metric_transformer.dart';

// have to use 'custom.googleapis.com/' as prefix cannot use anything else
final _PREFIX_METRIC_TYPE =
    'custom.googleapis.com/iot/'; // add the metric name to this
final _log = Logger('stackdriver');

abstract class DoubleMetricTransformer extends MetricTransformer {

  final String metricName;
  final String description;
  final String displayName;
  MetricDescriptor metricDescriptor;

  DoubleMetricTransformer(this.metricName, this.description,
      this.displayName);

  @override
  TimeSeries process(Timeseries timeseries) {
    final pointType = getType();

    final metric = Metric()
      ..labels = {
        'source': timeseries.source,
        'mote': timeseries.mote,
        'point_type':
            PointTypeTypeTransformer.toJsonMap[pointType].toLowerCase()
      }
      ..type = metricDescriptor.type;

    final points =
        timeseries.points.where((p) => p.type == pointType).map((point) {
      final value = TypedValue()..doubleValue = point.n;

      final interval = TimeInterval();

      if (point.when != null) {
        interval.endTime = point.when.toUtc().toIso8601String();
      } else {
        interval.endTime = DateTime.now().toUtc().toIso8601String();
      }

      return Point()
        ..interval = interval
        ..value = value;
    }).toList();

    if (points.isNotEmpty) {
      return TimeSeries()
        ..metric = metric
        ..valueType = 'DOUBLE'
        ..points = points;
    }

    return null;
  }

  @override
  Future<void> setupMetrics(MonitoringApi api, String projectName,
      ListMetricDescriptorsResponse existingMetricDescriptors) async {
    final type = _PREFIX_METRIC_TYPE + metricName;

    metricDescriptor = existingMetricDescriptors.metricDescriptors
        .firstWhere((md) => md.type == type, orElse: () => null);

    if (metricDescriptor == null) {
      final request = MetricDescriptor()
        ..description = description
        ..displayName = displayName
        ..type = type
        ..metricKind = 'GAUGE'
        ..unit = '1'
        ..valueType = 'DOUBLE';

      _log.info(
          'stackdriver metric does not exist, creating ${displayName}...');
      metricDescriptor =
          await api.projects.metricDescriptors.create(request, projectName);

      _log.info('new metric is $metricDescriptor, we are good to start logging');
    } else {
      _log.info('metric already exists, we are good to start logging.');
    }
  }
}
