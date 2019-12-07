import 'package:googleapis/monitoring/v3.dart';
import 'package:iot_api/api.dart';

import 'double_pusher.dart';

class TemperaturePusher extends DoublePusher {
  TemperaturePusher(MonitoringApi api, String projectName) : super(api, projectName, 'temperature', 'temperature', 'temperature');

  @override
  PointType getType() {
    return PointType.TEMP_C;
  }
}
