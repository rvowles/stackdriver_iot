import 'package:googleapis/monitoring/v3.dart';
import 'package:iot_api/api.dart';

abstract class Pusher {
  PointType getType();
  Future<void> setupMetrics(ListMetricDescriptorsResponse existingMetricDescriptors);
  Future<bool> process(Timeseries timeseries);
  void setApi(MonitoringApi api);
}
