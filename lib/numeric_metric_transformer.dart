import 'package:googleapis/monitoring/v3.dart';
import 'package:iot_api/api.dart';
import 'package:logging/logging.dart';
import 'package:stackdriver_iot/metric_transformer.dart';

// have to use 'custom.googleapis.com/' as prefix cannot use anything else
final _PREFIX_METRIC_TYPE =
    'custom.googleapis.com/iot/'; // add the metric name to this
final _log = Logger('stackdriver');

typedef TypedValue GetValueFunction(TimeseriesPoint apiPoint);

abstract class NumericMetricTransformer extends MetricTransformer {
  final String metricName;
  final String description;
  final String displayName;
  final String valueType; // as per stackdriver spec
  final GetValueFunction getValueFunction;
  final String _unit;
  MetricDescriptor metricDescriptor;

  NumericMetricTransformer(this.metricName, this.description,
      this.displayName, this.valueType, this.getValueFunction, {String unit}) :
    _unit = unit ?? '1';

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
      final interval = TimeInterval();

      if (point.when != null) {
        interval.endTime = point.when.toUtc().toIso8601String();
      } else {
        interval.endTime = DateTime.now().toUtc().toIso8601String();
      }

      return Point()
        ..interval = interval
        ..value = getValueFunction(point);
    }).toList();

    if (points.isNotEmpty) {
      return TimeSeries()
        ..metric = metric
        ..valueType = valueType
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
        ..unit = _unit
        ..valueType = valueType;

      _log.info(
          'stackdriver metric does not exist, creating ${displayName}...');
      metricDescriptor =
      await api.projects.metricDescriptors.create(request, projectName);

      _log.info('new metric is $metricDescriptor, we are good to start logging');
    } else {
      _log.info('metric ${metricName} already exists, we are good to start logging.');
    }
  }

  // use this carefully
  Future<void> deleteMetric(MonitoringApi api, String projectName) async {
    try {
      await api.projects.metricDescriptors.delete(projectName + '/metricDescriptors/' + _PREFIX_METRIC_TYPE + metricName);
      _log.info("Deleted ${metricName} ok.");
    } catch (e,s) {
      _log.severe('Unable to delete metric: ${metricName}', e, s);
    }
  }
}

abstract class DoubleMetricTransformer extends NumericMetricTransformer {

  DoubleMetricTransformer(String metricName, String description,
      String displayName) : super(metricName, description, displayName, 'DOUBLE', getTypedValueFromPoint);

  static TypedValue getTypedValueFromPoint(TimeseriesPoint point) {
    return TypedValue()..doubleValue = point.n == null ? 0.0 : point.n;
  }
}

abstract class IntegerMetricTransformer extends NumericMetricTransformer {
  IntegerMetricTransformer(String metricName, String description,
      String displayName) : super(metricName, description, displayName, 'INT64', getTypedValueFromPoint);

  static TypedValue getTypedValueFromPoint(TimeseriesPoint point) {
    return TypedValue()..int64Value = point.i == null ? '0' : point.i.toString();
  }
}
