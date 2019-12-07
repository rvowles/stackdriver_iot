import 'package:googleapis/monitoring/v3.dart';
import 'package:iot_api/api.dart';
import 'package:logging/logging.dart';

import 'double_pusher.dart';

// have to use 'custom.googleapis.com/' as prefix cannot use anything else
final _log = Logger('stackdriver');

class TemperaturePusher extends DoublePusher {
  final MonitoringApi api;
  final String projectName;

  TemperaturePusher(this.api, this.projectName) : super(api, projectName, 'temperature', 'temperature', 'temperature');

  @override
  PointType getType() {
    return PointType.TEMP_C;
  }
}
