import 'package:googleapis/monitoring/v3.dart';
import 'package:iot_api/api.dart';

abstract class MetricTransformer {
  PointType getType();
  Future<void> setupMetrics(MonitoringApi api, String projectName, ListMetricDescriptorsResponse existingMetricDescriptors);
  TimeSeries process(Timeseries timeseries);
  Future<void> deleteMetric(MonitoringApi api, String projectName);
}
